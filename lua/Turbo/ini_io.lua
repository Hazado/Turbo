--[[
  Turbo/ini_io.lua
  Shared INI read/write helpers used by the Turbo hub and companions
  (e.g. turbowares). Extracted from init.lua so callers can require()
  without depending on hub locals.

  @version lua/Turbo/ini_io.lua 1.0.0
]]

local M = {}

function M.writeIniKey(filePath, section, key, value)
    local lines = {}
    local f = io.open(filePath, 'r')
    if f then
        for line in f:lines() do table.insert(lines, line) end
        f:close()
    end

    local inSection = false
    local keyWritten = false
    local sectionFound = false
    local result = {}

    for _, line in ipairs(lines) do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            if inSection and not keyWritten then
                table.insert(result, key .. '=' .. value)
                keyWritten = true
            end
            if sec == section and sectionFound then
                inSection = true
                goto nextline
            end
            inSection = (sec == section)
            if inSection then sectionFound = true end
        elseif inSection then
            local k = line:match('^([^=]+)=')
            if k and k:match('^%s*(.-)%s*$') == key then
                table.insert(result, key .. '=' .. value)
                keyWritten = true
                goto nextline
            end
        end
        table.insert(result, line)
        ::nextline::
    end

    if not sectionFound then
        table.insert(result, '')
        table.insert(result, '[' .. section .. ']')
        table.insert(result, key .. '=' .. value)
    elseif not keyWritten then
        table.insert(result, key .. '=' .. value)
    end

    f = io.open(filePath, 'w')
    if not f then return false end
    for _, line in ipairs(result) do f:write(line .. '\n') end
    f:close()
    return true
end

function M.deleteIniKey(filePath, section, key)
    local f = io.open(filePath, 'r')
    if not f then return false end

    local lines = {}
    local inSection = false
    local deleted = false
    for line in f:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            inSection = (sec == section)
            lines[#lines + 1] = line
        elseif inSection then
            local k = line:match('^([^=]+)=')
            if k and k:match('^%s*(.-)%s*$') == key then
                deleted = true
            else
                lines[#lines + 1] = line
            end
        else
            lines[#lines + 1] = line
        end
    end
    f:close()

    if not deleted then return false end

    local wf = io.open(filePath, 'w')
    if not wf then return false end
    for _, line in ipairs(lines) do wf:write(line .. '\n') end
    wf:close()
    return true
end

function M.readIniKey(filePath, section, key)
    local f = io.open(filePath, 'r')
    if not f then return nil end
    local inSection = false
    for line in f:lines() do
        local sec = line:match('^%[(.-)%]%s*$')
        if sec then
            inSection = (sec == section)
        elseif inSection then
            local k, v = line:match('^([^=]+)=(.*)')
            if k and k:match('^%s*(.-)%s*$') == key then
                f:close()
                return v
            end
        end
    end
    f:close()
    return nil
end

local function stripIniValueForDisplay(raw)
    if not raw then return '—' end
    local s = raw:match('^([^;]*)') or raw
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

function M.readIniSectionPairs(filePath, section)
    local out = {}
    local f = io.open(filePath, 'r')
    if not f then return out end

    local inSection = false
    for line in f:lines() do
        local sec = line:match('^%s*%[(.-)%]%s*$')
        if sec then
            if inSection then break end
            inSection = (sec == section)
        elseif inSection then
            local k, v = line:match('^%s*([^;#][^=]-)%s*=%s*(.*)$')
            if k then
                table.insert(out, {
                    key = k:match('^%s*(.-)%s*$'),
                    value = stripIniValueForDisplay(v),
                })
            end
        end
    end

    f:close()
    return out
end

return M
