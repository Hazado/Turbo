--[[ Compatibility shim — canonical module: turbogear/research_catalog.lua ]]
local mq = require('mq')
local path = (mq.TLO.MacroQuest.Path() or ''):gsub('[\\/]+$', '') .. '\\lua\\turbogear\\research_catalog.lua'
local chunk, err = loadfile(path)
if not chunk then
    error('ResearchLearnCatalog moved into turbogear/research_catalog.lua: ' .. tostring(err))
end
return chunk()
