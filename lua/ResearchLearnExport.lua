--[[ Compatibility shim — use /tgear exportspells or turbogear/export_spells.lua ]]
local mq = require('mq')
local path = (mq.TLO.MacroQuest.Path() or ''):gsub('[\\/]+$', '') .. '\\lua\\turbogear\\export_spells.lua'
local chunk, err = loadfile(path)
if not chunk then
    error('ResearchLearnExport moved into turbogear/export_spells.lua: ' .. tostring(err))
end
return chunk((...))
