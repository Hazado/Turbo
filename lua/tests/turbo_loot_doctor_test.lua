-- Run from repo root:  luajit lua/tests/turbo_loot_doctor_test.lua
package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path

-- Stub mq so requiring loot_doctor does not need a live client.
package.loaded.mq = package.loaded.mq or {
    TLO = {
        MQ2Mono = { Query = function() return function() return '' end end },
        SpawnCount = function() return function() return 0 end end,
        Spawn = function() return function() return false end end,
        NearestSpawn = function() return function() return false end end,
        Macro = { Name = function() return '' end },
        Me = { CleanName = function() return 'Tester' end, Name = function() return 'Tester' end },
    },
}

local D = require('Turbo.loot_doctor')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

local function eval(ctx)
    return D.evaluate_gates(ctx)
end

do
    local ok, by = eval({
        turbo = true, combat = true, mode = 'single', looter = 'Bob',
        corpses = 2, aggro = false, events_ok = true,
    })
    check(ok == true and by == nil, 'healthy single is ready')
end

do
    local ok, by, hint = eval({
        turbo = false, combat = true, mode = 'single', looter = 'Bob',
        corpses = 2, aggro = false, events_ok = true,
    })
    check(ok == false and by == 'Turbo=false', 'Turbo off blocks')
    check(type(hint) == 'string' and hint:find('ON', 1, true), 'Turbo hint mentions ON')
end

do
    local ok, by = eval({
        turbo = true, combat = true, mode = 'single', looter = 'NOBODY',
        corpses = 2, aggro = false, events_ok = true,
    })
    check(ok == false and by == 'Looter=NOBODY', 'NOBODY looter blocks single')
end

do
    local ok, by = eval({
        turbo = true, combat = false, mode = 'single', looter = 'Bob',
        corpses = 2, aggro = true, events_ok = true,
    })
    check(ok == false and by == 'CombatLoot (aggro in radius)', 'combat+aggro blocks')
end

do
    local ok, by = eval({
        turbo = true, combat = false, mode = 'single', looter = 'Bob',
        corpses = 2, aggro = false, events_ok = true,
    })
    check(ok == true, 'CombatLoot off is ok when no aggro')
end

do
    local ok, by, hint = eval({
        turbo = true, combat = true, mode = 'single', looter = 'Bob',
        corpses = 0, aggro = false, events_ok = true,
        radius = 80, nearest_corpse_ft = 120,
    })
    check(ok == false and by == 'no corpses in LootRadius', 'zero corpses blocks')
    check(type(hint) == 'string' and hint:find('120', 1, true) and hint:find('80', 1, true),
        'nearest corpse distance in hint')
end

do
    local ok, by = eval({
        turbo = true, combat = true, mode = 'single', looter = 'Bob',
        corpses = 1, aggro = false, events_ok = true, events_stale = true,
    })
    check(ok == false and by:find('stale', 1, true), 'stale events block when otherwise ready')
end

do
    local ok, by = eval({
        turbo = true, combat = true, mode = 'multi', looter = 'NOBODY',
        multi_ok = false, corpses = 1, aggro = false, events_ok = true,
    })
    check(ok == false and by == 'multi slots empty', 'empty multi blocks')
end

do
    local lines = D.format_lines({
        ready = false,
        blocked_by = 'CombatLoot (aggro in radius)',
        hint = 'Enable CombatLoot',
        turbo = true,
        combat = false,
        mode = 'single',
        live_looter = 'Bob',
        ui_looter = 'Bob',
        radius = 15,
        loot_distance = 80,
        corpses = 0,
        aggro = true,
        nearest_corpse_ft = 40,
        hide_mode = 'LOOTED',
        turboloot_running = false,
        events_ok = true,
        events_stale = false,
        events_label = 'OK',
        me = 'Bob',
    })
    local blob = table.concat(lines, '\n')
    check(blob:find('AUTO READY: ', 1, true) ~= nil, 'format has verdict')
    check(blob:find('mismatch', 1, true) ~= nil, 'format flags radius mismatch')
    check(blob:find('Closest npccorpse', 1, true) ~= nil, 'format shows nearest corpse')
    check(blob:find('\226\128\148', 1, true) == nil, 'no utf8 emdash in output')
    check(blob:find('—', 1, true) == nil, 'no emdash character in output')
end

if failed > 0 then
    io.stderr:write(string.format('turbo_loot_doctor_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end
print(string.format('turbo_loot_doctor_test: %d passed, %d failed', passed, failed))
