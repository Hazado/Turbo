--[[
  Turbo/turboloot_path.lua
  Resolve turboloot*.ini profile names and absolute paths for the hub
  and headless companions (turbowares). Prefers the character's live /
  saved active profile — never invent a divergent default first.

  @version lua/Turbo/turboloot_path.lua 1.0.0
]]

local mq = require('mq')
local Paths = require('Turbo.paths')

local M = {}

function M.cleanProfileName(val)
    if not val then return nil end
    local s = tostring(val):match('^%s*(.-)%s*$') or ''
    if s:sub(1, 1) == '"' and s:sub(-1) == '"' then
        s = s:sub(2, -2)
    end
    if s == '' or s == 'NULL' or s == 'null' or s:match('^%$%b{}$') then
        return nil
    end
    return s
end

local function fileExists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

--- Resolve absolute path for a profile filename (Config, then Macros).
--- Returns path, existedBool (same contract as hub resolveTurbolootIniPathForProfile).
function M.resolveTurbolootIniPathForProfile(profile)
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil, false end
    profile = M.cleanProfileName(profile)
    profile = (profile and profile ~= '' and profile ~= 'NULL') and profile or 'turboloot.ini'

    local candidates = {
        mqPath .. '\\Config\\' .. profile,
        mqPath .. '\\Macros\\' .. profile,
    }
    for _, p in ipairs(candidates) do
        if fileExists(p) then return p, true end
    end

    if profile ~= 'turboloot.ini' then
        local fallbacks = {
            mqPath .. '\\Config\\turboloot.ini',
            mqPath .. '\\Macros\\turboloot.ini',
        }
        for _, p in ipairs(fallbacks) do
            if fileExists(p) then return p, true end
        end
    end

    return candidates[1], false
end

local function loadLuaTable(path)
    if not path or path == '' or not fileExists(path) then return nil end
    local ok, tbl = pcall(function()
        local chunk = loadfile(path)
        if not chunk then return nil end
        local result = chunk()
        if type(result) == 'table' then return result end
        return nil
    end)
    if ok and type(tbl) == 'table' then return tbl end
    return nil
end

local function queryE3TurboLootIni()
    local ok, val = pcall(function()
        return mq.TLO.MQ2Mono.Query('e3,TurboLootIni')()
    end)
    if not ok then return nil end
    return M.cleanProfileName(val)
end

local function charSettingsPath()
    local dir = Paths.config_dir()
    if not dir then return nil end
    local charName = tostring(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or '')
        :match('^%s*(.-)%s*$') or ''
    if charName == '' or charName == 'NULL' then
        return dir .. '\\turbo_settings.lua'
    end
    return dir .. '\\turbo_settings_' .. charName .. '.lua'
end

local function sharedSettingsPath()
    local dir = Paths.config_dir()
    if not dir then return nil end
    return dir .. '\\turbo_settings.lua'
end

local function profileFromSettingsTable(tbl)
    if type(tbl) ~= 'table' then return nil end
    if tbl.perCharProfile == true and type(tbl.charProfiles) == 'table' then
        local me = tostring(mq.TLO.Me.Name() or mq.TLO.Me.CleanName() or '')
            :match('^%s*(.-)%s*$') or ''
        if me ~= '' then
            local p = M.cleanProfileName(tbl.charProfiles[me])
            if p then return p end
        end
    end
    return M.cleanProfileName(tbl.savedTurboLootIni)
end

--- Same active INI the character's TurboLoot/hub would use.
--- Order: live E3 TurboLootIni → per-char settings → shared settings → turboloot.ini.
function M.resolveActiveProfileName()
    local live = queryE3TurboLootIni()
    if live then return live end

    local fromChar = profileFromSettingsTable(loadLuaTable(charSettingsPath()))
    if fromChar then return fromChar end

    local fromShared = profileFromSettingsTable(loadLuaTable(sharedSettingsPath()))
    if fromShared then return fromShared end

    return 'turboloot.ini'
end

local function listIniNamesInDir(dir)
    local out = {}
    if not dir or dir == '' then return out end
    local okLfs, lfs = pcall(require, 'lfs')
    if okLfs and lfs and lfs.dir then
        pcall(function()
            for name in lfs.dir(dir) do
                if type(name) == 'string' and name:lower():match('^turboloot.*%.ini$') then
                    out[#out + 1] = name
                end
            end
        end)
        return out
    end
    local handle = io.popen(string.format('dir /b /a-d "%s\\turboloot*.ini" 2>nul', dir))
    if handle then
        for line in handle:lines() do
            local name = line:gsub('[\r\n]', ''):match('^%s*(.-)%s*$')
            if name and name ~= '' then out[#out + 1] = name end
        end
        handle:close()
    end
    return out
end

--- Scan Config (+ Macros) for turboloot*.ini names; active profile first.
function M.listProfileNames()
    local mqPath = tostring(mq.TLO.MacroQuest.Path() or '')
    local seen = {}
    local out = {}
    local function add(name)
        name = M.cleanProfileName(name)
        if not name then return end
        local key = name:lower()
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = name
    end

    add(M.resolveActiveProfileName())
    if mqPath ~= '' then
        for _, name in ipairs(listIniNamesInDir(mqPath .. '\\Config')) do add(name) end
        for _, name in ipairs(listIniNamesInDir(mqPath .. '\\Macros')) do add(name) end
    end
    if #out == 0 then add('turboloot.ini') end
    return out
end

return M
