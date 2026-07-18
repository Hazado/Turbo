-- TurboGear/keep_qty.lua
-- Persistent stock targets (Want = how many each eligible character should hold).
-- Counts are evaluated by callers from cached inventory rows / store snapshots.

local mq = require('mq')
local cfg = require('config')

local M = {}

local RulesFile = string.format("%s/%s_keepqty.lua", mq.configDir, cfg.CFG.script_name)
local loaded = false
local rules = {}

local VALID_SCOPES = {
    single = true,
    online = true,
    group = true,
    e3 = true,
    all = true,
}

-- Classes that use endurance draughts / mana draughts (AdventureTime tables).
local WANTS_ENDURANCE = {
    WAR = true, PAL = true, SHD = true, BST = true, RNG = true,
    ROG = true, MNK = true, BER = true, BRS = true, BRD = true,
}
local WANTS_MANA = {
    CLR = true, DRU = true, SHM = true, NEC = true, WIZ = true, MAG = true, ENC = true,
}

local CLASS_ROLE = {
    WAR = "tank", PAL = "tank", SHD = "tank",
    CLR = "healer", SHM = "healer", DRU = "healer",
    BRS = "melee", BER = "melee", ROG = "melee", MNK = "melee", BST = "melee", RNG = "melee",
    MAG = "caster", NEC = "caster", WIZ = "caster",
    BRD = "utility", ENC = "utility",
}

local ADVENTURE_DRAUGHTS = {
    "Draught of Shimmering Reflection",
    "Draught of Opulent Healing",
    "Draught of Frenzied Endurance",
    "Draught of Fleeting Fortitude",
    "Draught of Earthen Grit",
    "Draught of Inferno Ward",
    "Draught of the Clear Mind",
}

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$") or ""
end

local function norm(s)
    return trim(s):lower()
end

local function clean_qty(qty)
    qty = math.floor(tonumber(qty) or 0)
    if qty < 0 then qty = 0 end
    if qty > 9999 then qty = 9999 end
    return qty
end

local function clean_scope(scope)
    scope = tostring(scope or "all"):lower()
    return VALID_SCOPES[scope] and scope or "all"
end

local function clean_resource(res)
    res = norm(res)
    if res == "endurance" or res == "mana" then return res end
    return nil
end

local function class_key(class_name)
    local s = trim(class_name):upper()
    if s == "" then return "" end
    if #s <= 3 then return s end
    -- Full names from some snaps
    local map = {
        WARRIOR = "WAR", PALADIN = "PAL", ["SHADOW KNIGHT"] = "SHD", SHADOWKNIGHT = "SHD",
        CLERIC = "CLR", SHAMAN = "SHM", DRUID = "DRU",
        BERSERKER = "BRS", ROGUE = "ROG", MONK = "MNK", BEASTLORD = "BST", RANGER = "RNG",
        MAGICIAN = "MAG", NECROMANCER = "NEC", WIZARD = "WIZ",
        BARD = "BRD", ENCHANTER = "ENC",
    }
    return map[s] or s:sub(1, 3)
end

local function copy_string_set(src)
    if type(src) ~= "table" then return nil end
    local out = {}
    local any = false
    for k, v in pairs(src) do
        if v == true or v == 1 or v == "1" then
            local key = tostring(k):upper()
            if key ~= "" then out[key] = true; any = true end
        elseif type(k) == "number" and type(v) == "string" then
            local key = tostring(v):upper()
            if key ~= "" then out[key] = true; any = true end
        end
    end
    return any and out or nil
end

local function normalize_rule(rule)
    if type(rule) ~= "table" then return nil end
    local name = trim(rule.name or rule.item or rule.item_name)
    local id = tonumber(rule.id or rule.item_id) or 0
    if name == "" and id <= 0 then return nil end
    local group = trim(rule.group or "")
    -- Stock Up board: Orb of Shadows lived under "Quest"; show as Orbs.
    if group == "Quest" then group = "Orbs" end
    local out = {
        name = name,
        id = id > 0 and math.floor(id) or 0,
        qty = clean_qty(rule.qty or rule.want or rule.keep),
        scope = clean_scope(rule.scope),
        updated = tonumber(rule.updated) or os.time(),
        group = group,
        resource = clean_resource(rule.resource),
        roles = copy_string_set(rule.roles),
        classes = copy_string_set(rule.classes),
    }
    return out
end

-- Prefer name keys so id-bearing Keep Qty rows and name-only Adventure seeds
-- collapse to one rule (id-only keys caused duplicate board rows).
local function rule_key(rule)
    rule = normalize_rule(rule)
    if not rule then return "" end
    if rule.name ~= "" then return "name:" .. norm(rule.name) end
    if rule.id > 0 then return "id:" .. tostring(rule.id) end
    return ""
end

function M.class_abbrev(class_name)
    return class_key(class_name)
end

--- Short label; keeps I/II so Draught tiers do not look identical.
function M.display_name(item_name)
    local n = tostring(item_name or "")
    local tier = n:match(" (II)$") or n:match(" (I)$") or ""
    n = n:gsub("^Draught of ", "")
    n = n:gsub(" II$", ""):gsub(" I$", "")
    if tier ~= "" then return n .. " " .. tier end
    return n
end

function M.tier_label(item_name)
    local n = tostring(item_name or "")
    if n:match(" II$") then return "II" end
    if n:match(" I$") then return "I" end
    return ""
end

function M.hint_label(rule)
    rule = normalize_rule(rule) or rule
    if type(rule) ~= "table" then return "" end
    if rule.resource == "endurance" then return "endurance classes" end
    if rule.resource == "mana" then return "mana classes" end
    if rule.roles then
        local parts = {}
        for role, on in pairs(rule.roles) do
            if on then parts[#parts + 1] = tostring(role) end
        end
        table.sort(parts)
        if #parts > 0 then return "roles: " .. table.concat(parts, ", ") end
    end
    if rule.classes then
        local parts = {}
        for cls, on in pairs(rule.classes) do
            if on then parts[#parts + 1] = tostring(cls) end
        end
        table.sort(parts)
        if #parts > 0 then return "classes: " .. table.concat(parts, ", ") end
    end
    return ""
end

--- Want for this character after class/role/resource hints (0 = ineligible / skip).
function M.eff_want(rule, class_name)
    rule = normalize_rule(rule)
    if not rule then return 0 end
    local want = rule.qty or 0
    if want <= 0 then return 0 end
    local cls = class_key(class_name)
    if rule.classes then
        if cls == "" or not rule.classes[cls] then return 0 end
        return want
    end
    if rule.roles then
        local role = CLASS_ROLE[cls]
        if not role then return 0 end
        local hit = rule.roles[role] or rule.roles[role:upper()]
        if not hit then
            for r, on in pairs(rule.roles) do
                if on and norm(r) == norm(role) then hit = true break end
            end
        end
        if not hit then return 0 end
        return want
    end
    if rule.resource == "endurance" then
        if cls ~= "" and not WANTS_ENDURANCE[cls] then return 0 end
        return want
    end
    if rule.resource == "mana" then
        if cls ~= "" and not WANTS_MANA[cls] then return 0 end
        return want
    end
    return want
end

local function dedupe_rules(list)
    local out, seen = {}, {}
    for _, rule in ipairs(list or {}) do
        local key = rule_key(rule)
        if key ~= "" and not seen[key] then
            seen[key] = true
            out[#out + 1] = rule
        elseif key ~= "" and seen[key] then
            -- Merge: keep higher id / newer updated onto the first copy.
            for _, existing in ipairs(out) do
                if rule_key(existing) == key then
                    if (tonumber(rule.id) or 0) > (tonumber(existing.id) or 0) then
                        existing.id = rule.id
                    end
                    if (tonumber(rule.updated) or 0) > (tonumber(existing.updated) or 0) then
                        existing.qty = rule.qty
                        existing.scope = rule.scope
                        existing.updated = rule.updated
                    end
                    if not existing.resource and rule.resource then existing.resource = rule.resource end
                    if (not existing.group or existing.group == "") and rule.group then existing.group = rule.group end
                    break
                end
            end
        end
    end
    return out
end

local function sort_rules()
    table.sort(rules, function(a, b)
        local ga, gb = tostring(a.group or ""), tostring(b.group or "")
        if ga ~= gb then
            if ga == "" then return false end
            if gb == "" then return true end
            return ga < gb
        end
        return norm(a.name ~= "" and a.name or tostring(a.id)) < norm(b.name ~= "" and b.name or tostring(b.id))
    end)
end

function M.load(force)
    if loaded and not force then return rules end
    loaded = true
    rules = {}
    local migrated = false
    local ok, data = pcall(dofile, RulesFile)
    if ok and type(data) == "table" then
        for _, rec in ipairs(data) do
            local was_quest = trim(rec and rec.group or "") == "Quest"
            local rule = normalize_rule(rec)
            if rule then
                if was_quest and rule.group == "Orbs" then migrated = true end
                rules[#rules + 1] = rule
            end
        end
    end
    local before = #rules
    rules = dedupe_rules(rules)
    sort_rules()
    if #rules ~= before or migrated then pcall(function() mq.pickle(RulesFile, rules) end) end
    return rules
end

function M.save()
    M.load()
    local ok, err = pcall(function() mq.pickle(RulesFile, rules) end)
    if not ok then return false, tostring(err or "Could not save Keep Qty rules.") end
    return true
end

function M.rules()
    return M.load()
end

function M.add_or_update(item_name, item_id, qty, scope, opts)
    item_name = trim(item_name)
    item_id = tonumber(item_id) or 0
    opts = type(opts) == "table" and opts or {}
    if item_name == "" and item_id <= 0 then return false, "No item selected." end

    M.load()
    local next_rule = normalize_rule({
        name = item_name,
        id = item_id,
        qty = qty ~= nil and qty or 5,
        scope = scope,
        updated = os.time(),
        group = opts.group,
        resource = opts.resource,
        roles = opts.roles,
        classes = opts.classes,
    })
    if not next_rule then return false, "Could not create Keep Qty rule." end

    local key = rule_key(next_rule)
    for i, rule in ipairs(rules) do
        if rule_key(rule) == key then
            -- Preserve hints unless caller overrides.
            if opts.resource == nil then next_rule.resource = rule.resource end
            if opts.roles == nil then next_rule.roles = rule.roles end
            if opts.classes == nil then next_rule.classes = rule.classes end
            if opts.group == nil then next_rule.group = rule.group end
            if qty == nil then next_rule.qty = rule.qty end
            rules[i] = next_rule
            local ok, err = M.save()
            if not ok then return false, err end
            return true, string.format("Keep Qty: %s x%d.", next_rule.name ~= "" and next_rule.name or ("item " .. next_rule.id), next_rule.qty)
        end
    end

    rules[#rules + 1] = next_rule
    table.sort(rules, function(a, b)
        return norm(a.name ~= "" and a.name or tostring(a.id)) < norm(b.name ~= "" and b.name or tostring(b.id))
    end)
    local ok, err = M.save()
    if not ok then return false, err end
    return true, string.format("Keep Qty: %s x%d.", next_rule.name ~= "" and next_rule.name or ("item " .. next_rule.id), next_rule.qty)
end

function M.remove(index)
    M.load()
    index = tonumber(index)
    if not index or not rules[index] then return false, "No Keep Qty rule selected." end
    local name = rules[index].name
    table.remove(rules, index)
    local ok, err = M.save()
    if not ok then return false, err end
    return true, "Removed " .. tostring(name ~= "" and name or "Keep Qty rule") .. "."
end

function M.set_qty(index, qty)
    M.load()
    index = tonumber(index)
    if not index or not rules[index] then return false, "No Keep Qty rule selected." end
    rules[index].qty = clean_qty(qty)
    rules[index].updated = os.time()
    return M.save()
end

function M.set_scope(index, scope)
    M.load()
    index = tonumber(index)
    if not index or not rules[index] then return false, "No Keep Qty rule selected." end
    rules[index].scope = clean_scope(scope)
    rules[index].updated = os.time()
    return M.save()
end

function M.matches(rule, row)
    if type(row) ~= "table" then return false end
    rule = normalize_rule(rule)
    if not rule then return false end
    if rule.id > 0 and tonumber(row.id) == rule.id then return true end
    return rule.name ~= "" and norm(row.name) == norm(rule.name)
end

--- Aggregate evaluate (Have total + owners). Need uses per-char Want when
--- ownerClass is present on rows; otherwise falls back to aggregate Want.
function M.evaluate(rule, rows)
    rule = normalize_rule(rule)
    if not rule then return nil end
    local total = 0
    local owner_order, owners = {}, {}
    for _, row in ipairs(rows or {}) do
        if M.matches(rule, row) then
            local qty = math.max(1, math.floor(tonumber(row.qty) or 1))
            total = total + qty
            local owner = trim(row.owner)
            if owner == "" then owner = "Unknown" end
            local rec = owners[owner]
            if not rec then
                rec = {
                    owner = owner,
                    qty = 0,
                    locations = {},
                    class = trim(row.ownerClass or ""),
                }
                owners[owner] = rec
                owner_order[#owner_order + 1] = owner
            end
            rec.qty = rec.qty + qty
            if rec.class == "" and row.ownerClass then rec.class = trim(row.ownerClass) end
            local loc = trim(row.location)
            if loc ~= "" and #rec.locations < 4 then rec.locations[#rec.locations + 1] = loc end
        end
    end
    local list = {}
    local need = 0
    for _, owner in ipairs(owner_order) do
        local rec = owners[owner]
        list[#list + 1] = rec
        local want = M.eff_want(rule, rec.class)
        if want > 0 then need = need + math.max(0, want - rec.qty) end
    end
    table.sort(list, function(a, b)
        if a.qty ~= b.qty then return a.qty > b.qty end
        return norm(a.owner) < norm(b.owner)
    end)
    return {
        rule = rule,
        total = total,
        need = need,
        surplus = math.max(0, total - need - (rule.qty or 0)),
        owners = list,
    }
end

--- One-pass owner index for board draws. Call once per cache rebuild, then
--- evaluate_board_from_index per rule (O(roster) instead of O(rows) each).
function M.build_board_index(rows)
    local by_name, by_id = {}, {}
    for _, row in ipairs(rows or {}) do
        if type(row) == "table" then
            local owner = trim(row.owner)
            if owner == "" then owner = "Unknown" end
            local okey = norm(owner)
            local qty = math.max(1, math.floor(tonumber(row.qty) or 1))
            local class = trim(row.ownerClass or "")
            local loc = trim(row.location)
            local function bump(bucket, key)
                if key == nil or key == "" then return end
                local owners = bucket[key]
                if not owners then
                    owners = {}
                    bucket[key] = owners
                end
                local rec = owners[okey]
                if not rec then
                    rec = { owner = owner, have = 0, class = class, locations = {} }
                    owners[okey] = rec
                end
                rec.have = rec.have + qty
                if rec.class == "" and class ~= "" then rec.class = class end
                if loc ~= "" and #rec.locations < 6 then
                    rec.locations[#rec.locations + 1] = string.format("%s x%d", loc, qty)
                end
            end
            local id = tonumber(row.id) or 0
            if id > 0 then bump(by_id, tostring(math.floor(id))) end
            local n = norm(row.name)
            if n ~= "" then bump(by_name, n) end
        end
    end
    return { by_name = by_name, by_id = by_id }
end

function M.evaluate_board_from_index(rule, index, roster)
    rule = normalize_rule(rule)
    if not rule then return nil end
    index = type(index) == "table" and index or {}
    local by_owner = nil
    if rule.id > 0 then
        by_owner = index.by_id and index.by_id[tostring(rule.id)]
    end
    if not by_owner and rule.name ~= "" then
        by_owner = index.by_name and index.by_name[norm(rule.name)]
    end
    by_owner = by_owner or {}

    local cells = {}
    local need = 0
    local have_total = 0
    for _, member in ipairs(roster or {}) do
        local name = trim(member.name or member.owner)
        local key = norm(name)
        local class = trim(member.class or "")
        local owned = by_owner[key]
        if owned and class == "" then class = owned.class end
        local have = owned and owned.have or 0
        local want = M.eff_want(rule, class)
        local short = want > 0 and math.max(0, want - have) or 0
        need = need + short
        have_total = have_total + have
        cells[#cells + 1] = {
            owner = name,
            class = class,
            have = have,
            want = want,
            short = short,
            eligible = want > 0,
            locations = owned and owned.locations or {},
        }
    end

    return {
        rule = rule,
        cells = cells,
        need = need,
        total = have_total,
    }
end

--- Board evaluate: one cell per roster member.
--- roster = { { name=, class= }, ... }
--- Prefer evaluate_board_from_index after build_board_index for UI frames.
function M.evaluate_board(rule, rows, roster)
    return M.evaluate_board_from_index(rule, M.build_board_index(rows), roster)
end

--- Build donor→recipient transfers to even a rule toward Want.
--- cells from evaluate_board*; ineligible toons with stock can donate all.
--- Returns { { from=, to=, qty= }, ... }
function M.plan_even_out(rule, cells)
    rule = normalize_rule(rule)
    if not rule then return {} end
    cells = type(cells) == "table" and cells or {}

    local donors, recipients = {}, {}
    for _, cell in ipairs(cells) do
        local name = trim(cell.owner)
        if name ~= "" then
            local have = math.max(0, math.floor(tonumber(cell.have) or 0))
            local want = math.max(0, math.floor(tonumber(cell.want) or 0))
            local eligible = cell.eligible == true
            if eligible and want > have then
                recipients[#recipients + 1] = {
                    name = name,
                    need = want - have,
                }
            end
            local keep = eligible and want or 0
            local surplus = have - keep
            if surplus > 0 then
                donors[#donors + 1] = {
                    name = name,
                    surplus = surplus,
                }
            end
        end
    end

    table.sort(recipients, function(a, b)
        if a.need ~= b.need then return a.need > b.need end
        return norm(a.name) < norm(b.name)
    end)
    table.sort(donors, function(a, b)
        if a.surplus ~= b.surplus then return a.surplus > b.surplus end
        return norm(a.name) < norm(b.name)
    end)

    local transfers = {}
    local di = 1
    for _, rec in ipairs(recipients) do
        local need = rec.need
        while need > 0 and di <= #donors do
            local donor = donors[di]
            if norm(donor.name) == norm(rec.name) then
                di = di + 1
            elseif donor.surplus <= 0 then
                di = di + 1
            else
                local move = math.min(need, donor.surplus)
                if move > 0 then
                    transfers[#transfers + 1] = {
                        from = donor.name,
                        to = rec.name,
                        qty = move,
                        item = rule.name,
                        id = rule.id,
                    }
                    donor.surplus = donor.surplus - move
                    need = need - move
                end
                if donor.surplus <= 0 then di = di + 1 end
            end
        end
    end
    return transfers
end

--- Pull every copy of this rule to collector (AdventureTime Collect-all).
--- Other toons with have > 0 send their full stack; collector is skipped.
function M.plan_collect(rule, cells, collector)
    rule = normalize_rule(rule)
    if not rule then return {} end
    collector = trim(collector)
    if collector == "" then return {} end
    local ckey = norm(collector)
    local transfers = {}
    for _, cell in ipairs(cells or {}) do
        local name = trim(cell.owner)
        local have = math.max(0, math.floor(tonumber(cell.have) or 0))
        if name ~= "" and norm(name) ~= ckey and have > 0 then
            transfers[#transfers + 1] = {
                from = name,
                to = collector,
                qty = have,
                item = rule.name,
                id = rule.id,
            }
        end
    end
    table.sort(transfers, function(a, b)
        if a.qty ~= b.qty then return a.qty > b.qty end
        return norm(a.from) < norm(b.from)
    end)
    return transfers
end

--- Seed AdventureTime draughts + Orb + Emerald (idempotent). Prefer calling
--- once via ensure_defaults_seeded rather than a UI Adventure button.
function M.ensure_adventure_preset(default_qty, scope)
    default_qty = clean_qty(default_qty)
    if default_qty <= 0 then default_qty = 5 end
    scope = clean_scope(scope or "group")
    local added = 0
    M.load()
    local function ensure(name, opts)
        local key = "name:" .. norm(name)
        for _, rule in ipairs(rules) do
            if rule_key(rule) == key then
                rule.resource = opts.resource or rule.resource
                rule.group = opts.group or rule.group
                return false
            end
        end
        local ok = select(1, M.add_or_update(name, 0, default_qty, scope, opts))
        if ok then added = added + 1 end
        return ok
    end

    for _, base in ipairs(ADVENTURE_DRAUGHTS) do
        local resource = nil
        if base:find("Frenzied Endurance", 1, true) then resource = "endurance" end
        if base:find("Clear Mind", 1, true) then resource = "mana" end
        ensure(base .. " I", { group = "Draughts I", resource = resource })
        ensure(base .. " II", { group = "Draughts II", resource = resource })
    end
    ensure("Orb of Shadows", { group = "Orbs" })
    ensure("Emerald", { group = "Vendor" })
    rules = dedupe_rules(rules)
    sort_rules()
    M.save()
    return true, added
end

--- One-shot: if the keepqty file is missing/empty, seed the Adventure pack.
function M.ensure_defaults_seeded()
    M.load()
    if #rules > 0 then return false, 0 end
    return M.ensure_adventure_preset(5, "group")
end

return M
