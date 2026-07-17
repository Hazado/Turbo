-- Run from repo root: luajit lua\tests\turbo_update_check_spawn_test.lua
-- Verifies CreateProcess CREATE_NO_WINDOW spawn path (no os.execute) can run
-- a hidden powershell that writes a version file.

package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path

-- Stub mq before requiring update_check.
local tempDir = (os.getenv('TEMP') or os.getenv('TMP') or '.') .. '\\turbo_uc_test_' .. tostring(os.time())
os.execute('mkdir "' .. tempDir .. '" >NUL 2>&1')

package.preload['mq'] = function()
    return {
        configDir = tempDir,
        luaDir = 'lua',
    }
end

local UC = require('Turbo.update_check')

-- Force a fetch by clearing throttle state via tick with fresh g.
local g = {
    checkForUpdates = true,
    updateCheckAt = 0,
}
UC.tick(g)

local resultPath = tempDir .. '\\turbo_update_check.txt'
local deadline = os.clock() + 30
local got = nil
while os.clock() < deadline do
    local f = io.open(resultPath, 'r')
    if f then
        got = (f:read('*l') or ''):match('^%s*(.-)%s*$')
        f:close()
        if got and got:match('^%d+%.%d+') then break end
    end
    -- Busy-wait briefly; CreateProcess is async.
    local t = os.clock() + 0.25
    while os.clock() < t do end
    UC.tick(g)
end

local ok = got and got:match('^%d+%.%d+')
io.write(string.format(
    'turbo_update_check_spawn_test: %s (remote=%s)\n',
    ok and 'passed' or 'FAILED',
    tostring(got or 'nil')))

-- Cleanup best-effort
pcall(function()
    os.remove(resultPath)
    os.remove(tempDir .. '\\turbo_update_check.ps1')
    os.remove(tempDir .. '\\turbo_update_check.fetching')
end)

os.exit(ok and 0 or 1)
