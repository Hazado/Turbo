-- Run from repo root:  luajit lua\tests\turbogear_don_spells_test.lua
-- DoN pack/single ownership: pack OR (each scroll held / ability known).

package.path = "lua/turbogear/?.lua;lua/turbogear/?/init.lua;" .. package.path

package.preload["mq"] = function()
    return {
        configDir = ".",
        TLO = {
            Me = { CleanName = function() return "Tester" end },
            MacroQuest = { Server = function() return "Srv" end },
            FindItem = function() return nil end,
        },
    }
end
package.preload["config"] = function()
    return {
        CFG = { script_name = "TurboGear" },
        Settings = {},
        SharedSettings = {},
        SaveSettings = function() end,
        SaveSharedSettings = function() end,
    }
end

local bis = require("bis")
local DS = require("don_spells")

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write("FAIL: ", tostring(label), "\n")
    end
end

local function snap_with(bags, spells, spell_ids)
    return {
        name = "Tester",
        server = "Srv",
        class = "Cleric",
        bags = bags or {},
        equipped = {},
        bank = {},
        spells = spells or {},
        spell_ids = spell_ids or {},
        inventoryUpdated = tostring(os.clock()),
    }
end

-- Allegiance pack: three scrolls; one scroll alone must NOT clear.
local allegiance = {
    item = "Spell Pack: Allegiance",
    ids = { 82658 },
    names = { "Spell Pack: Allegiance" },
    spells = { "Allegiance" }, -- intentional incomplete LazBiS-style metadata
}

local one_scroll = snap_with({ { id = 78067, name = "Spell: Allegiance" } })
local r1 = bis.evaluate_entry(allegiance, one_scroll, { skip_live = true })
check(r1.have ~= true, "Allegiance: one scroll does not clear pack")

local pack_held = snap_with({ { id = 82658, name = "Spell Pack: Allegiance" } })
local r2 = bis.evaluate_entry(allegiance, pack_held, { skip_live = true })
check(r2.have == true and r2.status == "carried", "Allegiance: pack held clears")

local all_scrolls = snap_with({
    { id = 78067, name = "Spell: Allegiance" },
    { id = 78146, name = "Spell: Hand of Allegiance" },
    { id = 78046, name = "Spell: Symbol of Elushar" },
})
local r3 = bis.evaluate_entry(allegiance, all_scrolls, { skip_live = true })
check(r3.have == true, "Allegiance: all three scrolls clear")

local all_known = snap_with({}, {
    ["allegiance"] = { name = "Allegiance", book = 1 },
    ["hand of allegiance"] = { name = "Hand of Allegiance", book = 1 },
    ["symbol of elushar"] = { name = "Symbol of Elushar", book = 1 },
}, { [9730] = true, [9809] = true, [9709] = true })
local r4 = bis.evaluate_entry(allegiance, all_known, { skip_live = true })
check(r4.have == true and r4.status == "known", "Allegiance: all abilities known clears")

-- WAR Malicious: scroll id clears even when LazBiS only lists pack id
local malicious = {
    item = "Tome Pack: Ancient: Malicious Onslaught",
    ids = { 82654 },
    names = { "Tome Pack: Ancient: Malicious Onslaught" },
    spells = { "Malicious Onslaught Discipline" }, -- old wrong/partial name
}
local scroll_only = snap_with({
    { id = 78424, name = "Tome of Ancient: Malicious Onslaught" },
})
local r5 = bis.evaluate_entry(malicious, scroll_only, { skip_live = true })
check(r5.have == true, "Malicious: opened pack scroll clears via catalog")

local known_ability = snap_with({}, {
    ["ancient: malicious onslaught"] = { name = "Ancient: Malicious Onslaught", book = 1 },
}, { [10849] = true })
local r6 = bis.evaluate_entry(malicious, known_ability, { skip_live = true })
check(r6.have == true and r6.status == "known", "Malicious: catalog ability/spell_id known clears")

-- Single vendor tome
local field = {
    item = "Tome of Field Conqueror",
    ids = { 88919 },
    names = { "Tome of Field Conqueror" },
    spell_ids = { 25036 },
    spells = { "Field Conqueror" },
}
local r7 = bis.evaluate_entry(field, snap_with({}), { skip_live = true })
check(r7.have ~= true, "Field Conqueror: missing when empty")
local r8 = bis.evaluate_entry(field, snap_with({}, {}, { [25036] = true }), { skip_live = true })
check(r8.have == true, "Field Conqueror: spell_id known clears")

-- Partial Sha's pack (2 abilities)
local shas = {
    item = "Spell Pack: Sha's Urgent Renewal",
    ids = { 82820 },
    names = { "Spell Pack: Sha's Urgent Renewal" },
    spells = { "Sha's Urgent Renewal" },
}
local half = snap_with({
    { id = 115093, name = "Spell: Sha's Urgent Renewal" },
})
local r9 = bis.evaluate_entry(shas, half, { skip_live = true })
check(r9.have ~= true, "Sha's: one of two scrolls does not clear")

local both = snap_with({
    { id = 115093, name = "Spell: Sha's Urgent Renewal" },
    { id = 115099, name = "Spell: Feral Exigency" },
})
local r10 = bis.evaluate_entry(shas, both, { skip_live = true })
check(r10.have == true, "Sha's: both scrolls clear")

-- Non-catalog gear falls through (not handled as missing by don_spells)
local gear = { item = "Some Random Sword", ids = { 999999 }, names = { "Some Random Sword" } }
local handled = select(1, DS.try_match(gear, snap_with({})))
check(handled == false, "non-catalog entry is not claimed by don_spells")

print(string.format("don_spells: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
