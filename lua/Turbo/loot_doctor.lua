--[[
   Slim auto-loot gate report for support.
   Answers: why did the E3 slain event not start /mac TurboLoot?

   Usage (via Turbo hub):
     /turbodoctor loot
     /lua run Turbo doctor loot
     /tlootwhy

   @version lua/Turbo/loot_doctor.lua 1.0.0
]]

local mq = require('mq')

local M = {}

local LOW_RADIUS_FT = 30
local TAG = '\at[loot]\ax'

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function e3_bool(val)
    local s = tostring(val or ''):lower()
    return s == 'true' or s == 'on' or s == '1'
end

local function e3_query(key)
    local ok, val = pcall(function()
        return mq.TLO.MQ2Mono.Query('e3,' .. key)()
    end)
    if not ok or val == nil then return '' end
    val = tostring(val)
    if val:find('${', 1, true) or val == 'NULL' or val == 'nil' then return '' end
    return val
end

local function sanitize_name(val)
    val = trim(val)
    if val == '' or val == 'NULL' or val == 'NOBODY' then return 'NOBODY' end
    if val:find('${', 1, true) then return 'NOBODY' end
    return val
end

--- Pure gate evaluation (unit-testable). ctx fields are pre-normalized booleans/numbers/strings.
function M.evaluate_gates(ctx)
    ctx = ctx or {}
    local turbo = ctx.turbo == true
    local combat = ctx.combat == true
    local mode = tostring(ctx.mode or 'single'):lower()
    local looter = sanitize_name(ctx.looter)
    local corpses = tonumber(ctx.corpses) or 0
    local aggro = ctx.aggro == true
    local events_ok = ctx.events_ok ~= false
    local events_stale = ctx.events_stale == true
    local multi_ok = ctx.multi_ok ~= false

    if not turbo then
        return false, 'Turbo=false', 'Turn auto-loot ON (/lua run Turbo on or hub toggle)'
    end
    if mode == 'single' and looter == 'NOBODY' then
        return false, 'Looter=NOBODY', 'Pick a looter (hub picker or /lua run Turbo CharName)'
    end
    if mode == 'multi' and not multi_ok then
        return false, 'multi slots empty', 'Assign BagLoot1+ looters or switch Mode to single/all'
    end
    if mode ~= 'single' and mode ~= 'all' and mode ~= 'multi' then
        return false, 'Mode invalid', 'BagLootMode should be single, all, or multi (live=' .. mode .. ')'
    end
    if not combat and aggro then
        return false, 'CombatLoot (aggro in radius)',
            'Enable CombatLoot, or clear aggro / wait until combat ends'
    end
    if corpses <= 0 then
        local hint = 'No corpses in LootRadius on this client (hidden, out of range, or radius too low)'
        if ctx.nearest_corpse_ft and ctx.radius and ctx.nearest_corpse_ft > ctx.radius then
            hint = string.format(
                'Closest npccorpse is %.0f ft but LootRadius=%d (raise radius or move closer)',
                ctx.nearest_corpse_ft, ctx.radius)
        elseif ctx.hide_mode == 'ALL' or ctx.hide_mode == 'SELF' then
            hint = 'No corpses in radius; corpseHideMode=' .. ctx.hide_mode
                .. ' can hide them (Reloot uses /hidecorpse none)'
        elseif ctx.radius and ctx.radius < LOW_RADIUS_FT then
            hint = string.format('LootRadius=%d is very low; raise it in the Turbo hub', ctx.radius)
        end
        return false, 'no corpses in LootRadius', hint
    end
    if events_stale then
        return false, 'Events stale (bare LootRadius)', 'Run Setup again so Events use MQ2Mono.Query[e3,LootRadius]'
    end
    if not events_ok then
        return false, 'Events missing/incomplete', 'Run /lua run Turbo setup (then /e3reload) to write Tloot* slain hooks'
    end
    return true, nil, nil
end

local function spawn_count(filter)
    local ok, n = pcall(function()
        return tonumber(mq.TLO.SpawnCount(filter)()) or 0
    end)
    return (ok and n) or 0
end

local function has_aggressive(radius)
    radius = math.floor(tonumber(radius) or 0)
    if radius < 1 then return false end
    local ok, val = pcall(function()
        local s = mq.TLO.Spawn(string.format('npc radius %d', radius))
        if not s or not s() then return false end
        return s.Aggressive() == true
    end)
    return ok and val == true
end

local function nearest_corpse_distance()
    local ok, dist = pcall(function()
        local s = mq.TLO.NearestSpawn('npccorpse')
        if not s or not s() then return nil end
        return tonumber(s.Distance())
    end)
    if ok and dist and dist >= 0 and dist < 100000 then
        return dist
    end
    return nil
end

local function macro_is_turboloot()
    local ok, name = pcall(function()
        return tostring(mq.TLO.Macro.Name() or '')
    end)
    if not ok then return false end
    local lower = name:lower()
    return lower == 'turboloot' or lower == 'turboloot.mac'
end

local function inspect_events(ini_path)
    if not ini_path or ini_path == '' then
        return false, false, 'E3 INI path unknown'
    end
    local f = io.open(ini_path, 'r')
    if not f then
        return false, false, 'E3 INI not readable'
    end
    local in_events = false
    local found = { Tloot = false, TlootAll = false }
    for i = 1, 6 do found['TlootM' .. i] = false end
    local stale = false
    local missing_mono = false
    local need_mono = 'MQ2Mono.Query[e3,LootRadius]'
    for line in f:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            in_events = (sec == 'Events')
        elseif in_events then
            local k, v = line:match('^%s*(TlootAll)%s*=%s*(.*)$')
            if not k then k, v = line:match('^%s*(TlootM%d)%s*=%s*(.*)$') end
            if not k then k, v = line:match('^%s*(Tloot)%s*=%s*(.*)$') end
            if k and v then
                found[k] = true
                if v:find(need_mono, 1, true) then
                    -- ok
                elseif v:find('${LootRadius}', 1, true) then
                    stale = true
                else
                    missing_mono = true
                end
            end
        end
    end
    f:close()
    local ok = found.Tloot and found.TlootAll
    for i = 1, 6 do
        if not found['TlootM' .. i] then ok = false end
    end
    if stale then return false, true, 'bare ${LootRadius}' end
    if missing_mono then return false, false, 'missing MQ2Mono LootRadius' end
    if not ok then return false, false, 'Tloot* incomplete' end
    return true, false, 'OK (MQ2Mono LootRadius)'
end

local function read_ini_setting(ini_path, key)
    if not ini_path or ini_path == '' then return '' end
    local f = io.open(ini_path, 'r')
    if not f then return '' end
    local in_settings = false
    local hit = ''
    for line in f:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            in_settings = (sec:lower() == 'settings')
        elseif in_settings then
            local k, v = line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
            if k and k:lower() == key:lower() then
                hit = trim(v)
                break
            end
        end
    end
    f:close()
    return hit
end

local function collect_multi_looters()
    local names = {}
    local any = false
    for i = 1, 6 do
        local n = sanitize_name(e3_query('BagLoot' .. i))
        if n ~= 'NOBODY' then
            names[#names + 1] = n
            any = true
        end
    end
    return names, any
end

function M.gather(opts)
    opts = opts or {}
    local live_turbo = e3_bool(e3_query('Turbo'))
    local live_combat = e3_bool(e3_query('CombatLoot'))
    local mode = trim(e3_query('BagLootMode')):lower()
    if mode == '' then mode = 'single' end
    local live_looter = sanitize_name(e3_query('BagMainLooter'))
    local ui_looter = sanitize_name(opts.ui_looter or '')
    local radius = tonumber(e3_query('LootRadius')) or 0
    if radius < 1 then radius = tonumber(opts.fallback_radius) or 50 end
    radius = math.floor(radius)

    local corpses = spawn_count(string.format('npccorpse radius %d', radius))
    local aggro = has_aggressive(radius)
    local nearest = nil
    if corpses <= 0 then
        nearest = nearest_corpse_distance()
    end

    local multi_names, multi_ok = collect_multi_looters()
    if mode ~= 'multi' then multi_ok = true end

    local loot_ini = opts.loot_ini_path or ''
    local loot_distance = tonumber(read_ini_setting(loot_ini, 'lootDistance'))
        or tonumber(read_ini_setting(loot_ini, 'lootRadiusFeet'))
    local hide_mode = trim(read_ini_setting(loot_ini, 'corpseHideMode')):upper()
    if hide_mode == '' then hide_mode = '(default LOOTED)' end
    local stop_on_attack = trim(read_ini_setting(loot_ini, 'StopLootWhenAttacked')):lower()
    local stop_on = (stop_on_attack == 'on' or stop_on_attack == 'true' or stop_on_attack == '1')

    local events_ok, events_stale, events_label = true, false, 'E3 INI not checked'
    if opts.e3_ini_path and opts.e3_ini_path ~= '' then
        events_ok, events_stale, events_label = inspect_events(opts.e3_ini_path)
    end
    local ready, blocked_by, hint = M.evaluate_gates({
        turbo = live_turbo,
        combat = live_combat,
        mode = mode,
        looter = live_looter,
        multi_ok = multi_ok,
        corpses = corpses,
        aggro = aggro,
        events_ok = events_ok,
        events_stale = events_stale,
        radius = radius,
        nearest_corpse_ft = nearest,
        hide_mode = hide_mode,
    })

    return {
        ready = ready,
        blocked_by = blocked_by,
        hint = hint,
        turbo = live_turbo,
        combat = live_combat,
        mode = mode,
        live_looter = live_looter,
        ui_looter = ui_looter,
        multi_names = multi_names,
        radius = radius,
        loot_distance = loot_distance,
        corpses = corpses,
        aggro = aggro,
        nearest_corpse_ft = nearest,
        hide_mode = hide_mode,
        stop_on_attack = stop_on,
        turboloot_running = macro_is_turboloot(),
        events_ok = events_ok,
        events_stale = events_stale,
        events_label = events_label,
        me = trim(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or '?'),
    }
end

function M.format_lines(report)
    report = report or {}
    local lines = {}
    local function add(fmt, ...)
        lines[#lines + 1] = string.format(fmt, ...)
    end

    if report.ready then
        add('%s AUTO READY: \agYES\ax', TAG)
    else
        add('%s AUTO READY: \arNO\ax - blocked by: \ay%s\ax', TAG, tostring(report.blocked_by or '?'))
    end

    local looter_disp = report.live_looter or 'NOBODY'
    if report.mode == 'multi' then
        if report.multi_names and #report.multi_names > 0 then
            looter_disp = table.concat(report.multi_names, ',')
        else
            looter_disp = '(none)'
        end
    elseif report.mode == 'all' then
        looter_disp = 'ALL'
    end

    add('%s Turbo=%s  CombatLoot=%s  Mode=%s  Looter=%s',
        TAG,
        report.turbo and '\agtrue\ax' or '\arfalse\ax',
        report.combat and '\agtrue\ax' or '\ayfalse\ax',
        tostring(report.mode or '?'),
        looter_disp)

    local radius = tonumber(report.radius) or 0
    local loot_distance = tonumber(report.loot_distance)
    local radius_note
    if loot_distance and loot_distance > 0 and loot_distance ~= radius then
        radius_note = string.format('LootRadius=%d  lootDistance(INI)=%d \ay(mismatch)\ax',
            radius, math.floor(loot_distance))
    elseif radius > 0 and radius < LOW_RADIUS_FT then
        radius_note = string.format('LootRadius=%d \ay(low)\ax', radius)
    else
        radius_note = string.format('LootRadius=%d (matches INI)', radius)
        if not loot_distance then
            radius_note = string.format('LootRadius=%d', radius)
        end
    end

    add('%s %s   Corpses=%d   Aggro in radius=%s',
        TAG,
        radius_note,
        tonumber(report.corpses) or 0,
        report.aggro and '\ayYES\ax' or 'NO')

    if (tonumber(report.corpses) or 0) <= 0 and report.nearest_corpse_ft then
        add('%s Closest npccorpse=%.0f ft  (LootRadius=%d) \ayscene from this client\ax',
            TAG, report.nearest_corpse_ft, radius)
    end

    add('%s Hide=%s  TurboLoot running=%s  Events=%s',
        TAG,
        tostring(report.hide_mode or '?'),
        report.turboloot_running and '\ayyes\ax' or 'no',
        report.events_stale and '\arstale\ax'
            or (report.events_ok and '\agOK\ax' or ('\ay' .. tostring(report.events_label or 'check') .. '\ax')))

    local ui = sanitize_name(report.ui_looter)
    local live = sanitize_name(report.live_looter)
    if report.mode == 'single' and ui ~= 'NOBODY' and ui:lower() ~= live:lower() then
        add('%s UI looter=%s  live=%s \ay(Reloot may still work via UI fallback)\ax',
            TAG, ui, live)
    end

    if report.stop_on_attack then
        add('%s StopLootWhenAttacked=\ayon\ax (can abort mid-run after auto starts)', TAG)
    end

    if not report.ready and report.hint and report.hint ~= '' then
        add('%s Hint: %s', TAG, report.hint)
    end

    add('%s Counts are from \ay%s\ax (the box evaluating slain)', TAG, tostring(report.me or '?'))
    return lines
end

function M.print(opts)
    local report = M.gather(opts)
    for _, line in ipairs(M.format_lines(report)) do
        printf('%s', line)
    end
    return report
end

return M
