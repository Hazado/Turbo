-- TurboGear/don_spells.lua
-- Ownership for DoN packs/singles from references/don_spell_catalog.lua.
--
-- Pack:  pack item held OR every ability satisfied
--        (that ability's scroll/tome held OR ability scribed).
-- Single: item held OR ability scribed.

local M = {}

local catalog = nil
local by_pack_id = nil
local by_single_id = nil
local by_scroll_id = nil
local by_name = nil

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function norm(s)
    s = trim(s):lower()
    s = s:gsub('`', "'"):gsub('\226\128\152', "'"):gsub('\226\128\153', "'")
    return s
end

local function ensure_index()
    if by_pack_id then return true end
    local ok, data = pcall(require, 'references.don_spell_catalog')
    if not ok or type(data) ~= 'table' then
        by_pack_id = {}
        by_single_id = {}
        by_scroll_id = {}
        by_name = {}
        return false
    end
    catalog = data
    by_pack_id = {}
    by_single_id = {}
    by_scroll_id = {}
    by_name = {}
    for className, bucket in pairs(data) do
        if type(bucket) == 'table' then
            for _, pack in ipairs(bucket.packs or {}) do
                if type(pack) == 'table' then
                    local pid = tonumber(pack.id)
                    local rec = { kind = 'pack', class = className, row = pack }
                    if pid then by_pack_id[pid] = rec end
                    local pn = norm(pack.name)
                    if pn ~= '' then by_name[pn] = rec end
                    for _, ab in ipairs(pack.abilities or {}) do
                        local sid = tonumber(ab and ab.item)
                        if sid then by_scroll_id[sid] = rec end
                    end
                end
            end
            for _, single in ipairs(bucket.singles or {}) do
                if type(single) == 'table' then
                    local iid = tonumber(single.id)
                    local rec = { kind = 'single', class = className, row = single }
                    if iid then by_single_id[iid] = rec end
                    local sn = norm(single.name)
                    if sn ~= '' then by_name[sn] = rec end
                end
            end
        end
    end
    return true
end

--- Resolve a BiS entry to a catalog pack/single, or nil.
function M.lookup_entry(entry)
    if type(entry) ~= 'table' then return nil end
    if not ensure_index() then return nil end
    for _, id in ipairs(entry.ids or {}) do
        id = tonumber(id)
        if id then
            local hit = by_pack_id[id] or by_single_id[id] or by_scroll_id[id]
            if hit then return hit end
        end
    end
    local name = norm(entry.item)
    if name ~= '' and by_name[name] then return by_name[name] end
    for _, alias in ipairs(entry.names or {}) do
        local n = norm(alias)
        if n ~= '' and by_name[n] then return by_name[n] end
    end
    return nil
end

local function snap_has_id(snap, item_id)
    item_id = tonumber(item_id)
    if not item_id or item_id <= 0 or type(snap) ~= 'table' then return nil end
    local idx = snap._bis_index
    if type(idx) == 'table' and type(idx.by_id) == 'table' then
        return idx.by_id[item_id]
    end
    -- Build a tiny id scan when called outside bis.match_entry (tests / spellsync).
    local function scan(list)
        for _, it in ipairs(list or {}) do
            if tonumber(it.id) == item_id then
                return { item = it, status = 'carried' }
            end
        end
        return nil
    end
    return scan(snap.equipped) or scan(snap.bags) or scan(snap.bank)
end

local function snap_knows_ability(snap, ability)
    if type(ability) ~= 'table' or type(snap) ~= 'table' then return false end
    local sid = tonumber(ability.spell_id)
    if sid and sid > 0 and type(snap.spell_ids) == 'table' and snap.spell_ids[sid] then
        return true
    end
    local want = norm(ability.ability)
    if want == '' then return false end
    local spells = snap.spells
    if type(spells) ~= 'table' then return false end
    local row = spells[want]
    if type(row) == 'table' and ((row.book == true) or (tonumber(row.book) or 0) > 0) then
        return true
    end
    for key, rec in pairs(spells) do
        if type(rec) == 'table' then
            local n = norm(rec.name or key)
            if n == want and ((rec.book == true) or (tonumber(rec.book) or 0) > 0) then
                return true
            end
        end
    end
    return false
end

local function ability_satisfied_in_snap(snap, ability)
    local rec = snap_has_id(snap, ability.item)
    if rec then return true, 'carried', rec end
    if snap_knows_ability(snap, ability) then return true, 'known', nil end
    return false, nil, nil
end

--- Snapshot match. Returns handled, match, status.
--- handled=false → caller should use generic BiS matching.
function M.try_match(entry, snap)
    local hit = M.lookup_entry(entry)
    if not hit then return false, nil, nil end
    local row = hit.row
    if hit.kind == 'pack' then
        local packRec = snap_has_id(snap, row.id)
        if packRec then
            return true, packRec.item or row.name, packRec.status or 'carried'
        end
        local anyKnown = false
        local lastItem = nil
        for _, ab in ipairs(row.abilities or {}) do
            local ok, how, rec = ability_satisfied_in_snap(snap, ab)
            if not ok then return true, nil, 'missing' end
            if how == 'known' then anyKnown = true end
            if rec and rec.item then lastItem = rec.item end
        end
        if #(row.abilities or {}) == 0 then return true, nil, 'missing' end
        return true, lastItem or row.name, anyKnown and 'known' or 'carried'
    end
    -- single
    local rec = snap_has_id(snap, row.id)
    if rec then return true, rec.item or row.name, rec.status or 'carried' end
    if snap_knows_ability(snap, {
        spell_id = row.spell_id,
        ability = row.ability,
        item = row.id,
    }) then
        return true, row.name, 'known'
    end
    return true, nil, 'missing'
end

--- True if item_id is a DoN scroll/tome/single/pack learn item (scribe consume).
function M.is_learn_item_id(item_id)
    item_id = tonumber(item_id)
    if not item_id or item_id <= 0 then return false end
    if not ensure_index() then return false end
    if by_scroll_id[item_id] or by_single_id[item_id] or by_pack_id[item_id] then
        return true
    end
    return false
end

local function live_has_item(item_id)
    item_id = tonumber(item_id)
    if not item_id or item_id <= 0 then return false end
    local ok, cnt = pcall(function()
        local mq = require('mq')
        local fi = mq.TLO.FindItem and mq.TLO.FindItem(item_id)
        if fi and fi() then return tonumber(fi.Count()) or 0 end
        return 0
    end)
    return ok and (cnt or 0) > 0
end

-- Live ownership = Me.Book / Me.CombatAbility (via spell_known), same as
-- /echo Book?=${Me.Book[Name]}. Cache is a positive accelerator only.
local function live_knows(ability_or_row)
    local sid = tonumber(ability_or_row.spell_id)
    local name = trim(ability_or_row.ability or ability_or_row.name)
    local ok, mod = pcall(require, 'spell_known')
    if not ok or not mod then return false end
    local known = false
    if sid and sid > 0 and mod.live_id and mod.live_id(sid) then known = true end
    if not known and name ~= '' and mod.live and mod.live(name) then known = true end
    if known then
        pcall(function()
            local SC = require('spell_cache')
            if sid and sid > 0 and SC.probe_id then SC.probe_id(sid) end
            if name ~= '' and SC.probe_name then SC.probe_name(name) end
        end)
    end
    return known
end

--- Live match (FindItem + Book/CombatAbility). Same return shape as try_match.
function M.try_live_match(entry)
    local hit = M.lookup_entry(entry)
    if not hit then return false, nil, nil end
    local row = hit.row
    if hit.kind == 'pack' then
        if live_has_item(row.id) then return true, row.name, 'carried' end
        local anyKnown = false
        for _, ab in ipairs(row.abilities or {}) do
            if live_has_item(ab.item) then
                -- scroll held counts for this ability
            elseif live_knows(ab) then
                anyKnown = true
            else
                return true, nil, 'missing'
            end
        end
        if #(row.abilities or {}) == 0 then return true, nil, 'missing' end
        return true, row.name, anyKnown and 'known' or 'carried'
    end
    if live_has_item(row.id) then return true, row.name, 'carried' end
    if live_knows(row) then return true, row.name, 'known' end
    return true, nil, 'missing'
end

local function class_key(className)
    className = trim(className)
    if className == 'Shadowknight' then return 'Shadow Knight' end
    return className
end

--- Probe every catalog ability for a class into spell maps (spellsync).
function M.merge_into_spell_maps(className, out, spell_ids_out, probe_book, probe_id)
    if not ensure_index() or type(catalog) ~= 'table' then return end
    local bucket = catalog[class_key(className)]
    if type(bucket) ~= 'table' then return end
    local function add_ability(spell_id, ability)
        ability = trim(ability)
        spell_id = tonumber(spell_id)
        local known = false
        if spell_id and spell_id > 0 and probe_id then
            known = probe_id(spell_id) == true
            if known then spell_ids_out[spell_id] = true end
        end
        if ability ~= '' and probe_book and probe_book(ability) then
            known = true
        end
        if ability == '' then return end
        local key = norm(ability)
        local prev = out[key]
        if not prev then
            out[key] = {
                name = ability,
                book = known and 1 or 0,
                scroll = 0,
                spell_id = spell_id,
            }
        elseif known then
            prev.book = 1
            if spell_id then prev.spell_id = spell_id end
        end
    end
    for _, pack in ipairs(bucket.packs or {}) do
        for _, ab in ipairs((pack and pack.abilities) or {}) do
            add_ability(ab.spell_id, ab.ability)
        end
    end
    for _, single in ipairs(bucket.singles or {}) do
        add_ability(single.spell_id, single.ability)
    end
end

-- Test / debug helpers
function M._reset_index_for_tests()
    catalog = nil
    by_pack_id = nil
    by_single_id = nil
    by_scroll_id = nil
    by_name = nil
end

return M
