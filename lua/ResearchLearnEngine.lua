--[[
  ResearchLearnEngine.lua - pure-Lua buy/prep/craft engine for ResearchLearn

  Replaces the researchlearn.mac execution path (vendor buying, parchment
  prep subcombines, research kit combines) with a Lua state machine driven
  directly by the ResearchLearn.lua plan. No ResearchLearn_pass.ini bridge,
  no ${Ini[]} re-reads, real-millisecond waits.

  Used by ResearchLearn.lua ("Start Lua" button):
    local engine = require('ResearchLearnEngine')
    engine.run(job)   -- blocking; call from the script main loop, not ImGui
    engine.busy() / engine.request_stop() / engine.ui (status for UI)

  job = {
    kitPack = 10,
    items = {
      { name = 'Blessing of Oak',
        copies = 1,
        rec = { iniRaw = 'Spell: Blessing of Oak', name = ..., level = 69,
                ingredients = { 'Runic Vellum', 'Ink of Tunare', ... } } },
      ...
    },
  }
]]

local mq = require('mq')

local M = {
    ui = { state = 'idle', current = '', done = 0, total = 0, log = {} },
}

-- ---------------------------------------------------------------------------
-- Constants / data
-- ---------------------------------------------------------------------------

local KIT_NAME = 'Spell Research Kit'
local KIT_SLOTS = 10

local KLAZ, VORI = 'Scholar Klaz', 'Vori'
local NURSA, CADEN = 'Nursa Rasumus', 'Caden Zharik'
local VORI_ITEMS = { ['Tiny Dagger'] = true, ['Bone Chips'] = true }

local CLEANSER = 'Celestial Cleanser'
local SOLVENT = 'Celestial Solvent'
local VOPW = 'Vial of Pure Water'

-- parchment = 1x Cleanser + 1x solution + 1x dropped item
-- Cleanser batch = 1x Solvent + 1x Empty Vial + 3x VoPW  -> 4x Cleanser
-- VoPW batch     = 5x Empty Vial + 1x Gnomish Heat Source + 4x Water Flask -> 5x VoPW
local PARCH = {
    ['Fine Runic Vellum']    = { solution = 'Fine Runic Vellum Solution',    dropped = 'Sooty Fine Runic Vellum' },
    ['Fine Vellum']          = { solution = 'Fine Vellum Solution',          dropped = 'Grubby Fine Vellum' },
    ['Vellum']               = { solution = 'Vellum Solution',               dropped = 'Dirty Vellum' },
    ['Runic Vellum']         = { solution = 'Runic Vellum Solution',         dropped = 'Shabby Runic Vellum' },
    ['Fine Runic Parchment'] = { solution = 'Fine Runic Parchment Solution', dropped = 'Grimy Fine Runic Parchment' },
}

-- ---------------------------------------------------------------------------
-- State / events
-- ---------------------------------------------------------------------------

local stopRequested = false
local kitPack = 10
local flags = { success = false, fail = false, lacked = false }
local WAIT_MULT = 1.35 -- 1.00 normal, 1.15 tiny slowdown, 1.25 safer, 1.35 very safe

mq.event('rlng_success',  'You have fashioned the items together#*#', function() flags.success = true end)
mq.event('rlng_lacked',   'You lacked the skills to fashion#*#',      function() flags.fail = true flags.lacked = true end)
mq.event('rlng_cannot',   'You cannot combine these items#*#',        function() flags.fail = true end)
mq.event('rlng_missing',  'You do not have all the components#*#',    function() flags.fail = true end)
mq.event('rlng_place',    'You must place items#*#',                  function() flags.fail = true end)
-- emu/server message variants (anchored versions above can miss prefixed lines)
mq.event('rlng_success2', '#*#fashioned the items together#*#',       function() flags.success = true end)
mq.event('rlng_lacked2',  '#*#lack the skills#*#',                    function() flags.fail = true flags.lacked = true end)

local function log(msg, ...)
    if select('#', ...) > 0 then msg = string.format(msg, ...) end
    printf('\ag[RL Engine]\ax %s', msg)
    local l = M.ui.log
    l[#l + 1] = msg
    while #l > 8 do table.remove(l, 1) end
    M.ui.current = msg
end

function M.request_stop() stopRequested = true end
function M.busy() return M.ui.state ~= 'idle' end

local function check_stop()
    if stopRequested then error('__RL_STOP__', 0) end
end

-- delay in real ms; stop-aware; pumps events
local function delay(ms, cond)
    ms = math.floor(ms * WAIT_MULT)

    if cond then
        mq.delay(ms, function()
            mq.doevents()
            return stopRequested or cond()
        end)
    else
        local deadline = mq.gettime() + ms
        while mq.gettime() < deadline and not stopRequested do
            mq.delay(math.min(100, math.max(1, deadline - mq.gettime())))
            mq.doevents()
        end
    end
    check_stop()
end

-- ---------------------------------------------------------------------------
-- Inventory helpers
-- ---------------------------------------------------------------------------

local function item_count(name)
    return mq.TLO.FindItemCount('=' .. name)() or 0
end

local function kit_slot_name(i)
    local n = mq.TLO.Me.Inventory('pack' .. kitPack).Item(i).Name()
    if not n or n == '' then return nil end
    return n
end

-- bags + stacks sitting in the open research kit (FindItemCount misses kit contents)
local function count_everywhere(name)
    local total = item_count(name)
    if mq.TLO.Window('ContainerCombine_Items').Open() then
        for i = 1, KIT_SLOTS do
            if kit_slot_name(i) == name then
                local st = mq.TLO.Me.Inventory('pack' .. kitPack).Item(i).Stack() or 1
                if st <= 0 then st = 1 end
                total = total + st
            end
        end
    end
    return total
end

-- free slots in bags/top-level inventory EXCLUDING the research kit.
-- Me.FreeInventory counts kit slots too, which hides "bags actually full".
local function free_slots_outside_kit()
    local free = 0
    for p = 1, 10 do
        if p ~= kitPack then
            local inv = mq.TLO.Me.Inventory('pack' .. p)
            local sz = inv.Container() or 0
            if sz > 0 then
                for s = 1, sz do
                    if not inv.Item(s).ID() then free = free + 1 end
                end
            elseif not inv.ID() then
                free = free + 1
            end
        end
    end
    return free
end

local function scroll_count(rawName)
    local n = item_count(rawName)
    if not rawName:find('^Spell:') then
        local alt = item_count('Spell: ' .. rawName)
        if alt > n then n = alt end
    end
    return n
end

local function skill_value()
    local sk = mq.TLO.Me.Skill('Research')() or 0
    if sk == 0 then sk = mq.TLO.Me.Skill('Spell Research')() or 0 end
    return sk
end

local function cursor_id() return mq.TLO.Cursor.ID() or 0 end

-- pick a destination OUTSIDE the research kit for whatever is on the cursor:
-- first a same-name stack with room (merge), else the first empty bag slot.
local function find_stow_target(want_name)
    local emptyP, emptyS = nil, nil
    for p = 1, 10 do
        if p ~= kitPack then
            local inv = mq.TLO.Me.Inventory('pack' .. p)
            local sz = inv.Container() or 0
            if sz > 0 then
                for s = 1, sz do
                    local it = inv.Item(s)
                    if it.ID() then
                        if want_name and it.Name() == want_name then
                            local st, mx = it.Stack() or 1, it.StackSize() or 1
                            if mx > 1 and st < mx then return p, s end
                        end
                    elseif not emptyP then
                        emptyP, emptyS = p, s
                    end
                end
            end
        end
    end
    return emptyP, emptyS
end

local function clear_cursor()
    for _ = 1, 5 do
        if cursor_id() == 0 then return true end
        -- stow explicitly outside the kit: /autoinventory treats the open
        -- research kit as a normal bag and bounces items straight back into
        -- it, which is how slots end up stacked/occupied
        local p, s = find_stow_target(mq.TLO.Cursor.Name())
        if p then
            mq.cmdf('/nomodkey /itemnotify in pack%d %d leftmouseup', p, s)
            delay(800, function() return cursor_id() == 0 end)
        else
            mq.cmd('/autoinventory')
            delay(600, function() return cursor_id() == 0 end)
        end
    end
    return cursor_id() == 0
end

local function accept_qty_window(n)
    if not mq.TLO.Window('QuantityWnd').Open() then return end
    if n and n > 0 then
        mq.TLO.Window('QuantityWnd/QTYW_SliderInput').SetText(tostring(n))()
        delay(500, function() return mq.TLO.Window('QuantityWnd/QTYW_SliderInput').Text() == tostring(n) end)
    end
    mq.TLO.Window('QuantityWnd/QTYW_Accept_Button').LeftMouseUp()
    delay(1000, function() return not mq.TLO.Window('QuantityWnd').Open() end)
end

-- ---------------------------------------------------------------------------
-- Navigation / merchant
-- ---------------------------------------------------------------------------

local function nav_to(name)
    check_stop()
    if mq.TLO.Me.Levitating() then
        mq.cmd('/removelev')
        delay(1500, function() return not mq.TLO.Me.Levitating() end)
    end
    local spawn = mq.TLO.Spawn(string.format('npc "%s"', name))
    local id = spawn.ID() or 0
    if id == 0 then
        log('Could not find %s in zone.', name)
        return false
    end
    mq.cmdf('/target id %d', id)
    delay(1000, function() return (mq.TLO.Target.ID() or 0) == id end)
    local function dist() return mq.TLO.Target.Distance() or 999 end
    if dist() <= 10 then mq.cmd('/face fast') return true end

    log('Navigating to %s...', name)
    mq.cmdf('/nav id %d distance=10', id)
    local deadline = mq.gettime() + 90000
    local restarted = false
    local lastX, lastY = mq.TLO.Me.X() or 0, mq.TLO.Me.Y() or 0
    local stuckMs, strafeLeft = 0, true
    while mq.gettime() < deadline do
        check_stop()
        if dist() <= 12 then break end
        local x, y = mq.TLO.Me.X() or 0, mq.TLO.Me.Y() or 0
        if math.abs(x - lastX) < 1 and math.abs(y - lastY) < 1 then
            stuckMs = stuckMs + 200
        else
            stuckMs = 0
        end
        lastX, lastY = x, y
        if stuckMs >= 3000 then
            stuckMs = 0
            log('Nav stuck - opening doors / nudging...')
            try_open_door(40)
            mq.cmd('/nav stop')
            mq.cmd('/keypress forward hold')
            delay(300)
            mq.cmd('/keypress forward')
            if strafeLeft then
                mq.cmd('/keypress strafe_left hold')
                delay(200)
                mq.cmd('/keypress strafe_left')
            else
                mq.cmd('/keypress strafe_right hold')
                delay(200)
                mq.cmd('/keypress strafe_right')
            end
            strafeLeft = not strafeLeft
            mq.cmdf('/nav id %d distance=10', id)
        end
        if not mq.TLO.Navigation.Active() then
            if not restarted then
                restarted = true
                mq.cmdf('/nav id %d distance=10', id)
                delay(500)
            else
                mq.cmdf('/moveto id %d', id)
                delay(8000, function() return dist() <= 12 end)
                break
            end
        end
        delay(200)
    end
    mq.cmd('/nav stop')
    mq.cmd('/face fast')
    if dist() > 15 then
        log('Could not reach %s (%.0f away).', name, dist())
        return false
    end
    return true
end

local function try_open_door(radius)
    mq.cmd('/doortarget')
    mq.delay(200)
    local d = mq.TLO.DoorTarget.Distance() or 999
    if (mq.TLO.DoorTarget.ID() or 0) > 0 and d <= (radius or 40) then
        mq.cmd('/click left door')
        mq.delay(500)
        return true
    end
    return false
end

local function merchant_open() return mq.TLO.Window('MerchantWnd').Open() end

local function close_merchant()
    if merchant_open() then
        mq.TLO.Window('MerchantWnd').DoClose()
        delay(1500, function() return not merchant_open() end)
    end
end

local function open_merchant()
    if merchant_open() then return true end
    for _ = 1, 3 do
        check_stop()
        mq.cmd('/invoke ${Merchant.OpenWindow}')
        delay(2000, function() return merchant_open() end)
        if not merchant_open() then
            mq.cmd('/click right target')
            delay(2000, function() return merchant_open() end)
        end
        if merchant_open() then
            delay(5000, function() return mq.TLO.Merchant.ItemsReceived() end)
            return true
        end
    end
    return false
end

local function buy_item(name, qty)
    if qty <= 0 then return true end
    local target = item_count(name) + qty
    local list = mq.TLO.Window('MerchantWnd/MW_ItemList')
    local row = tonumber(list.List('=' .. name, 2)() or 0) or 0
    if row == 0 then
        log('WARNING: %s not sold here.', name)
        return false
    end
    log('Buying %dx %s...', qty, name)
    for _ = 1, qty + 2 do
        check_stop()
        if item_count(name) >= target then break end
        list.Select(row)()
        delay(1500, function() return mq.TLO.Window('MerchantWnd/MW_SelectedItemLabel').Text() == name end)
        mq.TLO.Window('MerchantWnd/MW_Buy_Button').LeftMouseUp()
        delay(1000, function() return mq.TLO.Window('QuantityWnd').Open() or item_count(name) >= target end)
        if mq.TLO.Window('QuantityWnd').Open() then
            accept_qty_window(target - item_count(name))
        end
        delay(2500, function() return item_count(name) >= target end)
        clear_cursor()
    end
    if item_count(name) < target then
        log('WARNING: still short %s (%d/%d).', name, item_count(name), target)
        return false
    end
    return true
end

-- list = { itemName = absoluteNeed } ; buys only the shortfall at buy time
local function vendor_run(vendorName, list)
    local pending = {}
    for name, need in pairs(list) do
        if need - item_count(name) > 0 then pending[name] = need end
    end
    if not next(pending) then return true end
    log('Vendor run: %s', vendorName)
    if not nav_to(vendorName) then return false end
    if not open_merchant() then
        log('WARNING: could not open %s.', vendorName)
        return false
    end
    for name, need in pairs(pending) do
        local short = need - item_count(name)
        if short > 0 then buy_item(name, short) end
    end
    close_merchant()
    return true
end

-- ---------------------------------------------------------------------------
-- Research kit
-- ---------------------------------------------------------------------------

-- Open bag windows interfere with scripted slot clicks (field-verified:
-- combines only ran reliably once all bags were closed). Close every bag
-- window except the kit's own pack before working the kit, so it does not
-- matter what the player has open when the run starts (or opens mid-run).
local function close_bag_windows()
    local closed = false
    for p = 1, 10 do
        if p ~= kitPack then
            pcall(function()
                local w = mq.TLO.Window('pack' .. p)
                if w.Open() then w.DoClose() closed = true end
            end)
        end
    end
    if closed then delay(150) end
end

local ensure_kit_pack_window   -- defined after open_kit (forward declaration)

local function kit_open() return mq.TLO.Window('ContainerCombine_Items').Open() end

local function open_kit()
    if kit_open() then return true end
    clear_cursor()
    close_merchant()
    local kit = mq.TLO.FindItem('=' .. KIT_NAME)
    if not kit.ID() then
        log('ERROR: %s not found in inventory.', KIT_NAME)
        return false
    end
    if (kit.ItemSlot2() or -1) ~= -1 then
        log('ERROR: move %s to a top-level bag slot.', KIT_NAME)
        return false
    end
    local slot = kit.ItemSlot() or 0
    if slot >= 23 and slot <= 32 then kitPack = slot - 22 end
    close_bag_windows()
    for _ = 1, 4 do
        check_stop()
        if not mq.TLO.Window('InventoryWindow').Open() then
            mq.cmd('/keypress i')
            delay(500, function() return mq.TLO.Window('InventoryWindow').Open() end)
        end
        mq.cmdf('/nomodkey /itemnotify pack%d rightmouseup', kitPack)
        delay(1000, function() return kit_open() or mq.TLO.Window('TradeskillWnd').Open() end)
        if mq.TLO.Window('TradeskillWnd').Open() and not kit_open() then
            mq.cmd('/nomodkey /notify TradeskillWnd COMBW_ExperimentButton leftmouseup')
            delay(1000, function() return kit_open() end)
        end
        if not kit_open() then
            mq.cmdf('/combine pack%d', kitPack)
            delay(1000, function() return kit_open() end)
        end
        if kit_open() then ensure_kit_pack_window() return true end
    end
    log('ERROR: could not open %s in Experiment mode (pack%d).', KIT_NAME, kitPack)
    return false
end

-- /combine needs the kit's plain bag window ('pack<N>') open; the experiment
-- window (ContainerCombine_Items) is a different window. OPEN_INV_BAGS opens
-- every bag, then close_bag_windows closes all but the kit's - deterministic.
ensure_kit_pack_window = function()
    if mq.TLO.Window('pack' .. kitPack).Open() then return true end
    mq.cmd('/keypress OPEN_INV_BAGS')
    delay(600, function() return mq.TLO.Window('pack' .. kitPack).Open() end)
    close_bag_windows()
    return mq.TLO.Window('pack' .. kitPack).Open()
end

local function ensure_bags_open()
    -- /itemnotify clicks work on CLOSED bags; never toggle OPEN_INV_BAGS
    -- (it opens/closes every bag at once and thrashes the UI).
    if not mq.TLO.Window('InventoryWindow').Open() then
        mq.cmd('/keypress i')
        delay(400, function() return mq.TLO.Window('InventoryWindow').Open() end)
    end
end

-- best-effort dismissal of blocking server popups (e.g. the "You may not have
-- any stacks of items in the container" alert), which eat combine clicks
local function dismiss_popups()
    local wins = {
        { 'ConfirmationDialogBox', 'CD_OK_Button' },
        { 'ConfirmationDialogBox', 'CD_Yes_Button' },
        { 'AlertWnd', 'ALW_Dismiss_Button' },
        { 'LargeDialogWindow', 'LDW_OkButton' },
    }
    for _, w in ipairs(wins) do
        pcall(function()
            if mq.TLO.Window(w[1]).Open() then
                mq.TLO.Window(w[1] .. '/' .. w[2]).LeftMouseUp()
            end
        end)
    end
end

-- deterministic pick: find the mat's exact bag slot (never inside the kit),
-- ctrl-click THAT slot, and verify the cursor holds exactly 1 of the right
-- item. By-name /itemnotify is ambiguous with mats spread across many bags
-- and fails silently, which is what caused the one-item-then-fumble loop.
local function find_in_bags(name)
    for p = 1, 10 do
        if p ~= kitPack then
            local inv = mq.TLO.Me.Inventory('pack' .. p)
            local sz = inv.Container() or 0
            if sz > 0 then
                for s = 1, sz do
                    if (inv.Item(s).Name() or '') == name then return p, s end
                end
            elseif (inv.Name() or '') == name then
                return p, 0   -- sitting directly in a top-level slot
            end
        end
    end
    return nil
end

local function pick_one(name)
    for _ = 1, 2 do
        local p, s = find_in_bags(name)
        if not p then return false end
        if s and s > 0 then
            mq.cmdf('/nomodkey /ctrlkey /itemnotify in pack%d %d leftmouseup', p, s)
        else
            mq.cmdf('/nomodkey /ctrlkey /itemnotify pack%d leftmouseup', p)
        end
        delay(1200, function() return cursor_id() > 0 or mq.TLO.Window('QuantityWnd').Open() end)
        accept_qty_window(1)
        if cursor_id() > 0 then
            if (mq.TLO.Cursor.Name() or '') == name and (mq.TLO.Cursor.Stack() or 1) == 1 then
                return true
            end
            clear_cursor()   -- wrong item or a whole stack - put it back, retry
        end
    end
    return false
end

local function clear_kit()
    if not kit_open() then return false end
    dismiss_popups()
    close_bag_windows()
    for i = 1, KIT_SLOTS do
        if kit_slot_name(i) then
            mq.cmdf('/nomodkey /itemnotify in pack%d %d leftmouseup', kitPack, i)
            delay(800, function() return cursor_id() > 0 or mq.TLO.Window('QuantityWnd').Open() end)
            accept_qty_window(nil)
            clear_cursor()
        end
    end
    -- verify: /autoinventory above can drop items straight back into the kit
    -- (it is a normal bag, often the only one with free slots). Combining on
    -- top of leftovers is what creates stacked slots, which the server rejects.
    for i = 1, KIT_SLOTS do
        if kit_slot_name(i) then
            log('WARNING: kit slot %d still holds %s after clearing (bags full?).', i, kit_slot_name(i))
            return false
        end
    end
    return true
end

local function place_in_kit(name, slot)
    if item_count(name) <= 0 then return false end
    for _ = 1, 4 do
        check_stop()
        clear_cursor()
        dismiss_popups()
        -- never drop onto an occupied slot: a same-name leftover would merge
        -- into a stack, and stacked slots make the combine fail server-side
        if kit_slot_name(slot) then
            log('WARNING: kit slot %d already holds %s - not placing %s on top.',
                slot, kit_slot_name(slot), name)
            return false
        end
        if pick_one(name) then
            mq.cmdf('/nomodkey /itemnotify in pack%d %d leftmouseup', kitPack, slot)
            delay(1200, function() return cursor_id() == 0 end)
            if cursor_id() == 0 and kit_slot_name(slot) == name then return true end
        end
    end
    log('WARNING: could not place %s in kit slot %d.', name, slot)
    return false
end

-- useScrollCount: spell scrolls match 'Spell: X' variants; subcombines use exact names
local function combine_and_wait(expected, useScrollCount)
    if not kit_open() and not open_kit() then return false end
    local counter, before = nil, 0
    if expected then
        counter = useScrollCount and scroll_count or count_everywhere
        before = counter(expected)
    end
    -- hard guard: never click Combine with a stacked slot; the server rejects
    -- it ("You may not have any stacks of items in the container...")
    local items_in_kit = 0
    for i = 1, KIT_SLOTS do
        if kit_slot_name(i) then
            items_in_kit = items_in_kit + 1
            if (mq.TLO.Me.Inventory('pack' .. kitPack).Item(i).Stack() or 1) > 1 then
                log('ABORT combine: stack of %s in kit slot %d - clearing kit.', kit_slot_name(i), i)
                clear_kit()
                return false
            end
        end
    end
    if items_in_kit == 0 then return false end

    local function kit_count()
        local c = 0
        for i = 1, KIT_SLOTS do if kit_slot_name(i) then c = c + 1 end end
        return c
    end

    -- the window-button notify sometimes gets eaten by UI state; retry, then
    -- fall back to the direct /combine command. "Mats left the kit" counts as
    -- the combine firing even if no chat message matched.
    local fired = false
    for attempt = 1, 3 do
        check_stop()
        dismiss_popups()
        flags.success = false
        flags.fail = false
        flags.lacked = false
        -- prefer the direct /combine command (instant, no UI click to eat)
        -- whenever the kit's pack window is available; window-button notify
        -- is the alternate path
        if ensure_kit_pack_window() and attempt < 3 then
            if attempt > 1 then log('Combine did not register - retrying /combine (attempt %d).', attempt) end
            mq.cmdf('/combine pack%d', kitPack)
        else
            if attempt > 1 then log('Combine did not register - retrying window click (attempt %d).', attempt) end
            mq.cmd('/notify ContainerCombine_Items Container_Combine leftmouseup')
        end
        local deadline = mq.gettime() + 3100
        while mq.gettime() < deadline do
            mq.doevents()
            if flags.fail or flags.success then fired = true break end
            if cursor_id() > 0 then fired = true break end
            if counter and counter(expected) > before then fired = true break end
            if kit_count() < items_in_kit then fired = true break end   -- mats consumed
            mq.delay(50)
        end
        if fired then break end
    end
    -- let any trailing combine message land, then put the product away
    delay(310)
    mq.doevents()
    clear_cursor()
    check_stop()
    if flags.fail then return false end
    if counter then return counter(expected) > before or flags.success end
    -- no counter (skill-up): success event, or mats visibly consumed
    return flags.success or (fired and kit_count() == 0)
end

-- ---------------------------------------------------------------------------
-- Parchment prep subcombines
-- ---------------------------------------------------------------------------

local function make_vopw_batch()
    if not open_kit() then return false end
    if not clear_kit() then return false end
    for i = 1, 5 do
        if not place_in_kit('Empty Vial', i) then return false end
    end
    if not place_in_kit('Gnomish Heat Source', 6) then return false end
    for i = 7, 10 do
        if not place_in_kit('Water Flask', i) then return false end
    end
    return combine_and_wait(VOPW, false)
end

local function make_cleanser_batch()
    if not open_kit() then return false end
    if not clear_kit() then return false end
    if not place_in_kit(SOLVENT, 1) then return false end
    if not place_in_kit('Empty Vial', 2) then return false end
    for i = 3, 5 do
        if not place_in_kit(VOPW, i) then return false end
    end
    return combine_and_wait(CLEANSER, false)
end

local function make_one_parchment(ptype)
    local def = PARCH[ptype]
    if not def then return false end
    if item_count(CLEANSER) == 0 or item_count(def.solution) == 0 or item_count(def.dropped) == 0 then
        log('Missing mats for %s (%d cleanser / %d solution / %d dropped).',
            ptype, item_count(CLEANSER), item_count(def.solution), item_count(def.dropped))
        return false
    end
    if not open_kit() then return false end
    if not clear_kit() then return false end
    if not place_in_kit(CLEANSER, 1) then return false end
    if not place_in_kit(def.solution, 2) then return false end
    if not place_in_kit(def.dropped, 3) then return false end
    local ok = combine_and_wait(ptype, false)
    if ok then log('Made %s.', ptype) end
    return ok
end

-- ---------------------------------------------------------------------------
-- Crafting
-- ---------------------------------------------------------------------------

local function recipe_need_counts(rec)
    local per = {}
    for _, ing in ipairs(rec.ingredients or {}) do
        per[ing] = (per[ing] or 0) + 1
    end
    return per
end

local function craft_one(it)
    local rec = it.rec
    local label = it.name or rec.name or '?'
    local per = recipe_need_counts(rec)

    -- top up parchments / vendor mats for ONE combine
    local vendorShort = {}
    for ing, n in pairs(per) do
        local short = n - count_everywhere(ing)
        if short > 0 then
            if PARCH[ing] then
                for _ = 1, short do
                    if item_count(CLEANSER) == 0 and item_count(SOLVENT) > 0
                        and item_count(VOPW) >= 3 and item_count('Empty Vial') >= 1 then
                        make_cleanser_batch()
                    end
                    if not make_one_parchment(ing) then break end
                end
            else
                vendorShort[ing] = n
            end
        end
    end
    if next(vendorShort) then
        local byVendor = {}
        for ing, need in pairs(vendorShort) do
            local v = VORI_ITEMS[ing] and VORI or KLAZ
            byVendor[v] = byVendor[v] or {}
            byVendor[v][ing] = need
        end
        for v, lst in pairs(byVendor) do
            vendor_run(v, lst)
        end
    end

    -- final mat check (includes anything already sitting in the open kit)
    for ing, n in pairs(per) do
        if count_everywhere(ing) < n then
            log('FAILED %s: missing %s (%d/%d).', label, ing, count_everywhere(ing), n)
            return false
        end
    end
    if #(rec.ingredients or {}) > KIT_SLOTS then
        log('FAILED %s: %d ingredients exceeds %d kit slots.', label, #rec.ingredients, KIT_SLOTS)
        return false
    end

    if not open_kit() then
        log('FAILED %s: research kit would not open.', label)
        return false
    end
    close_merchant()
    if not clear_kit() then
        log('FAILED %s: kit not empty and could not be cleared.', label)
        return false
    end

    local slot = 1
    for _, ing in ipairs(rec.ingredients) do
        if not place_in_kit(ing, slot) then
            log('FAILED %s: could not place %s.', label, ing)
            clear_kit()
            return false
        end
        slot = slot + 1
    end

    log('Combining %s...', label)
    local ok = combine_and_wait(rec.iniRaw or label, true)
    if ok then
        log('Success: %s (now have %d).', label, scroll_count(rec.iniRaw or label))
    else
        log('FAILED combine: %s.', label)
        clear_kit()
    end
    return ok
end

-- ---------------------------------------------------------------------------
-- Skill-up (replaces researchskill.mac: combines tier mats in the kit until
-- trivial / capped / out of mats; mats must already be in inventory)
-- ---------------------------------------------------------------------------

local function skillup_impl(job)
    local tiers = job.tiers or {}
    local cap = job.cap or 300
    local made = 0
    M.ui.state = 'skillup'
    M.ui.total = 0
    while true do
        check_stop()
        local skill = skill_value()
        if skill >= cap then
            log('Research skill capped (%d/%d).', skill, cap)
            break
        end

        local tier
        if job.tierId then
            for _, t in ipairs(tiers) do
                if t.id == job.tierId then tier = t end
            end
            if tier and skill >= (tier.trivial or 0) then
                log('%s is trivial at skill %d - done.', tier.label, skill)
                break
            end
        else
            -- auto mode: lowest non-trivial tier we actually have mats for,
            -- so the run keeps going on whatever is in the bags and only
            -- stops when everything usable is consumed or trivial
            local any_nontrivial = false
            for _, t in ipairs(tiers) do
                if skill < (t.trivial or 0) then
                    any_nontrivial = true
                    local has = true
                    for _, itname in ipairs(t.items or {}) do
                        if item_count(itname) == 0 then has = false break end
                    end
                    if has then tier = t break end
                end
            end
            if not tier and any_nontrivial then
                log('Out of mats for every non-trivial tier at skill %d - done.', skill)
                break
            end
        end
        if not tier then
            log('All tiers trivial at skill %d.', skill)
            break
        end

        local missing = {}
        for _, itname in ipairs(tier.items or {}) do
            if item_count(itname) == 0 then missing[#missing + 1] = itname end
        end
        if #missing > 0 then
            log('Out of mats for %s: %s', tier.label, table.concat(missing, ', '))
            break
        end
        if free_slots_outside_kit() == 0 then
            log('No free bag space outside the kit - stopping skill-up (products would auto-inventory into the kit and stack).')
            break
        end

        if not open_kit() then break end
        if not clear_kit() then
            log('Kit not empty and could not be cleared - stopping skill-up.')
            break
        end
        local placed = true
        for i, itname in ipairs(tier.items) do
            if not place_in_kit(itname, i) then placed = false break end
        end
        if not placed then
            log('Could not fill kit for %s - stopping.', tier.label)
            clear_kit()
            break
        end
        local ok = combine_and_wait(nil, false)
        if not ok and not flags.lacked then
            log('Combine did not fire for %s - stopping skill-up (check the kit).', tier.label)
            clear_kit()
            break
        end
        made = made + 1
        M.ui.done = made
        local newSkill = skill_value()
        M.ui.current = string.format('%s: combine %d, skill %d/%d', tier.label, made, newSkill, cap)
        if made % 10 == 0 then
            log('Skill-up progress: %d combines, skill %d/%d.', made, newSkill, cap)
        end
    end
    clear_kit()
    log('Skill-up finished: %d combine(s), skill %d/%d.', made, skill_value(), cap)
end

-- ---------------------------------------------------------------------------
-- Doctor: read-only preflight (safe to call from the UI thread)
-- ---------------------------------------------------------------------------

function M.doctor(opts)
    local kp = (opts and opts.kitPack) or kitPack
    local out = {}
    local function add(ok, msg, ...)
        if select('#', ...) > 0 then msg = string.format(msg, ...) end
        out[#out + 1] = { ok = ok and true or false, msg = msg }
    end

    local kit = mq.TLO.FindItem('=' .. KIT_NAME)
    if kit.ID() then
        if (kit.ItemSlot2() or -1) ~= -1 then
            add(false, '%s is inside another bag - move it to a top-level bag slot.', KIT_NAME)
        else
            local slot = kit.ItemSlot() or 0
            local pk = (slot >= 23 and slot <= 32) and (slot - 22) or kp
            add(true, '%s in pack%d (%d slots).', KIT_NAME, pk,
                mq.TLO.Me.Inventory('pack' .. pk).Container() or 0)
        end
    else
        add(false, '%s NOT found in inventory.', KIT_NAME)
    end

    local zone = (mq.TLO.Zone.ShortName() or '?'):lower()
    add(zone == 'poknowledge', 'Zone: %s%s', zone,
        zone == 'poknowledge' and '' or '  (PoK recommended - vendors live there)')

    for _, v in ipairs({ KLAZ, VORI, NURSA, CADEN }) do
        local found = (mq.TLO.Spawn(string.format('npc "%s"', v)).ID() or 0) > 0
        add(found, 'Vendor %s: %s', v, found and 'found' or 'NOT in zone')
    end

    add(skill_value() > 0, 'Research skill: %d', skill_value())
    local free = mq.TLO.Me.FreeInventory() or 0
    add(free > 0, 'Free inventory slots: %d', free)
    add(true, 'Platinum: %d', mq.TLO.Me.Platinum() or 0)
    add(true, 'Stock: %dx %s, %dx %s, %dx Empty Vial',
        item_count(CLEANSER), CLEANSER, item_count(VOPW), VOPW, item_count('Empty Vial'))

    local dropped = {}
    for _, def in pairs(PARCH) do
        dropped[#dropped + 1] = string.format('%dx %s', item_count(def.dropped), def.dropped)
    end
    table.sort(dropped)
    add(true, 'Dropped parchment stock: ' .. table.concat(dropped, ', '))
    return out
end

-- ---------------------------------------------------------------------------
-- Main run
-- ---------------------------------------------------------------------------

local function run_impl(job)
    kitPack = job.kitPack or 10
    local items = job.items or {}
    if #items == 0 then
        log('Nothing to craft.')
        return
    end

    -- 1) aggregate ingredient needs across the whole queue
    local totals = {}
    local totalCopies = 0
    for _, it in ipairs(items) do
        totalCopies = totalCopies + (it.copies or 1)
        for ing, per in pairs(recipe_need_counts(it.rec)) do
            totals[ing] = (totals[ing] or 0) + per * (it.copies or 1)
        end
    end
    M.ui.total = totalCopies
    M.ui.done = 0
    log('Run: %d spell(s), %d combine(s).', #items, totalCopies)

    -- 2) parchment shortfalls + dropped-item gate
    local parchShort, totalParchShort = {}, 0
    local missingDropped = {}
    for ptype, def in pairs(PARCH) do
        local need = totals[ptype] or 0
        if need > 0 then
            local short = need - count_everywhere(ptype)
            if short > 0 then
                parchShort[ptype] = short
                totalParchShort = totalParchShort + short
                local dShort = short - item_count(def.dropped)
                if dShort > 0 then
                    missingDropped[#missingDropped + 1] = string.format('%dx %s', dShort, def.dropped)
                end
            end
        end
    end
    if #missingDropped > 0 then
        log('MISSING dropped parchment items: %s', table.concat(missingDropped, ', '))
        log('Loot these into your bags, then Start again.')
        return
    end

    -- 3) cleanser / VoPW batch math
    local cleanserShort = math.max(0, totalParchShort - item_count(CLEANSER))
    local cleanserBatches = math.ceil(cleanserShort / 4)
    local vopwShort = math.max(0, cleanserBatches * 3 - item_count(VOPW))
    local vopwBatches = math.ceil(vopwShort / 5)
    if totalParchShort > 0 then
        log('Parchment prep: %d parchment(s), %d cleanser batch(es), %d VoPW batch(es).',
            totalParchShort, cleanserBatches, vopwBatches)
    end

    -- 4) shopping lists (absolute needs; shortfalls computed at the vendor)
    local shop = { [KLAZ] = {}, [VORI] = {}, [NURSA] = {}, [CADEN] = {} }
    for ing, need in pairs(totals) do
        if not PARCH[ing] then
            local v = VORI_ITEMS[ing] and VORI or KLAZ
            shop[v][ing] = need
        end
    end
    if vopwBatches > 0 or cleanserBatches > 0 then
        local k = shop[KLAZ]
        k['Empty Vial'] = (k['Empty Vial'] or 0) + vopwBatches * 5 + cleanserBatches
        k['Gnomish Heat Source'] = (k['Gnomish Heat Source'] or 0) + vopwBatches
        k['Water Flask'] = (k['Water Flask'] or 0) + vopwBatches * 4
    end
    if cleanserBatches > 0 then shop[CADEN][SOLVENT] = cleanserBatches end
    for ptype, short in pairs(parchShort) do
        shop[NURSA][PARCH[ptype].solution] = short
    end

    -- 5) one trip per vendor
    M.ui.state = 'buying'
    for _, vendor in ipairs({ KLAZ, VORI, CADEN, NURSA }) do
        vendor_run(vendor, shop[vendor])
    end

    -- 6) prep subcombines
    M.ui.state = 'prep'
    for b = 1, vopwBatches do
        check_stop()
        log('Vial of Pure Water batch %d/%d...', b, vopwBatches)
        if not make_vopw_batch() then log('WARNING: VoPW batch %d failed.', b) end
    end
    for b = 1, cleanserBatches do
        check_stop()
        log('Celestial Cleanser batch %d/%d...', b, cleanserBatches)
        if not make_cleanser_batch() then log('WARNING: Cleanser batch %d failed.', b) end
    end
    for ptype, short in pairs(parchShort) do
        local made, attempts = 0, 0
        while made < short and attempts < short * 2 + 3 do
            check_stop()
            attempts = attempts + 1
            if make_one_parchment(ptype) then
                made = made + 1
            elseif item_count(CLEANSER) == 0 and item_count(SOLVENT) > 0
                and item_count(VOPW) >= 3 and item_count('Empty Vial') >= 1 then
                make_cleanser_batch()
            else
                break
            end
        end
        if made < short then log('WARNING: only made %d/%d %s.', made, short, ptype) end
    end

    -- 7) craft queue
    M.ui.state = 'crafting'
    local failed = {}
    local invFull = false
    for _, it in ipairs(items) do
        if invFull then break end
        for _ = 1, (it.copies or 1) do
            check_stop()
            if (mq.TLO.Me.FreeInventory() or 0) == 0 then
                log('ERROR: inventory full - stopping craft phase.')
                invFull = true
                break
            end
            if not craft_one(it) then
                failed[#failed + 1] = { rec = it.rec, name = it.name }
            end
            M.ui.done = M.ui.done + 1
        end
    end

    -- 8) one retry pass for failures
    if #failed > 0 and not invFull then
        log('Retrying %d failed combine(s)...', #failed)
        local still = {}
        for _, it in ipairs(failed) do
            check_stop()
            if not craft_one(it) then still[#still + 1] = it end
        end
        failed = still
    end

    -- 9) summary
    clear_kit()
    if #failed == 0 then
        log('Run complete: %d/%d combines OK.', M.ui.done, M.ui.total)
    else
        local names = {}
        for _, it in ipairs(failed) do names[#names + 1] = it.name or it.rec.name end
        log('Run complete with %d failure(s): %s', #failed, table.concat(names, ', '))
    end
end

function M.run(job)
    if M.busy() then return end
    stopRequested = false
    M.ui.log = {}
    M.ui.state = 'starting'
    M.ui.done, M.ui.total = 0, 0
    local ok, err = pcall(function()
        if job.kind == 'skillup' then
            skillup_impl(job)
        else
            run_impl(job)
        end
    end)
    if not ok then
        if tostring(err):find('__RL_STOP__', 1, true) then
            mq.cmd('/nav stop')
            log('Stopped by user.')
        else
            log('ERROR: %s', tostring(err))
        end
    end
    M.ui.state = 'idle'
    M.ui.current = ''
end

return M
