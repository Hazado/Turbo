--[[
  Turbo Actions -- Run-as pill (manual panel, not OpenPopup).
  @version lua/Turbo/ui/run_as_pill.lua 1

  Replaces the multi-row Run-as block on the Actions tab. Open-state lives in
  _G so a module reload cannot silently close the panel. Selectable rows that
  can appear selected=true are guarded (MQ returns true every frame for those).
]]

local ImGui = require('ImGui')
local Theme = require('Turbo.theme')
local Ui = require('Turbo.ui.components')

local M = {}
M.VERSION = 1

local function panel_is_open()
    return rawget(_G, '__TurboRunAsPillOpen') == true
end

local function set_panel_open(v)
    rawset(_G, '__TurboRunAsPillOpen', v == true)
end

local close_requested = false
local function request_close()
    close_requested = true
end

local function save_name_get()
    return tostring(rawget(_G, '__TurboRunAsSaveName') or '')
end

local function save_name_set(v)
    rawset(_G, '__TurboRunAsSaveName', tostring(v or ''))
end

local function checkbox_value(label, checked)
    if not ImGui.Checkbox then return checked, false end
    local rv1, rv2 = ImGui.Checkbox(label, checked and true or false)
    if type(rv2) == 'boolean' then return rv1 and true or false, rv2 end
    if type(rv1) == 'boolean' and rv1 ~= checked then return rv1, true end
    return checked, false
end

local function dim_text(msg)
    ImGui.TextColored(0.55, 0.58, 0.65, 1.0, tostring(msg or ''))
end

local function section_label(msg)
    ImGui.TextColored(0.62, 0.68, 0.78, 1.0, tostring(msg or ''))
end

local function mode_display(mode)
    if mode == 'multi' then return 'Picks' end
    if mode == 'group' then return 'Group' end
    if mode == 'all' then return 'All' end
    return 'Self'
end

local function pill_variant(mode)
    if mode == 'multi' then return 'primaryButton' end
    if mode == 'group' then return 'amberButton' end
    if mode == 'all' then return 'dangerButton' end
    return 'secondaryButton'
end

local function sorted_names(list)
    local out = {}
    for _, name in ipairs(type(list) == 'table' and list or {}) do
        if name and tostring(name) ~= '' then out[#out + 1] = tostring(name) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

local function picked_names(api)
    local targets = type(api.get_pick_map) == 'function' and api.get_pick_map() or {}
    local bots = type(api.bot_targets) == 'table' and api.bot_targets or {}
    local out, seen = {}, {}
    for _, name in ipairs(bots) do
        if targets[name] then
            out[#out + 1] = name
            seen[name:lower()] = true
        end
    end
    for name, on in pairs(targets) do
        if on and type(name) == 'string' and name ~= '' and not seen[name:lower()] then
            out[#out + 1] = name
        end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

local function resolved_targets(api)
    local mode = tostring(api.run_mode or 'self')
    if mode == 'self' then
        return { tostring(api.me_name or 'Self') }
    end
    if mode == 'multi' then
        return picked_names(api)
    end
    if mode == 'group' then
        return sorted_names(api.bot_targets)
    end
    -- all: known members when available, else bots + self
    local members = type(api.members) == 'table' and api.members or nil
    if members and #members > 0 then
        return sorted_names(members)
    end
    local bots = sorted_names(api.bot_targets)
    local me = tostring(api.me_name or '')
    if me ~= '' then
        local found = false
        for _, n in ipairs(bots) do if n:lower() == me:lower() then found = true break end end
        if not found then table.insert(bots, 1, me) end
    end
    return bots
end

local function pill_label(api)
    local mode = tostring(api.run_mode or 'self')
    local me = tostring(api.me_name or 'Self')
    if mode == 'self' then
        return string.format('Run as: Self (%s)', me)
    end
    if mode == 'multi' then
        local n = #picked_names(api)
        if n <= 0 then return 'Run as: Picks (0!)' end
        return string.format('Run as: Picks (%d)', n)
    end
    if mode == 'group' then
        return string.format('Run as: Group (%d)', #(api.bot_targets or {}))
    end
    local targets = resolved_targets(api)
    return string.format('Run as: All (%d)', #targets)
end

local function tooltip_targets(api)
    local mode = tostring(api.run_mode or 'self')
    local names = resolved_targets(api)
    if mode == 'all' and #names == 0 then
        return 'Targets: all E3 bots in zone (roster empty).'
    end
    if #names == 0 then
        return 'Targets: (none) -- pick one or more characters first.'
    end
    return 'Targets: ' .. table.concat(names, ', ')
end

local function ensure_saved_list(api)
    local list = type(api.get_saved_picks) == 'function' and api.get_saved_picks() or nil
    if type(list) ~= 'table' then
        list = {}
        if type(api.set_saved_picks) == 'function' then api.set_saved_picks(list) end
    end
    return list
end

local function persist(api)
    if type(api.save_settings) == 'function' then api.save_settings() end
end

local function apply_mode(api, mode)
    mode = tostring(mode or 'self')
    if mode ~= 'self' and api.can_shared_write == false then
        if type(api.on_locked) == 'function' then
            api.on_locked(mode_display(mode))
        end
        return false
    end
    if type(api.set_run_mode) == 'function' then
        api.set_run_mode(mode)
    end
    return true
end

local function draw_mode_section(api)
    section_label('MODE')
    local mode = tostring(api.run_mode or 'self')
    local rows = {
        { key = 'self', label = 'Self' },
        { key = 'multi', label = 'Picks' },
        { key = 'group', label = 'Group' },
        { key = 'all', label = 'All' },
    }
    for _, row in ipairs(rows) do
        local selected = mode == row.key
        local locked = row.key ~= 'self' and api.can_shared_write == false
        if locked then ImGui.BeginDisabled() end
        if ImGui.Selectable(row.label .. '##runas_mode_' .. row.key, selected) then
            -- Guard: selected=true returns true every frame on MQ ImGui.
            if not selected then
                if apply_mode(api, row.key) then
                    request_close()
                end
            end
        end
        if locked then ImGui.EndDisabled() end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() then
            local tip = row.key == 'self' and 'This character only.'
                or row.key == 'multi' and 'Picked targets only.'
                or row.key == 'group' and 'Current group bots.'
                or 'All E3 bots in zone.'
            if locked then tip = 'Take Turbo control to use ' .. row.label .. ' scope.' end
            if ImGui.SetTooltip then ImGui.SetTooltip(tip) end
        end
    end
end

local function draw_targets_section(api)
    if ImGui.Separator then ImGui.Separator() end
    section_label('TARGETS')
    local mode = tostring(api.run_mode or 'self')
    local bots = type(api.bot_targets) == 'table' and api.bot_targets or {}

    if mode == 'multi' then
        if #bots == 0 then
            dim_text('No bots found.')
            return
        end
        local picks = type(api.get_pick_map) == 'function' and api.get_pick_map() or {}
        for _, name in ipairs(bots) do
            local cur = picks[name] == true
            local new_v, changed = checkbox_value(tostring(name) .. '##runas_pick_' .. name, cur)
            if changed and new_v ~= cur and type(api.set_pick) == 'function' then
                api.set_pick(name, new_v and true or false)
                -- Stay in Picks while editing; do not close the panel.
                if type(api.set_run_mode) == 'function' and tostring(api.run_mode or '') ~= 'multi' then
                    apply_mode(api, 'multi')
                end
            end
        end
        return
    end

    -- Self / Group / All: resolved list, read-only.
    local names = resolved_targets(api)
    if #names == 0 then
        dim_text(mode == 'all' and 'All E3 bots in zone.' or 'No targets.')
        return
    end
    for _, name in ipairs(names) do
        dim_text(name)
    end
end

local function draw_saved_section(api)
    if ImGui.Separator then ImGui.Separator() end
    section_label('SAVED PICKS')

    local picks = picked_names(api)
    ImGui.SetNextItemWidth(160.0)
    local buf = save_name_get()
    if ImGui.InputTextWithHint then
        buf = ImGui.InputTextWithHint('##runas_save_name', 'Name this pick set...', buf)
    else
        buf = ImGui.InputText('##runas_save_name', buf)
    end
    save_name_set(buf)
    ImGui.SameLine()
    local can_save = #picks > 0 and tostring(buf):match('%S') ~= nil
    if not can_save then ImGui.BeginDisabled() end
    if Ui.buttonVariant('Save##runas_save_btn', 'primaryButton', 56, 22) then
        local name = tostring(buf):match('^%s*(.-)%s*$') or ''
        if name ~= '' and type(api.save_pick_set) == 'function' then
            if api.save_pick_set(name, picks) then
                save_name_set('')
                persist(api)
            end
        end
    end
    if not can_save then ImGui.EndDisabled() end
    if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
        ImGui.SetTooltip(#picks > 0
            and 'Store the current pick set under this name.'
            or 'Select one or more Picks targets first.')
    end

    local saved = ensure_saved_list(api)
    if #saved == 0 then
        dim_text('No saved pick sets yet.')
        return
    end

    for i, rec in ipairs(saved) do
        local set_name = tostring(rec.name or '')
        local members = type(rec.members) == 'table' and rec.members or {}
        local row_label = string.format('%s (%d)##runas_saved_%d', set_name, #members, i)
        -- Never draw selected=true: applying is a one-shot click, and MQ fires
        -- Selectable every frame when selected.
        if ImGui.Selectable(row_label, false) then
            if type(api.apply_pick_set) == 'function' then
                if api.apply_pick_set(members) then
                    request_close()
                end
            end
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Load as Picks: ' .. table.concat(members, ', '))
        end
        ImGui.SameLine()
        if Ui.buttonVariant('x##runas_del_' .. i, 'secondaryButton', 22, 22) then
            if type(api.delete_pick_set) == 'function' then
                api.delete_pick_set(i)
                persist(api)
            end
        end
        if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
            ImGui.SetTooltip('Delete saved pick set.')
        end
    end
end

local function draw_panel_body(api)
    draw_mode_section(api)
    draw_targets_section(api)
    draw_saved_section(api)
    dim_text('Mode pick closes this menu. Checkbox changes stay open.')
end

--- Draw the Run-as pill + manual dropdown panel.
-- @param opts table|nil  { width=, height= }
-- @param api table       me_name, run_mode, set_run_mode, bot_targets, members,
--   get_pick_map, set_pick, get_saved_picks, set_saved_picks, save_pick_set,
--   apply_pick_set, delete_pick_set, save_settings, can_shared_write, on_locked
function M.draw(opts, api)
    opts = type(opts) == 'table' and opts or {}
    api = type(api) == 'table' and api or {}

    local mode = tostring(api.run_mode or 'self')
    local picks_empty = mode == 'multi' and #picked_names(api) == 0
    local label = pill_label(api) .. '##turbo_runas_pill'
    local variant = pill_variant(mode)

    local width = tonumber(opts.width) or 0
    if width <= 0 and ImGui.CalcTextSize then
        local ok, w = pcall(ImGui.CalcTextSize, pill_label(api))
        if ok then
            if type(w) == 'table' then width = (tonumber(w.x or w[1]) or 180) + 24 end
            if type(w) == 'number' then width = w + 24 end
        end
    end
    if width <= 0 then width = 220 end
    local avail = 0
    if ImGui.GetContentRegionAvail then
        avail = select(1, ImGui.GetContentRegionAvail()) or 0
    end
    if avail > 0 and width > avail then width = avail end

    local height = tonumber(opts.height) or 24
    -- Picks(0!): keep blue scope color; stack amber Text on top of the
    -- palette so the (0!) warning reads without losing the Picks blue.
    local palette = Theme.component[variant] or Theme.component.secondaryButton
    local pushed = Ui.pushButtonPalette(palette)
    if picks_empty then
        local amber = Theme.component.amberButton and Theme.component.amberButton.text
        if amber then
            ImGui.PushStyleColor(ImGuiCol.Text, IM_COL32(amber[1], amber[2], amber[3], amber[4] or 255))
            pushed = pushed + 1
        end
    end
    local clicked = ImGui.Button(label, width, height)
    Ui.popButtonPalette(pushed)
    if clicked then
        set_panel_open(not panel_is_open())
    end
    local pill_hovered = ImGui.IsItemHovered and ImGui.IsItemHovered() or false
    local bx, by2 = nil, nil
    if ImGui.GetItemRectMin and ImGui.GetItemRectMax then
        pcall(function()
            local x1 = select(1, ImGui.GetItemRectMin())
            local _, y2 = ImGui.GetItemRectMax()
            bx, by2 = tonumber(x1), tonumber(y2)
        end)
    end
    if pill_hovered and ImGui.SetTooltip then
        ImGui.SetTooltip(tooltip_targets(api))
    end

    if close_requested then
        close_requested = false
        set_panel_open(false)
    end

    if not panel_is_open() or not ImGui.Begin then return true end
    if ImGui.SetNextWindowPos and bx and by2 then
        pcall(ImGui.SetNextWindowPos, bx, by2 + 2)
    end
    local flags = 0
    if ImGuiWindowFlags then
        flags = (ImGuiWindowFlags.NoTitleBar or 0)
            + (ImGuiWindowFlags.NoResize or 0)
            + (ImGuiWindowFlags.AlwaysAutoResize or 0)
            + (ImGuiWindowFlags.NoSavedSettings or 0)
            + (ImGuiWindowFlags.NoCollapse or 0)
    end
    local a, b = ImGui.Begin('TurboRunAsPill##panel', true, flags)
    local should_draw = (b == nil) and a or b
    local panel_hovered = false
    if should_draw then
        if ImGui.IsWindowHovered then
            local hf = 0
            if ImGuiHoveredFlags then
                hf = (ImGuiHoveredFlags.RootAndChildWindows or 0)
                    + (ImGuiHoveredFlags.AllowWhenBlockedByActiveItem or 0)
            end
            panel_hovered = ImGui.IsWindowHovered(hf) or false
        end
        draw_panel_body(api)
    end
    ImGui.End()

    if ImGui.IsMouseClicked and (ImGui.IsMouseClicked(0) or ImGui.IsMouseClicked(1)) then
        if not panel_hovered and not pill_hovered then
            set_panel_open(false)
        end
    end
    if close_requested then
        close_requested = false
        set_panel_open(false)
    end
    return true
end

return M
