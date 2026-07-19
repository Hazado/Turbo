-- Run from repo root: luajit lua/tests/turbo_bot_pause_test.lua
package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path

local cmds = {}
package.loaded.mq = {
    cmd = function(c) cmds[#cmds + 1] = c end,
    TLO = {
        Lua = {
            Script = function(name)
                return {
                    Status = {
                        Equal = function(want)
                            return function()
                                return name == 'rgmercs' and want == 'RUNNING' and package.loaded._rg_running == true
                            end
                        end,
                    },
                }
            end,
        },
        RGMercs = {
            Config = function(key)
                return function()
                    if key == 'RunMovePaused' then
                        return package.loaded._rg_run_move_paused == true
                    end
                    return nil
                end
            end,
        },
    },
}

package.loaded['turbo_lib.bot_pause'] = nil
local B = require('turbo_lib.bot_pause')

local passed, failed = 0, 0
local function check(cond, label)
    if cond then passed = passed + 1 else failed = failed + 1; io.stderr:write('FAIL: ', label, '\n') end
end

package.loaded._rg_running = true
cmds = {}
check(B.pause() == 'rgl' and cmds[1] == '/rgl pause', 'rgmercs pause uses /rgl pause')
cmds = {}
check(B.resume() == 'rgl' and cmds[1] == '/rgl unpause', 'rgmercs resume uses /rgl unpause')

package.loaded._rg_running = false
cmds = {}
check(B.pause() == 'e3p' and cmds[1] == '/e3p on', 'e3 pause uses /e3p on')
cmds = {}
check(B.resume() == 'e3p' and cmds[1] == '/e3p off', 'e3 resume uses /e3p off')

package.loaded._rg_running = false
package.loaded._rg_run_move_paused = true
check(B.run_move_paused() == false, 'run_move_paused false when rgmercs not running')
package.loaded._rg_running = true
package.loaded._rg_run_move_paused = false
check(B.run_move_paused() == false, 'run_move_paused false when setting off')
package.loaded._rg_run_move_paused = true
check(B.run_move_paused() == true, 'run_move_paused true when RUNNING and setting on')
check(type(B.RUN_MOVE_PAUSED_TIP) == 'string' and #B.RUN_MOVE_PAUSED_TIP > 20, 'tip text present')

if failed > 0 then
    io.stderr:write(string.format('turbo_bot_pause_test: %d passed, %d failed\n', passed, failed))
    os.exit(1)
end
print(string.format('turbo_bot_pause_test: %d passed, %d failed', passed, failed))
