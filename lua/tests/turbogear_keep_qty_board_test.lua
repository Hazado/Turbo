-- Unit tests for keep_qty board evaluate + class hints (no MQ).
package.path = table.concat({
    "lua/?.lua",
    "lua/?/init.lua",
    "lua/turbogear/?.lua",
    package.path,
}, ";")

-- Stub mq before requiring keep_qty.
package.loaded.mq = {
    configDir = ".",
    pickle = function() end,
}
package.loaded.config = {
    CFG = { script_name = "TurboGear_test" },
}

local keep_qty = require("keep_qty")

local fails = 0
local function check(cond, msg)
    if not cond then
        fails = fails + 1
        print("FAIL: " .. tostring(msg))
    end
end

-- Clear any accidental load from disk.
keep_qty.load(true)

local rule = {
    name = "Draught of the Clear Mind I",
    qty = 5,
    scope = "group",
    resource = "mana",
}

check(keep_qty.eff_want(rule, "CLR") == 5, "CLR wants Clear Mind")
check(keep_qty.eff_want(rule, "WAR") == 0, "WAR does not want Clear Mind")
check(keep_qty.eff_want(rule, "SHD") == 0, "SHD does not want Clear Mind")

local endu = {
    name = "Draught of Frenzied Endurance I",
    qty = 3,
    resource = "endurance",
}
check(keep_qty.eff_want(endu, "SHD") == 3, "SHD wants endurance")
check(keep_qty.eff_want(endu, "WIZ") == 0, "WIZ does not want endurance")

local roster = {
    { name = "Drel", class = "SHD" },
    { name = "Clrr", class = "CLR" },
    { name = "Disco", class = "BRS" },
}
local rows = {
    { name = "Draught of the Clear Mind I", owner = "Drel", ownerClass = "SHD", qty = 10, location = "Bags" },
    { name = "Draught of the Clear Mind I", owner = "Clrr", ownerClass = "CLR", qty = 2, location = "Bags" },
}
local board = keep_qty.evaluate_board(rule, rows, roster)
check(board ~= nil, "board result")
check(board.need == 3, "CLR short 3 (want 5 have 2); SHD/BRS want 0")
check(board.cells[1].have == 10 and board.cells[1].eligible == false, "Drel grey/ineligible")
check(board.cells[2].have == 2 and board.cells[2].short == 3, "Clrr short")
check(board.cells[3].have == 0 and board.cells[3].eligible == false, "Disco ineligible")

local idx = keep_qty.build_board_index(rows)
local board2 = keep_qty.evaluate_board_from_index(rule, idx, roster)
check(board2 and board2.need == board.need, "indexed board matches scan board")

local even_cells = {
    { owner = "Drel", have = 10, want = 5, eligible = true },
    { owner = "Clrr", have = 1, want = 5, eligible = true },
    { owner = "Disco", have = 0, want = 0, eligible = false },
}
local plan = keep_qty.plan_even_out(rule, even_cells)
check(#plan == 1 and plan[1].from == "Drel" and plan[1].to == "Clrr" and plan[1].qty == 4,
    "even-out plans Drel surplus to Clrr")

local collect_cells = {
    { owner = "Drel", have = 10, want = 5, eligible = true },
    { owner = "Clrr", have = 2, want = 5, eligible = true },
    { owner = "Disco", have = 3, want = 0, eligible = false },
}
local cplan = keep_qty.plan_collect(rule, collect_cells, "Drel")
check(#cplan == 2, "collect has two donors")
check(cplan[1].to == "Drel" and cplan[2].to == "Drel", "collect targets Drel")
local cqty = (cplan[1].qty or 0) + (cplan[2].qty or 0)
check(cqty == 5, "collect pulls Clrr 2 + Disco 3")

check(keep_qty.display_name("Draught of Fleeting Fortitude I") == "Fleeting Fortitude I", "display_name keeps tier I")
check(keep_qty.display_name("Draught of Fleeting Fortitude II") == "Fleeting Fortitude II", "display_name keeps tier II")
check(keep_qty.hint_label({ resource = "mana" }) == "mana classes", "hint_label mana")

if fails > 0 then
    print(string.format("turbogear_keep_qty_board_test: %d failure(s)", fails))
    os.exit(1)
end
print("turbogear_keep_qty_board_test: ok")
