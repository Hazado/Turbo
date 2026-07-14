package.path = 'lua/turbogear/?.lua;lua/turbogear/?/init.lua;' .. package.path

local G = require('runtime_guard')

local passed, failed = 0, 0

local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write('FAIL: ', tostring(label), '\n')
    end
end

check(G.status_is_running('Running') == true, 'Running is active')
check(G.status_is_running('running') == true, 'running is active')
check(G.status_is_running('RUN') == true, 'RUN is active')
check(G.status_is_running('Not Running') == false, 'Not Running is inactive')
check(G.status_is_running('Stopped') == false, 'Stopped is inactive')
check(G.status_is_running('Ending') == false, 'Ending is inactive')
check(G.status_is_running('') == false, 'empty is inactive')

check(G.autostart_decision({ main = false, bg = false }, '') == 'start_bg', 'no owner starts bg')
check(G.autostart_decision({ main = false, bg = true }, '') == 'publish_bg', 'bg owner publishes')
check(G.autostart_decision({ main = true, bg = false }, '') == 'start_bg', 'main UI starts bg owner')
check(G.autostart_decision({ main = true, bg = true }, '') == 'publish_bg', 'normal duplicate prefers existing bg command path')
check(G.autostart_decision({ main = true, bg = false }, 'repair') == 'repair_bg', 'repair starts bg beside main UI')
check(G.autostart_decision({ main = true, bg = true }, 'repair') == 'repair_bg', 'repair restarts bg and leaves main UI')
check(G.autostart_decision({ main = false, bg = true }, 'repair') == 'repair_bg', 'repair restarts bg owner')
check(G.autostart_decision({ main = false, bg = false }, 'repair') == 'repair_bg', 'repair starts bg when no owner')

-- STATIC ROLES: bg processes are 'bg-owner', every UI process is 'viewer';
-- there is no ui-owner or promotion state.
check(G.role({ bg = true }, true, { bg = true }) == 'bg-owner', 'role bg owner')
check(G.role({ bg = false, engine_claim_disabled = true }, false, { bg = true }) == 'viewer', 'role viewer')
check(G.role({ bg = false, engine_claim_disabled = false }, true, {}) == 'viewer', 'ui is always viewer (engine ok ignored)')
check(G.role({ bg = false, engine_claim_disabled = false }, false, {}) == 'viewer', 'ui is always viewer (no promote-pending)')
check(G.role(nil, false, nil) == 'viewer', 'role nil-safe')

-- Announce passivity: bg mutes only while a main UI runs on the same box.
check(G.announce_passive(true, { main = true }) == true, 'bg passive when local UI running')
check(G.announce_passive(true, { main = false }) == false, 'bg active when no local UI')
check(G.announce_passive(true, nil) == false, 'bg active when scripts unknown')
check(G.announce_passive(false, { main = true }) == false, 'ui never announce-passive')
check(G.announce_passive(false, { main = false }) == false, 'ui never announce-passive (no ui script flag)')

check(G.script_summary({ main = true, bg = false }) == 'main=running bg=off', 'script summary')

if failed > 0 then
    io.stderr:write(string.format('turbogear_runtime_guard_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end

print(string.format('turbogear_runtime_guard_test: %d passed, %d failed', passed, failed))
