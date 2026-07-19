--[[
  turbo_lib/bot_pause.lua
  Pause/resume the active combat bot on THIS client.
  If rgmercs is RUNNING -> /rgl pause|unpause; else E3Next /e3p on|off.

  Assumes /rgl pause keeps Lua.Script[rgmercs] Status as RUNNING (loop paused,
  script still loaded) so resume can re-detect the same path.

  RunMovePaused (Chase or Camp While Paused): when true, RGMercs still chase/
  camp after /rgl pause. Hub tip only; no auto set/tempset.
]]

local mq = require('mq')

local M = {}

M.RUN_MOVE_PAUSED_TIP =
    'RGMercs: Chase or Camp While Paused is ON. Turbo pauses RGMercs for loot/give, but that setting still lets chase/camp run. That can pull you off corpses. Turn off: /rgl set runmovepaused false (or /rgl search chase paused).'

function M.rgmercs_running()
    local ok, running = pcall(function()
        return mq.TLO.Lua.Script('rgmercs').Status.Equal('RUNNING')() == true
    end)
    return ok and running == true
end

--- True only when rgmercs is RUNNING and Config(RunMovePaused) is true.
--- Always pcall; never call the RGMercs Config TLO unless Status is RUNNING.
function M.run_move_paused()
    if not M.rgmercs_running() then return false end
    local ok, val = pcall(function()
        return mq.TLO.RGMercs.Config('RunMovePaused')() == true
    end)
    return ok and val == true
end

function M.pause()
    if M.rgmercs_running() then
        mq.cmd('/rgl pause')
        return 'rgl'
    end
    mq.cmd('/e3p on')
    return 'e3p'
end

function M.resume()
    if M.rgmercs_running() then
        mq.cmd('/rgl unpause')
        return 'rgl'
    end
    mq.cmd('/e3p off')
    return 'e3p'
end

return M
