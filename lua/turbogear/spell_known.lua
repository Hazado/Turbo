-- TurboGear/spell_known.lua
-- Shared live probe: scribed spell/song (Book / Me.Spell) or combat ability.

local mq = require('mq')

local M = {}

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$') or ''
end

local function apostrophe_variants(name)
    name = trim(name)
    if name == '' then return {} end
    local out, seen = {}, {}
    local function add(v)
        v = trim(v)
        if v ~= '' and not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    add(name)
    add(name:gsub("'", "`"))
    add(name:gsub("`", "'"))
    add(name:gsub("\226\128\152", "'"):gsub("\226\128\153", "'"))
    add(name:gsub("\226\128\152", "`"):gsub("\226\128\153", "`"))
    return out
end

local function probe_one(name)
    local book = tonumber(mq.TLO.Me.Book(name)()) or 0
    if book > 0 then return true end
    local ca = tonumber(mq.TLO.Me.CombatAbility(name)()) or 0
    if ca > 0 then return true end
    -- Ranked scribed form (spells/songs); nil when not known.
    local sp = mq.TLO.Me.Spell(name)
    if sp and sp() then return true end
    return false
end

--- True if the local character has scribed / unlocked the ability.
function M.live(name)
    local known = false
    pcall(function()
        for _, variant in ipairs(apostrophe_variants(name)) do
            if probe_one(variant) then
                known = true
                return
            end
        end
    end)
    return known
end

--- Resolve spells_new id via Spell[id] (+ RankName) then probe Book/CombatAbility.
function M.live_id(spell_id)
    spell_id = tonumber(spell_id)
    if not spell_id or spell_id <= 0 then return false end
    local known = false
    pcall(function()
        local base = mq.TLO.Spell(spell_id)
        if not base or not base() then return end
        local names = {}
        local rank = base.RankName
        if rank and rank() then
            local rn = rank.Name and rank.Name() or nil
            if not rn or rn == '' then rn = tostring(rank()) end
            if rn and rn ~= '' then names[#names + 1] = rn end
        end
        local bn = base.Name and base.Name() or nil
        if bn and bn ~= '' then names[#names + 1] = bn end
        for _, n in ipairs(names) do
            if M.live(n) then
                known = true
                return
            end
        end
    end)
    return known
end

--- True if any listed spell name or spell id is known.
function M.live_any(names, ids)
    for _, id in ipairs(ids or {}) do
        if M.live_id(id) then return true end
    end
    for _, name in ipairs(names or {}) do
        if M.live(name) then return true end
    end
    return false
end

return M
