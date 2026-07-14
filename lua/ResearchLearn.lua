--[[
  ResearchLearn.lua - lightweight ImGui front-end for researchlearn.mac

  Run:
    /lua run ResearchLearn          (open UI)
    /lua run ResearchLearn toggle   (show/hide)
    /lua run ResearchLearn doctor   (preflight, no UI)

  Bind (while script runs):
    /rlui show|hide|toggle|doctor|stop

  Requires researchlearn.mac + researchlearn.ini in Macros/Config.
  Optional: lazbis/spells.lua for acquisition tags (research vs drop).

  Import: ResearchLearnExport.lua (self-contained) -> config/ResearchLearn_want_<char>.txt
  Skill-up: researchskill.mac in Macros (Pack10 container). Legacy: binding/refined/intricate redirect.
]]

local mq = require('mq')
local ImGui = require('ImGui')
local okShell, ShellOpen = pcall(require, 'Turbo.shell_open')
if not okShell then ShellOpen = nil end

local INI_NAME = 'researchlearn.ini'
local MACRO_NAME = 'researchlearn'
local scriptName = 'ResearchLearn'
local IMPORT_FORMAT = 'ResearchLearn want-list v1'

local SKILL_MACRO = 'researchskill'
local RESEARCH_SKILL_CAP = 300

local SKILL_TIERS = {
    {
        id = 'binding',
        label = 'Binding parchment',
        macro = SKILL_MACRO,
        trivial = 232,
        container = 'Pack10',
        items = {
            'Binding Powder',
            'Binding Solution',
            'Piece of Parchment',
            "Spellcaster's Empowering Essence",
        },
    },
    {
        id = 'refined',
        label = 'Refined parchment',
        macro = SKILL_MACRO,
        trivial = 272,
        container = 'Pack10',
        items = {
            'Refined Binding Powder',
            'Refined Binding Solution',
            'Piece of Parchment',
            "Refined Spellcaster's Empowering Essence",
        },
    },
    {
        id = 'intricate',
        label = 'Intricate parchment',
        macro = SKILL_MACRO,
        trivial = 312,
        container = 'Pack10',
        items = {
            'Intricate Binding Powder',
            'Intricate Binding Solution',
            'Piece of Parchment',
            "Intricate Spellcaster's Empowering Essence",
        },
    },
    {
        id = 'elaborate',
        label = 'Elaborate parchment',
        macro = SKILL_MACRO,
        trivial = 352,
        container = 'Pack10',
        items = {
            'Elaborate Binding Powder',
            'Elaborate Binding Solution',
            'Piece of Parchment',
            "Elaborate Spellcaster's Empowering Essence",
        },
    },
    {
        id = 'ornate',
        label = 'Ornate parchment',
        macro = SKILL_MACRO,
        trivial = 392,
        container = 'Pack10',
        items = {
            'Ornate Binding Powder',
            'Ornate Binding Solution',
            'Piece of Parchment',
            "Ornate Spellcaster's Empowering Essence",
        },
    },
}

local DEFAULT_CLASSES = {
    'cleric', 'beastlord', 'magician', 'bard', 'druid', 'enchanter',
    'necromancer', 'ranger', 'shadowknight', 'shaman', 'wizard', 'paladin',
}

local LEVELS = { '66', '67', '68', '69', '70', 'all' }
local LEVEL_NUMS = { 70, 69, 68, 67, 66 }

local SORT_MANIFEST = { LVL = 1, SPELL = 2, SOURCE = 3, HAVE = 4, INI = 5 }
local SORT_ING = { ITEM = 1, NEED = 2, HAVE = 3, SHORT = 4 }

local CLASS_NORMALIZE = {
    brd = 'bard', bst = 'beastlord', ber = 'berserker', clr = 'cleric',
    dru = 'druid', enc = 'enchanter', mag = 'magician', mnk = 'monk',
    nec = 'necromancer', pal = 'paladin', rng = 'ranger', rog = 'rogue',
    shd = 'shadowknight', shm = 'shaman', wiz = 'wizard', war = 'warrior',
    bard = 'bard', beastlord = 'beastlord', berserker = 'berserker', cleric = 'cleric',
    druid = 'druid', enchanter = 'enchanter', magician = 'magician', monk = 'monk',
    necromancer = 'necromancer', paladin = 'paladin', ranger = 'ranger', rogue = 'rogue',
    shadowknight = 'shadowknight', shaman = 'shaman', wizard = 'wizard', warrior = 'warrior',
}

local CLASS_TO_LAZ = {
    cleric = 'Cleric',
    beastlord = 'Beastlord',
    magician = 'Magician',
    bard = 'Bard',
    druid = 'Druid',
    enchanter = 'Enchanter',
    necromancer = 'Necromancer',
    ranger = 'Ranger',
    shadowknight = 'Shadow Knight',
    shaman = 'Shaman',
    wizard = 'Wizard',
    paladin = 'Paladin',
    berserker = 'Berserker',
    monk = 'Monk',
    rogue = 'Rogue',
    warrior = 'Warrior',
}

local UI = {
    round = 8,
    btn_w = 92,
    btn_h = 26,
    green = { 0.28, 0.62, 0.42, 1.0 },
    blue  = { 0.22, 0.42, 0.68, 1.0 },
    red   = { 0.62, 0.28, 0.28, 1.0 },
    steel = { 0.18, 0.22, 0.30, 1.0 },
    amber = { 0.85, 0.65, 0.20, 1.0 },
}

local state = {
    windowOpen = true,
    sizeSet = false,
    classes = DEFAULT_CLASSES,
    classIndex = 0,
    levelIndex = 5,
    quantity = 1,
    runMode = 'class',
    spellName = '',
    importPath = '',
    importEntries = nil,
    importRunning = false,
    importQueue = {},
    importBatchLaunched = false,
    importIndex = 0,
    importMeta = {},
    importFiles = {},
    importListIndex = 0,
    importScanAt = 0,
    skillTierIndex = 0,
    researchOnly = true,
    hideOwned = false,
    kitPack = 10,
    statusMsg = '',
    statusAt = 0,
    planKey = '',
    plan = nil,
    iniPath = nil,
    iniSections = nil,
    spellsConfig = nil,
    spellsLoaded = false,
    lastCountRefresh = 0,
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function trim(s)
    return (tostring(s or ''):gsub('^%s*(.-)%s*$', '%1'))
end

local function normalize_class(className)
    local key = trim(className):lower()
    return CLASS_NORMALIZE[key] or key
end

local function normalize_name(name)
    return trim(name):lower():gsub('^spell:%s*', '')
end

local function scroll_label(name)
    name = trim(name)
    if name:lower():find('^spell:') then return name end
    return 'Spell: ' .. name
end

local function file_exists(path)
    local fh = io.open(path, 'r')
    if fh then fh:close(); return true end
    return false
end

local function begin_window_flags()
    if ImGuiWindowFlags then
        return ImGuiWindowFlags.None or 0
    end
    return 0
end

local function table_flags(...)
    if bit32 and bit32.bor then return bit32.bor(...) end
    local n = 0
    for i = 1, select('#', ...) do
        n = n + (select(i, ...) or 0)
    end
    return n
end

local function sortable_table_flags()
    return table_flags(
        ImGuiTableFlags.Borders,
        ImGuiTableFlags.RowBg,
        ImGuiTableFlags.Resizable,
        ImGuiTableFlags.ScrollY,
        ImGuiTableFlags.Sortable,
        ImGuiTableFlags.SizingStretchProp
    )
end

local function sort_is_ascending(spec)
    if ImGuiSortDirection and spec.SortDirection == ImGuiSortDirection.Ascending then
        return true
    end
    return tonumber(spec.SortDirection) == 1
end

local function apply_table_sort(list, sortSpecs, compare_for_uid)
    if not sortSpecs or not list or #list < 2 then return end
    local specCount = tonumber(sortSpecs.SpecsCount) or 0
    if specCount <= 0 then return end

    table.sort(list, function(a, b)
        for n = 1, specCount do
            local spec = sortSpecs.Specs and sortSpecs:Specs(n)
            if not spec then break end
            local uid = spec.ColumnUserID or spec.ColumnIndex or 0
            local cmp = compare_for_uid(uid, a, b)
            if cmp ~= 0 then
                if sort_is_ascending(spec) then return cmp < 0 end
                return cmp > 0
            end
        end
        return (a.name or '') < (b.name or '')
    end)

    if sortSpecs.SpecsDirty ~= nil then sortSpecs.SpecsDirty = false end
end

local function push_ui_style()
    local vars, cols = 0, 0
    local function pv(v, ...)
        if v ~= nil and pcall(ImGui.PushStyleVar, v, ...) then vars = vars + 1 end
    end
    local function pc(c, r, g, b, a)
        if c ~= nil and pcall(ImGui.PushStyleColor, c, r, g, b, a) then cols = cols + 1 end
    end
    pv(ImGuiStyleVar.WindowRounding, UI.round)
    pv(ImGuiStyleVar.FrameRounding, UI.round)
    pv(ImGuiStyleVar.GrabRounding, UI.round)
    pv(ImGuiStyleVar.PopupRounding, UI.round)
    pv(ImGuiStyleVar.FramePadding, 8, 5)
    pc(ImGuiCol.WindowBg, 0.07, 0.08, 0.11, 0.96)
    pc(ImGuiCol.FrameBg, 0.12, 0.14, 0.18, 1.0)
    pc(ImGuiCol.FrameBgHovered, 0.18, 0.20, 0.26, 1.0)
    pc(ImGuiCol.FrameBgActive, 0.22, 0.24, 0.30, 1.0)
    pc(ImGuiCol.Button, UI.steel[1], UI.steel[2], UI.steel[3], 1.0)
    pc(ImGuiCol.ButtonHovered, 0.28, 0.32, 0.40, 1.0)
    pc(ImGuiCol.ButtonActive, 0.14, 0.16, 0.22, 1.0)
    return vars, cols
end

local function pop_ui_style(vars, cols)
    if cols and cols > 0 and ImGui.PopStyleColor then pcall(ImGui.PopStyleColor, cols) end
    if vars and vars > 0 and ImGui.PopStyleVar then pcall(ImGui.PopStyleVar, vars) end
end

local function themed_button(label, color, w, h, disabled)
    local pushed = 0
    if disabled and ImGui.BeginDisabled then
        ImGui.BeginDisabled(true)
        pushed = 1
    end
    local c = color or UI.steel
    local alpha = disabled and 0.45 or 1.0
    ImGui.PushStyleColor(ImGuiCol.Button, c[1] * 0.90, c[2] * 0.90, c[3] * 0.90, alpha)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, math.min(c[1] * 1.15, 1), math.min(c[2] * 1.15, 1), math.min(c[3] * 1.15, 1), alpha)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, c[1] * 0.72, c[2] * 0.72, c[3] * 0.72, alpha)
    local clicked = ImGui.Button(label, w or UI.btn_w, h or UI.btn_h)
    ImGui.PopStyleColor(3)
    if pushed > 0 and ImGui.EndDisabled then ImGui.EndDisabled() end
    return clicked and not disabled
end

local function set_status(msg)
    state.statusMsg = msg
    state.statusAt = mq.gettime()
    printf('\ag[ResearchLearn]\ax %s', msg)
end

local function resolve_spell_id(name)
    name = trim(name):gsub("^Spell:%s*", ""):gsub("^Tome of%s+", "")
    if name == '' or not mq.TLO.Spell then return 0 end
    local ok, id = pcall(function()
        local spell = mq.TLO.Spell(name)
        if spell and spell() and spell.ID then return tonumber(spell.ID()) or 0 end
        return 0
    end)
    return ok and (tonumber(id) or 0) or 0
end

local function alla_spell_url(id)
    id = tonumber(id)
    if not id or id <= 0 then return '' end
    return 'https://lazaruseq.com/alla/spells/' .. tostring(math.floor(id))
end

local function open_alla_spell(name)
    name = trim(name)
    local id = resolve_spell_id(name)
    if id <= 0 then
        set_status('No spell id available for Alla: ' .. (name ~= '' and name or '?'))
        return false
    end
    local url = alla_spell_url(id)
    local ok = ShellOpen and ShellOpen.shellOpenUrl and ShellOpen.shellOpenUrl(url)
    set_status(ok and ('Opening Alla spell ' .. tostring(id)) or 'Alla spell open failed.')
    return ok and true or false
end

local function copy_text(label, text)
    text = trim(text)
    if text == '' then return false end
    if ImGui.SetClipboardText then pcall(ImGui.SetClipboardText, text) end
    set_status('Copied ' .. trim(label or 'text'))
    return true
end

local function spell_context(name, suffix)
    name = trim(name)
    if name == '' or not ImGui.BeginPopupContextItem then return end
    suffix = tostring(suffix or name):gsub('[^%w_]', '_')
    if ImGui.BeginPopupContextItem('##rl_spell_ctx_' .. suffix) then
        ImGui.TextColored(0.25, 0.85, 1.0, 1.0, name)
        ImGui.Separator()
        if ImGui.Selectable('Open Alla##rl_spell_alla_' .. suffix) then
            open_alla_spell(name)
        end
        if ImGui.Selectable('Copy name##rl_spell_copy_' .. suffix) then
            copy_text('Spell name', name)
        end
        local id = resolve_spell_id(name)
        if id > 0 then
            if ImGui.Selectable('Copy Alla URL##rl_spell_copy_alla_' .. suffix) then
                copy_text('Alla URL', alla_spell_url(id))
            end
        else
            if ImGui.BeginDisabled then ImGui.BeginDisabled(true) end
            ImGui.Selectable('Copy Alla URL##rl_spell_no_alla_' .. suffix)
            if ImGui.EndDisabled then ImGui.EndDisabled() end
            if ImGui.IsItemHovered and ImGui.IsItemHovered() and ImGui.SetTooltip then
                ImGui.SetTooltip('No spell id resolved from MQ for this name.')
            end
        end
        ImGui.EndPopup()
    end
end

-- ---------------------------------------------------------------------------
-- Config / data loading
-- ---------------------------------------------------------------------------

local function resolve_config_dir()
    local mqPath = trim(mq.TLO.MacroQuest.Path() or ''):gsub('[\\/]+$', '')
    if mqPath == '' then return nil end
    return mqPath .. '\\Config'
end

local function default_import_path()
    local dir = resolve_config_dir()
    if not dir then return '' end
    local char = (mq.TLO.Me.CleanName() or 'unknown'):gsub('[^%w_%-]', '_')
    return dir .. '\\ResearchLearn_want_' .. char .. '.txt'
end

local function parse_import_file(path)
    local entries = {}
    local meta = { copies = 1, class = normalize_class(mq.TLO.Me.Class.ShortName() or ''), character = '', exported = '' }
    if not path or path == '' or not file_exists(path) then return entries, meta end
    local fh = io.open(path, 'r')
    if not fh then return entries, meta end
    for line in fh:lines() do
        line = trim(line)
        if line == '' or line:sub(1, 1) == '#' then
            local k, v = line:match('^#%s*([^=]+)=(.+)$')
            if k and v then
                k = trim(k):lower()
                if k == 'class' then meta.class = normalize_class(v)
                elseif k == 'character' then meta.character = trim(v)
                elseif k == 'exported' then meta.exported = trim(v)
                elseif k == 'copies' then meta.copies = tonumber(v) or meta.copies end
            end
        elseif line == '---' then
            -- header/body separator
        elseif line:match('^copies=%d+') then
            meta.copies = tonumber(line:match('(%d+)')) or meta.copies
        else
            local parts = {}
            for p in line:gmatch('[^|]+') do parts[#parts + 1] = trim(p) end
            local cls, level, name, copies = meta.class, nil, nil, meta.copies
            if #parts == 1 then
                name = parts[1]
            elseif #parts == 2 then
                if tonumber(parts[1]) then level = tonumber(parts[1]); name = parts[2]
                elseif tonumber(parts[2]) then name = parts[1]; copies = tonumber(parts[2])
                else cls = normalize_class(parts[1]); name = parts[2] end
            elseif #parts >= 3 then
                cls = normalize_class(parts[1])
                level = tonumber(parts[2])
                name = parts[3]
                if parts[4] then copies = tonumber(parts[4]) or copies end
            end
            if name and name ~= '' then
                entries[#entries + 1] = {
                    class = cls,
                    level = level,
                    name = name,
                    copies = math.max(1, math.floor(tonumber(copies) or meta.copies or 1)),
                }
            end
        end
    end
    fh:close()
    return entries, meta
end

local function load_import_entries()
    local path = trim(state.importPath)
    if path == '' then path = default_import_path() end
    state.importPath = path
    local entries, meta = parse_import_file(path)
    state.importEntries = entries
    state.importMeta = meta
    state.planKey = ''
    return entries, path
end

local function import_list_label(item)
    if not item then return 'No import files found' end
    local who = item.meta and item.meta.character or ''
    if who == '' then
        who = (item.fname or ''):match('ResearchLearn_want_(.+)%.txt') or (item.fname or '?')
    end
    local cls = (item.meta and item.meta.class) or '?'
    local when = (item.meta and item.meta.exported) or ''
    if when == '' then when = '?' end
    return string.format('%s (%s, %d spells) - %s', who, cls, item.spellCount or 0, when)
end

local function peek_import_meta(path)
    local meta = { copies = 1, character = '', class = '', exported = '' }
    local spellCount = 0
    if not path or path == '' or not file_exists(path) then return meta, 0 end
    local fh = io.open(path, 'r')
    if not fh then return meta, 0 end
    local inBody = false
    for line in fh:lines() do
        line = trim(line)
        if not inBody then
            if line == '---' then
                inBody = true
            elseif line:match('^copies=%d+') then
                meta.copies = tonumber(line:match('(%d+)')) or meta.copies
            else
                local k, v = line:match('^#%s*([^=]+)=(.+)$')
                if k and v then
                    k = trim(k):lower()
                    if k == 'class' then meta.class = normalize_class(v)
                    elseif k == 'character' then meta.character = trim(v)
                    elseif k == 'exported' then meta.exported = trim(v)
                    elseif k == 'copies' then meta.copies = tonumber(v) or meta.copies end
                end
            end
        elseif line ~= '' and not line:match('^#') then
            spellCount = spellCount + 1
        end
    end
    fh:close()
    return meta, spellCount
end

local function list_want_filenames(dir)
    local names = {}
    local ok, lfs = pcall(require, 'lfs')
    if ok and lfs and lfs.dir then
        for entry in lfs.dir(dir) do
            if entry ~= '.' and entry ~= '..' and entry:match('^ResearchLearn_want_.+%.txt$') then
                names[#names + 1] = entry
            end
        end
        return names
    end
    return nil
end

local function scan_import_files(force)
    local now = mq.gettime()
    if not force and state.importScanAt and (now - state.importScanAt) < 30000 then
        return state.importFiles or {}
    end

    local dir = resolve_config_dir()
    local files = {}
    if dir then
        local names = list_want_filenames(dir)
        if not names then
            if not force then
                return state.importFiles or {}
            end
            local cmd = string.format('dir /b "%s\\ResearchLearn_want_*.txt" 2>nul', dir)
            local handle = io.popen(cmd)
            names = {}
            if handle then
                for fname in handle:lines() do
                    fname = trim(fname)
                    if fname ~= '' then names[#names + 1] = fname end
                end
                handle:close()
            end
        end
        for _, fname in ipairs(names) do
            local path = dir .. '\\' .. fname
            local meta, spellCount = peek_import_meta(path)
            files[#files + 1] = {
                path = path,
                fname = fname,
                meta = meta,
                spellCount = spellCount,
            }
        end
    end

    table.sort(files, function(a, b)
        local me = (mq.TLO.Me.CleanName() or ''):lower()
        local aIsFriend = (a.meta.character or ''):lower() ~= me and (a.meta.character or '') ~= ''
        local bIsFriend = (b.meta.character or ''):lower() ~= me and (b.meta.character or '') ~= ''
        if aIsFriend ~= bIsFriend then return aIsFriend end
        return (a.meta.exported or a.fname) > (b.meta.exported or b.fname)
    end)

    state.importFiles = files
    state.importScanAt = now
    return files
end

local function pick_best_import_index(files)
    if not files or #files == 0 then return 0 end
    local me = (mq.TLO.Me.CleanName() or ''):lower()
    for i, f in ipairs(files) do
        if (f.spellCount or 0) > 0 and (f.meta.character or ''):lower() ~= me and (f.meta.character or '') ~= '' then
            return i
        end
    end
    for i, f in ipairs(files) do
        if (f.spellCount or 0) > 0 then return i end
    end
    return 1
end

local function select_import_file(index)
    local files = state.importFiles or scan_import_files(false)
    if index < 1 or index > #files then return false end
    local path = files[index].path
    if state.importListIndex == index and trim(state.importPath) == path and state.importEntries then
        return false
    end
    state.importListIndex = index
    state.importPath = path
    state.planKey = ''
    load_import_entries()
    return true
end

local function clean_old_want_lists(keepPath)
    keepPath = trim(keepPath or '')
    local files = scan_import_files(true)
    local removed = 0
    for _, f in ipairs(files) do
        if keepPath == '' or f.path ~= keepPath then
            local ok, err = os.remove(f.path)
            if ok then
                removed = removed + 1
            end
        end
    end
    state.importScanAt = nil
    state.importFiles = {}
    if keepPath ~= '' and file_exists(keepPath) then
        scan_import_files(true)
        for i, f in ipairs(state.importFiles or {}) do
            if f.path == keepPath then
                state.importListIndex = i
                break
            end
        end
    else
        state.importListIndex = 0
        state.importPath = ''
        state.importEntries = {}
        state.importMeta = {}
        state.planKey = ''
        scan_import_files(true)
    end
    return removed
end

local function ensure_import_ready(forceRescan)
    local files = scan_import_files(forceRescan)
    if #files == 0 then
        state.importEntries = state.importEntries or {}
        return false
    end
    if state.importListIndex < 1 or state.importListIndex > #files or forceRescan then
        state.importListIndex = pick_best_import_index(files)
    end
    local item = files[state.importListIndex]
    if item and trim(state.importPath) ~= item.path then
        state.importPath = item.path
        load_import_entries()
    elseif item and not state.importEntries then
        load_import_entries()
    end
    return true
end

local function parse_ini_file(iniPath)
    local sections = {}
    if not iniPath or not file_exists(iniPath) then return sections end
    local fh = io.open(iniPath, 'r')
    if not fh then return sections end
    local current = nil
    for line in fh:lines() do
        local sec = line:match('^%[(.-)%]$')
        if sec then
            current = trim(sec)
            sections[current] = sections[current] or {}
        elseif current then
            local key, val = line:match('^([^=]+)=(.*)$')
            if key then sections[current][trim(key)] = trim(val) end
        end
    end
    fh:close()
    return sections
end

local function resolve_ini_path()
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    if mqPath == '' then return nil end
    -- Macro reads researchlearn.ini from Macros/; prefer richest copy if several exist.
    local candidates = {
        mqPath .. '\\Macros\\' .. INI_NAME,
        mqPath .. '\\Config\\' .. INI_NAME,
        mqPath .. '\\lua\\' .. INI_NAME,
    }
    local bestPath, bestScore = nil, -1
    for _, p in ipairs(candidates) do
        if file_exists(p) then
            local sections = parse_ini_file(p)
            local score = 0
            for secName, sec in pairs(sections) do
                if secName:match('_%d+$') then
                    score = score + (tonumber(sec.SpellCount) or 0)
                end
            end
            if score > bestScore then
                bestScore = score
                bestPath = p
            end
        end
    end
    if bestPath then return bestPath end
    return candidates[1]
end

local function ensure_ini_loaded()
    local path = resolve_ini_path()
    if not path then
        state.iniPath = nil
        state.iniSections = {}
        return
    end
    if state.iniPath ~= path or not state.iniSections then
        state.iniPath = path
        state.iniSections = parse_ini_file(path)
        state.planKey = ''
    end
end

local function reload_ini_cache()
    state.iniPath = nil
    state.iniSections = nil
    state.planKey = ''
    ensure_ini_loaded()
end

local function load_spells_config()
    if state.spellsLoaded then return state.spellsConfig end
    state.spellsLoaded = true
    local mqPath = mq.TLO.MacroQuest.Path() or ''
    local paths = {
        mqPath .. '\\lua\\lazbis\\spells.lua',
        mqPath .. '\\lazbis\\spells.lua',
    }
    for _, p in ipairs(paths) do
        local chunk = loadfile(p)
        if chunk then
            local ok, data = pcall(chunk)
            if ok and type(data) == 'table' then
                state.spellsConfig = data
                return data
            end
        end
    end
    state.spellsConfig = nil
    return nil
end

local function load_config()
    ensure_ini_loaded()
    load_spells_config()

    local settings = (state.iniSections or {}).Settings or {}
    local pack = tonumber(settings.ResearchKitPack)
    if pack and pack > 0 then state.kitPack = pack end

    local classesSec = (state.iniSections or {}).Classes or {}
    local count = tonumber(classesSec.ClassCount) or 0
    if count > 0 then
        local list = {}
        for i = 1, count do
            local c = classesSec['Class' .. i]
            if c and c ~= '' then list[#list + 1] = c:lower() end
        end
        if #list > 0 then state.classes = list end
    end

    local meClass = normalize_class(mq.TLO.Me.Class.ShortName() or '')
    for i, c in ipairs(state.classes) do
        if c == meClass then
            state.classIndex = i - 1
            break
        end
    end
end

local function classify_source(source)
    local s = trim(source):lower()
    if s:find('random drop', 1, true) then return 'drop', 'Drop' end
    if s:find('anguish', 1, true) then return 'anguish', 'Anguish' end
    if s:find('pok library', 1, true) or s:find('library', 1, true) then return 'library', 'PoK Library' end
    if s:find('quest', 1, true) then return 'quest', 'Quest' end
    if s:find('research', 1, true) then return 'research', trim(source) end
    if s == '???' or s == '' then return 'other', source or '?' end
    return 'other', trim(source)
end

local function levels_for_selection(levelStr)
    if levelStr == 'all' then return LEVEL_NUMS end
    local n = tonumber(levelStr)
    if n then return { n } end
    return LEVEL_NUMS
end

local function product_norm(raw)
    return normalize_name(raw:gsub('^Spell:%s*', ''):gsub('^Skill:%s*', ''):gsub('^Tome of%s*', ''):gsub('%s+Rk%.%s*II$', ''))
end

local function ini_recipes_for_class(className)
    local out = {}
    local sections = state.iniSections or {}
    for secName, sec in pairs(sections) do
        local cls, lv = secName:match('^(.+)_(%d+)$')
        if cls and cls:lower() == className:lower() then
            local spellCount = tonumber(sec.SpellCount) or 0
            for sn = 1, spellCount do
                local raw = sec['Spell' .. sn]
                if raw and raw ~= '' then
                    local display = raw:gsub('^Spell:%s*', ''):gsub('^Skill:%s*', ''):gsub('^Tome of%s*', '')
                    local ings = {}
                    for ing = 1, 20 do
                        local iname = sec['Spell' .. sn .. '_Ingredient' .. ing]
                        if iname and iname ~= '' then ings[#ings + 1] = iname end
                    end
                    out[#out + 1] = {
                        section = secName,
                        level = tonumber(lv),
                        spellNum = sn,
                        iniRaw = raw,
                        name = display,
                        norm = product_norm(raw),
                        ingredients = ings,
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.level == b.level then return a.spellNum < b.spellNum end
        return (a.level or 0) > (b.level or 0)
    end)
    return out
end

local function find_ini_recipe(className, spellName)
    className = normalize_class(className)
    local norm = normalize_name(spellName)
    local candidates = { norm }
    if not norm:find('^tome of ') then
        candidates[#candidates + 1] = normalize_name('Tome of ' .. spellName)
        candidates[#candidates + 1] = normalize_name('Tome of ' .. spellName .. ' Rk. II')
        candidates[#candidates + 1] = normalize_name('Skill: ' .. spellName)
    end
    for _, rec in ipairs(ini_recipes_for_class(className)) do
        for _, c in ipairs(candidates) do
            if rec.norm == c or product_norm(rec.iniRaw) == c then return rec end
        end
    end
    for _, rec in ipairs(ini_recipes_for_class(className)) do
        for _, c in ipairs(candidates) do
            if rec.norm:find(c, 1, true) or c:find(rec.norm, 1, true) then return rec end
        end
    end
    return nil
end

local function find_ini_recipe_any(spellName)
    for _, cls in ipairs(state.classes) do
        local rec = find_ini_recipe(cls, spellName)
        if rec then return rec, normalize_class(cls) end
    end
    -- Fallback: scan every level section in the loaded INI (handles class list drift)
    local sections = state.iniSections or {}
    local seen = {}
    for secName, _ in pairs(sections) do
        local cls = secName:match('^(.+)_%d+$')
        if cls then
            cls = normalize_class(cls)
            if not seen[cls] then
                seen[cls] = true
                local rec = find_ini_recipe(cls, spellName)
                if rec then return rec, cls end
            end
        end
    end
    return nil, nil
end

local function spell_inventory_info(displayName, iniRaw)
    displayName = trim(displayName)
    local variants = { displayName, scroll_label(displayName) }
    if iniRaw and trim(iniRaw) ~= '' then
        variants[#variants + 1] = trim(iniRaw)
    end
    local inBook = false
    pcall(function()
        for _, variant in ipairs(variants) do
            if (mq.TLO.Me.Book(variant)() or 0) > 0 or (mq.TLO.Me.CombatAbility(variant)() or 0) > 0 then
                inBook = true
                break
            end
        end
    end)
    local scroll = 0
    pcall(function()
        for _, variant in ipairs(variants) do
            scroll = math.max(scroll, mq.TLO.FindItemCount('=' .. variant)() or 0)
        end
    end)
    return { inBook = inBook, scroll = scroll }
end

local function spell_owned_count(info, runMode)
    -- Import and single-spell: copies = scrolls to make; scribed does not block craft.
    if runMode == 'import' or runMode == 'spell' then
        return info.scroll
    end
    return info.scroll + (info.inBook and 1 or 0)
end

local function format_have_label(info, qty, runMode)
    if runMode == 'import' or runMode == 'spell' then
        local scr = string.format('%d/%d scr', info.scroll, qty)
        if info.inBook then
            return 'Scribed, ' .. scr
        end
        return scr
    end
    if info.inBook and info.scroll == 0 then
        return 'Scribed'
    end
    if info.inBook and info.scroll > 0 then
        return string.format('Scribed + %d scr', info.scroll)
    end
    if info.scroll > 0 then
        return string.format('%d/%d scr', info.scroll, qty)
    end
    return string.format('0/%d', qty)
end

local function spell_plan_from_inventory(info, qty, runMode)
    local owned = spell_owned_count(info, runMode)
    local need = math.max(0, qty - owned)
    return owned, need, format_have_label(info, qty, runMode)
end

local function spell_satisfied_message(info, qty, runMode)
    if runMode == 'import' or runMode == 'spell' then
        return string.format('Already have %d/%d scroll copies.', info.scroll, qty)
    end
    if info.inBook and info.scroll == 0 then
        return 'Scribed in spell book - you know this spell (not a scroll in inventory).'
    end
    return string.format('Already have %s.', format_have_label(info, qty, runMode))
end

local function item_count(name)
    local n = 0
    pcall(function()
        n = (mq.TLO.FindItemCount('=' .. name)() or 0) + (mq.TLO.FindItemBankCount('=' .. name)() or 0)
    end)
    return n
end

local function research_skill()
    local skill = 0
    pcall(function()
        skill = mq.TLO.Me.Skill('Research')() or 0
        if skill == 0 then skill = mq.TLO.Me.Skill('Spell Research')() or 0 end
    end)
    return skill
end

local function recommended_skill_tier(skill)
    skill = skill or research_skill()
    if skill >= RESEARCH_SKILL_CAP then return nil, 'done' end
    for _, tier in ipairs(SKILL_TIERS) do
        if skill < (tier.trivial or 0) then
            return tier, tier.id
        end
    end
    return nil, 'done'
end

local function skill_tier_label(index)
    if index == 0 then return 'Auto (advance when trivial)' end
    local tier = SKILL_TIERS[index]
    if not tier then return 'Auto' end
    return string.format('%s (trivial %d)', tier.label, tier.trivial or 0)
end

local function active_skill_tier()
    if state.skillTierIndex == 0 then
        return recommended_skill_tier()
    end
    local tier = SKILL_TIERS[state.skillTierIndex]
    if tier then return tier, tier.id end
    return recommended_skill_tier()
end

-- ---------------------------------------------------------------------------
-- Run plan (manifest + ingredients)
-- ---------------------------------------------------------------------------

local function build_plan_key()
    local cls = state.classes[state.classIndex + 1] or ''
    local lvl = LEVELS[state.levelIndex + 1] or 'all'
    local qty = math.max(1, math.floor(tonumber(state.quantity) or 1))
    return string.format('%s|%s|%d|%s|%s|%s|%s|%s',
        cls, lvl, qty, state.runMode, trim(state.spellName),
        state.researchOnly and '1' or '0', state.hideOwned and '1' or '0', trim(state.importPath))
end

local function build_run_plan()
    ensure_ini_loaded()
    load_spells_config()

    local qty = math.max(1, math.floor(tonumber(state.quantity) or 1))
    local plan = {
        rows = {},
        ingredients = {},
        summary = {
            total = 0,
            satisfied = 0,
            craftable = 0,
            drop = 0,
            anguish = 0,
            noRecipe = 0,
            other = 0,
            toCraft = 0,
        },
        canStart = false,
        blockReason = '',
        warns = {},
        hasSpellsLua = state.spellsConfig ~= nil,
    }

    local ingTotals = {}
    local craftWork = 0

    local function add_ingredients(recipe, copiesNeeded)
        if copiesNeeded <= 0 then return end
        for _, ingName in ipairs(recipe.ingredients) do
            ingTotals[ingName] = (ingTotals[ingName] or 0) + copiesNeeded
        end
    end

    local function laz_display_name(lazClass, level, norm)
        for _, entry in ipairs((state.spellsConfig[lazClass] or {})[level] or {}) do
            local n = entry:match('^([^|]+)')
            if normalize_name(n or '') == norm then return n end
        end
        return norm
    end

    local function push_row(row)
        if state.researchOnly and (row.sourceKind == 'drop' or row.sourceKind == 'anguish' or row.sourceKind == 'library' or row.sourceKind == 'quest') then
            return
        end
        if state.hideOwned and row.have >= qty then
            return
        end
        plan.rows[#plan.rows + 1] = row
        plan.summary.total = plan.summary.total + 1
        if row.status == 'satisfied' then
            plan.summary.satisfied = plan.summary.satisfied + 1
        elseif row.status == 'craftable' then
            plan.summary.craftable = plan.summary.craftable + 1
        elseif row.sourceKind == 'drop' then
            plan.summary.drop = plan.summary.drop + 1
        elseif row.sourceKind == 'anguish' then
            plan.summary.anguish = plan.summary.anguish + 1
        elseif row.sourceKind == 'library' then
            plan.summary.other = plan.summary.other + 1
        elseif row.sourceKind == 'quest' then
            plan.summary.other = plan.summary.other + 1
        elseif not row.inIni then
            plan.summary.noRecipe = plan.summary.noRecipe + 1
        else
            plan.summary.other = plan.summary.other + 1
        end
    end

    local function finalize_plan()
        for ingName, need in pairs(ingTotals) do
            local have = item_count(ingName)
            plan.ingredients[#plan.ingredients + 1] = {
                name = ingName,
                need = need,
                have = have,
                short = math.max(0, need - have),
            }
        end
        table.sort(plan.ingredients, function(a, b)
            if a.short == b.short then return a.name < b.name end
            return a.short > b.short
        end)

        if not plan.hasSpellsLua then
            plan.warns[#plan.warns + 1] = 'lazbis/spells.lua not found - showing INI recipes only.'
        end
    end

    if state.runMode == 'import' then
        ensure_import_ready(false)
        local entries = state.importEntries
        if not entries then
            entries = load_import_entries()
        end
        if #entries == 0 then
            plan.blockReason = 'Import list empty - run ResearchLearnExport on alt or pick a file.'
            finalize_plan()
            return plan
        end
        for _, entry in ipairs(entries) do
            local rec = entry.class and find_ini_recipe(entry.class, entry.name) or nil
            local recClass = entry.class
            if not rec then
                rec, recClass = find_ini_recipe_any(entry.name)
            end
            local qtyWant = entry.copies or 1
            local inv = spell_inventory_info(entry.name, rec and rec.iniRaw)
            local have, need, haveLabel = spell_plan_from_inventory(inv, qtyWant, 'import')
            local status = 'noRecipe'
            if have >= qtyWant then
                status = 'satisfied'
            elseif rec then
                status = 'craftable'
                if need > 0 then
                    add_ingredients(rec, need)
                    craftWork = craftWork + 1
                end
            end
            push_row({
                level = entry.level or (rec and rec.level) or 0,
                name = entry.name,
                source = 'Import',
                sourceKind = 'research',
                inIni = rec ~= nil,
                inBook = inv.inBook,
                scrollCount = inv.scroll,
                have = have,
                haveLabel = haveLabel,
                need = need,
                status = status,
                iniClass = recClass,
            })
        end
        plan.summary.toCraft = craftWork
        if craftWork > 0 then
            plan.canStart = true
        else
            plan.blockReason = 'Import list has nothing craftable (missing INI or already satisfied).'
        end
        finalize_plan()
        return plan
    end

    if state.runMode == 'spell' then
        local name = trim(state.spellName)
        if name == '' then
            plan.blockReason = 'Enter a spell name.'
            return plan
        end
        local rec, recClass = find_ini_recipe_any(name)
        local lazClass = recClass and CLASS_TO_LAZ[recClass] or CLASS_TO_LAZ[state.classes[state.classIndex + 1] or '']
        local sourceText, sourceKind = 'INI', 'research'
        if state.spellsConfig and lazClass and state.spellsConfig[lazClass] then
            for _, lv in ipairs(LEVEL_NUMS) do
                for _, entry in ipairs(state.spellsConfig[lazClass][lv] or {}) do
                    local parts = {}
                    for p in entry:gmatch('[^|]+') do parts[#parts + 1] = p end
                    local lazName = parts[1] or entry
                    if normalize_name(lazName) == normalize_name(name) then
                        sourceKind, sourceText = classify_source(parts[2] or '')
                        break
                    end
                end
            end
        end
        local inv = spell_inventory_info(name, rec and rec.iniRaw)
        local have, need, haveLabel = spell_plan_from_inventory(inv, qty, 'spell')
        local inIni = rec ~= nil
        local status = 'other'
        if have >= qty then
            status = 'satisfied'
        elseif sourceKind == 'drop' or sourceKind == 'anguish' or sourceKind == 'library' or sourceKind == 'quest' then
            status = sourceKind
        elseif inIni then
            status = 'craftable'
            if need > 0 then
                add_ingredients(rec, need)
                craftWork = craftWork + 1
            end
        else
            status = 'noRecipe'
        end
        push_row({
            level = rec and rec.level or 0,
            name = name,
            source = sourceText,
            sourceKind = sourceKind,
            inIni = inIni,
            inBook = inv.inBook,
            scrollCount = inv.scroll,
            have = have,
            haveLabel = haveLabel,
            need = need,
            status = status,
            iniClass = recClass,
        })
        if sourceKind == 'drop' then
            plan.blockReason = 'That spell is a random drop - not researchable.'
        elseif sourceKind == 'anguish' then
            plan.blockReason = 'That spell is an Anguish turn-in - not researchable.'
        elseif sourceKind == 'library' then
            plan.blockReason = 'That item is bought at a PoK library vendor - not spell research.'
        elseif sourceKind == 'quest' then
            plan.blockReason = 'That spell is from a quest - not spell research.'
        elseif not inIni then
            plan.blockReason = 'No recipe in researchlearn.ini for that spell.'
        elseif need <= 0 then
            plan.blockReason = spell_satisfied_message(inv, qty, 'spell')
        else
            plan.canStart = true
        end
        finalize_plan()
        return plan
    end

    local cls = state.classes[state.classIndex + 1]
    if not cls or cls == '' then
        plan.blockReason = 'Pick a class.'
        return plan
    end

    local levelStr = LEVELS[state.levelIndex + 1] or 'all'
    local levels = levels_for_selection(levelStr)
    local lazClass = CLASS_TO_LAZ[cls]
    local lazByNorm = {}

    if state.spellsConfig and lazClass and state.spellsConfig[lazClass] then
        for _, lv in ipairs(levels) do
            for _, entry in ipairs(state.spellsConfig[lazClass][lv] or {}) do
                local parts = {}
                for p in entry:gmatch('[^|]+') do parts[#parts + 1] = p end
                local lazName = parts[1] or entry
                local kind, src = classify_source(parts[2] or '')
                lazByNorm[normalize_name(lazName)] = { kind = kind, source = src, level = lv }
            end
        end
    end

    local iniByNorm = {}
    for _, rec in ipairs(ini_recipes_for_class(cls)) do
        local include = (levelStr == 'all')
        if not include then
            for _, lv in ipairs(levels) do
                if rec.level == lv then include = true; break end
            end
        end
        if include then iniByNorm[rec.norm] = rec end
    end

    local seenNorm = {}

    if next(lazByNorm) then
        for norm, laz in pairs(lazByNorm) do
            seenNorm[norm] = true
            local rec = iniByNorm[norm]
            local display = laz_display_name(lazClass, laz.level, norm)
            local inv = spell_inventory_info(display, rec and rec.iniRaw)
            local have, need, haveLabel = spell_plan_from_inventory(inv, qty, 'class')
            local status = 'other'
            if have >= qty then
                status = 'satisfied'
            elseif laz.kind == 'drop' then
                status = 'drop'
            elseif laz.kind == 'anguish' then
                status = 'anguish'
            elseif rec then
                status = 'craftable'
            else
                status = 'noRecipe'
            end
            if rec and need > 0 and laz.kind ~= 'drop' and laz.kind ~= 'anguish' and laz.kind ~= 'library' and laz.kind ~= 'quest' then
                add_ingredients(rec, need)
                craftWork = craftWork + 1
            end
            push_row({
                level = laz.level,
                name = display,
                source = laz.source,
                sourceKind = laz.kind,
                inIni = rec ~= nil,
                inBook = inv.inBook,
                scrollCount = inv.scroll,
                have = have,
                haveLabel = haveLabel,
                need = need,
                status = status,
            })
        end
    end

    for norm, rec in pairs(iniByNorm) do
        if not seenNorm[norm] then
            local inv = spell_inventory_info(rec.name, rec.iniRaw)
            local have, need, haveLabel = spell_plan_from_inventory(inv, qty, 'class')
            local status = have >= qty and 'satisfied' or 'craftable'
            if need > 0 then
                add_ingredients(rec, need)
                craftWork = craftWork + 1
            end
            push_row({
                level = rec.level,
                name = rec.name,
                source = 'INI only',
                sourceKind = 'research',
                inIni = true,
                inBook = inv.inBook,
                scrollCount = inv.scroll,
                have = have,
                haveLabel = haveLabel,
                need = need,
                status = status,
            })
        end
    end

    table.sort(plan.rows, function(a, b)
        if a.level == b.level then return a.name < b.name end
        return (a.level or 0) > (b.level or 0)
    end)

    plan.summary.toCraft = craftWork
    if craftWork > 0 then
        plan.canStart = true
    else
        plan.blockReason = 'Nothing to craft - all research spells satisfied or filtered out.'
    end

    finalize_plan()
    return plan
end

local function get_plan(force)
    local key = build_plan_key()
    if force or key ~= state.planKey or not state.plan then
        state.planKey = key
        state.plan = build_run_plan()
        state.lastCountRefresh = mq.gettime()
    elseif mq.gettime() - state.lastCountRefresh > 8000 then
        state.plan = build_run_plan()
        state.lastCountRefresh = mq.gettime()
    end
    return state.plan
end

-- ---------------------------------------------------------------------------
-- Macro control
-- ---------------------------------------------------------------------------

local function active_macro_name()
    local name = ''
    pcall(function()
        if mq.TLO.Macro and mq.TLO.Macro.Name then
            name = mq.TLO.Macro.Name() or ''
        end
    end)
    name = trim(name)
    if name == '' or name:upper() == 'NULL' then
        local parsed = mq.parse('${Macro.Name}')
        if parsed and parsed ~= '${Macro.Name}' then name = trim(parsed) end
    end
    if name == '' or name:upper() == 'NULL' then
        local parsed = mq.parse('${Macro}')
        if parsed and parsed ~= '${Macro}' then name = trim(parsed) end
    end
    if name == '' or name:upper() == 'NULL' then return '' end
    return name:lower()
end

local function macro_running()
    local name = active_macro_name()
    if name == '' then return false end
    return name:find(MACRO_NAME, 1, true) ~= nil
end

local function skill_macro_running()
    local name = active_macro_name()
    if name == '' then return false end
    if name == SKILL_MACRO then return true end
    for _, tier in ipairs(SKILL_TIERS) do
        if name == tier.id then return true end
    end
    return false
end

local function any_macro_running()
    return macro_running() or skill_macro_running()
end

-- Pass multi-word spell names through Config INI — mq.cmd and /declare both split on spaces.
local function write_import_pass(queue)
    local dir = resolve_config_dir()
    if not dir then return false end
    local path = dir .. '\\ResearchLearn_pass.ini'
    local fh = io.open(path, 'w')
    if not fh then return false end
    fh:write(string.format('[Pass]\nCount=%d\n', #queue))
    for i, item in ipairs(queue) do
        local name = trim(item.name or ''):gsub('[\r\n]', '')
        local copies = math.max(1, math.floor(tonumber(item.copies) or 1))
        fh:write(string.format('Item%d=%s\nQty%d=%d\n', i, name, i, copies))
    end
    fh:close()
    return true
end

local function launch_import_batch_macro()
    mq.cmdf('/mac %s _import', MACRO_NAME)
    return true
end

local function write_spell_pass(spellName, copies)
    local dir = resolve_config_dir()
    if not dir then return false end
    local path = dir .. '\\ResearchLearn_pass.ini'
    local fh = io.open(path, 'w')
    if not fh then return false end
    fh:write(string.format('[Pass]\nName=%s\nCopies=%d\n', spellName:gsub('[\r\n]', ''), copies))
    fh:close()
    return true
end

local function launch_single_spell_macro(spellName, copies)
    spellName = trim(spellName)
    copies = math.max(1, math.floor(tonumber(copies) or 1))
    if not write_spell_pass(spellName, copies) then
        set_status('Could not write ResearchLearn_pass.ini — check Config folder.')
        return false
    end
    mq.cmdf('/mac %s _spell', MACRO_NAME)
    return true
end

local function write_class_pass(className, level, copies)
    local dir = resolve_config_dir()
    if not dir then return false end
    local path = dir .. '\\ResearchLearn_pass.ini'
    local fh = io.open(path, 'w')
    if not fh then return false end
    fh:write(string.format(
        '[Pass]\nClass=%s\nLevel=%s\nCopies=%d\n',
        className:gsub('[\r\n]', ''),
        level:gsub('[\r\n]', ''),
        copies
    ))
    fh:close()
    return true
end

local function launch_class_macro(className, level, copies)
    className = trim(className)
    level = trim(level or 'all')
    if level == '' then level = 'all' end
    copies = math.max(1, math.floor(tonumber(copies) or 1))
    if not write_class_pass(className, level, copies) then
        set_status('Could not write ResearchLearn_pass.ini — check Config folder.')
        return false
    end
    mq.cmdf('/mac %s _class', MACRO_NAME)
    return true
end

local function run_doctor()
    local cls = state.classes[state.classIndex + 1] or ''
    if cls ~= '' then
        mq.cmdf('/mac %s doctor %s', MACRO_NAME, cls)
    else
        mq.cmdf('/mac %s doctor', MACRO_NAME)
    end
    set_status('Doctor sent to chat.')
end

local function run_stop()
    mq.cmd('/nav stop')
    if any_macro_running() then
        mq.cmd('/endmac')
        state.importRunning = false
        state.importBatchLaunched = false
        state.importQueue = {}
        set_status('Stop sent (/nav stop, /endmac).')
    else
        set_status('Nav stopped.')
    end
end

local function tick_import_queue()
    if not state.importRunning then return end
    if any_macro_running() then return end
    if state.importBatchLaunched then
        state.importRunning = false
        state.importBatchLaunched = false
        set_status('Import batch finished.')
    end
end

local function start_import_queue(plan)
    if any_macro_running() then
        set_status('Macro already running - stop first.')
        return
    end
    state.importQueue = {}
    for _, row in ipairs(plan.rows or {}) do
        if row.status == 'craftable' and row.need and row.need > 0 then
            state.importQueue[#state.importQueue + 1] = {
                name = row.name,
                copies = row.need,
            }
        end
    end
    if #state.importQueue == 0 then
        set_status('Nothing to run from import list.')
        return
    end
    if not write_import_pass(state.importQueue) then
        set_status('Could not write ResearchLearn_pass.ini — check Config folder.')
        return
    end
    state.importIndex = #state.importQueue
    state.importRunning = true
    state.importBatchLaunched = true
    launch_import_batch_macro()
    set_status(string.format('Import batch: %d spell(s) — one buy + parchment prep', #state.importQueue))
end

local function run_skill_start()
    if any_macro_running() then
        set_status('Macro already running - stop first.')
        return
    end
    local mode = 'auto'
    if state.skillTierIndex > 0 then
        local tier = SKILL_TIERS[state.skillTierIndex]
        if tier then mode = tier.id end
    end
    mq.cmdf('/mac %s %s', SKILL_MACRO, mode)
    if mode == 'auto' then
        local tier = recommended_skill_tier()
        set_status(string.format('Skill-up started: auto (/mac %s) - currently %s', SKILL_MACRO, tier and tier.label or 'done'))
    else
        local tier = SKILL_TIERS[state.skillTierIndex]
        set_status(string.format('Skill-up started: %s (/mac %s %s)', tier and tier.label or mode, SKILL_MACRO, mode))
    end
end

local function run_start()
    if any_macro_running() then
        set_status('Macro already running - stop first or wait.')
        return
    end

    local plan = get_plan(true)

    if state.runMode == 'import' then
        if not plan.canStart then
            set_status(plan.blockReason ~= '' and plan.blockReason or 'Cannot start import queue.')
            return
        end
        ensure_import_ready(false)
        start_import_queue(plan)
        return
    end

    if not plan.canStart then
        set_status(plan.blockReason ~= '' and plan.blockReason or 'Cannot start this run.')
        return
    end

    local qty = math.max(1, math.floor(tonumber(state.quantity) or 1))
    state.quantity = qty

    if state.runMode == 'spell' then
        local spell = trim(state.spellName)
        if launch_single_spell_macro(spell, qty) then
            set_status(string.format('Started spell: %s x%d', spell, qty))
        end
        return
    end

    local cls = state.classes[state.classIndex + 1]
    local level = LEVELS[state.levelIndex + 1] or 'all'
    if launch_class_macro(cls, level, qty) then
        set_status(string.format('Started %s %s x%d (%d spells to craft)', cls, level, qty, plan.summary.toCraft))
    end
end

-- ---------------------------------------------------------------------------
-- UI draw
-- ---------------------------------------------------------------------------

local function draw_preflight()
    local kitOpen = false
    pcall(function()
        kitOpen = mq.TLO.Window('ContainerCombine_Items').Open() or false
    end)

    local packSlots = 0
    pcall(function()
        local inv = mq.TLO.Me.Inventory('pack' .. state.kitPack)
        if inv and inv.Container then packSlots = inv.Container() or 0 end
    end)

    local zone = '?'
    local pp = 0
    pcall(function()
        zone = mq.TLO.Zone.ShortName() or '?'
        pp = mq.TLO.Me.Platinum() or 0
    end)

    if macro_running() then
        ImGui.TextColored(0.3, 0.9, 0.4, 1.0, 'Macro: researchlearn RUNNING')
    elseif skill_macro_running() then
        ImGui.TextColored(0.3, 0.9, 0.4, 1.0, 'Macro: researchskill RUNNING')
    elseif state.importRunning then
        ImGui.TextColored(0.3, 0.9, 0.4, 1.0, string.format('Import batch: %d spell(s)', #state.importQueue))
    else
        ImGui.TextColored(0.7, 0.7, 0.7, 1.0, 'Macro: idle')
    end

    ImGui.Text(string.format('Zone: %s   PP: %s', zone, pp))
    if kitOpen then
        ImGui.TextColored(0.3, 0.9, 0.4, 1.0, 'Research kit: OPEN')
    else
        ImGui.TextColored(0.95, 0.45, 0.35, 1.0, 'Research kit: closed (macro will auto-open)')
    end
    ImGui.Text(string.format('Kit bag: pack%d (%d slots)', state.kitPack, packSlots))
    ensure_ini_loaded()
    if state.iniPath then
        ImGui.TextDisabled(string.format('INI: %s', state.iniPath))
    else
        ImGui.TextColored(0.95, 0.45, 0.35, 1.0, 'INI: researchlearn.ini not found')
    end
    if ImGui.SmallButton('Reload INI') then
        reload_ini_cache()
        set_status('Reloaded researchlearn.ini')
    end
    ImGui.SameLine()
    if zone:lower() ~= 'poknowledge' then
        ImGui.TextColored(0.95, 0.75, 0.25, 1.0, 'PoK recommended for vendors')
    end
end

local function status_color(row)
    if row.status == 'satisfied' then return 0.45, 0.85, 0.45, 1.0 end
    if row.status == 'craftable' then return 0.95, 0.85, 0.35, 1.0 end
    if row.status == 'drop' then return 0.55, 0.75, 0.95, 1.0 end
    if row.status == 'anguish' then return 0.75, 0.55, 0.95, 1.0 end
    if row.status == 'library' then return 0.85, 0.65, 0.35, 1.0 end
    if row.status == 'quest' then return 0.85, 0.55, 0.55, 1.0 end
    if row.status == 'noRecipe' then return 0.95, 0.45, 0.35, 1.0 end
    return 0.75, 0.75, 0.75, 1.0
end

local function draw_summary_line(plan)
    local s = plan.summary
    ImGui.Text(string.format(
        'Spells: %d shown | %d to craft | %d satisfied | %d no INI',
        s.total, s.toCraft, s.satisfied, s.noRecipe
    ))
    for _, w in ipairs(plan.warns) do
        ImGui.TextColored(UI.amber[1], UI.amber[2], UI.amber[3], 1.0, w)
    end
    if plan.blockReason ~= '' and not plan.canStart then
        ImGui.TextColored(0.95, 0.45, 0.35, 1.0, plan.blockReason)
    end
end

local function draw_manifest(plan)
    if not ImGui.CollapsingHeader('Spell manifest', ImGuiTreeNodeFlags.DefaultOpen) then return end

    local rows = {}
    for i, row in ipairs(plan.rows) do rows[i] = row end

    if ImGui.BeginTable('##rl_manifest', 5, sortable_table_flags(), 0, 180) then
        local col = ImGuiTableColumnFlags
        ImGui.TableSetupColumn('Lvl', col.WidthFixed, 32, SORT_MANIFEST.LVL)
        ImGui.TableSetupColumn('Spell', col.WidthStretch, 1.0, SORT_MANIFEST.SPELL)
        ImGui.TableSetupColumn('Source', col.WidthStretch, 0.45, SORT_MANIFEST.SOURCE)
        ImGui.TableSetupColumn('Have', col.WidthFixed, 88, SORT_MANIFEST.HAVE)
        ImGui.TableSetupColumn('INI', col.WidthFixed, 32, SORT_MANIFEST.INI)
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableHeadersRow()

        local sortOk, sortSpecs = pcall(ImGui.TableGetSortSpecs)
        if sortOk and sortSpecs then
            apply_table_sort(rows, sortSpecs, function(uid, a, b)
                if uid == SORT_MANIFEST.LVL then
                    return (a.level or 0) - (b.level or 0)
                elseif uid == SORT_MANIFEST.SPELL then
                    local an, bn = (a.name or ''):lower(), (b.name or ''):lower()
                    if an < bn then return -1 elseif bn < an then return 1 end
                    return 0
                elseif uid == SORT_MANIFEST.SOURCE then
                    local an, bn = (a.source or ''):lower(), (b.source or ''):lower()
                    if an < bn then return -1 elseif bn < an then return 1 end
                    return 0
                elseif uid == SORT_MANIFEST.HAVE then
                    return (a.have or 0) - (b.have or 0)
                elseif uid == SORT_MANIFEST.INI then
                    local ai = a.inIni and 1 or 0
                    local bi = b.inIni and 1 or 0
                    return ai - bi
                end
                return 0
            end)
        end

        for _, row in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(tostring(row.level or ''))
            ImGui.TableNextColumn()
            local r, g, b, a = status_color(row)
            ImGui.TextColored(r, g, b, a, row.name)
            spell_context(row.name, 'manifest_' .. tostring(row.level or '') .. '_' .. tostring(row.name or ''))
            if ImGui.IsItemHovered() then
                if not row.inIni then
                    ImGui.SetTooltip('No recipe in researchlearn.ini - macro will not craft this spell.')
                elseif row.status == 'library' then
                    ImGui.SetTooltip('PoK library vendor item - not handled by research macro.')
                end
            end
            ImGui.TableNextColumn()
            ImGui.TextDisabled(row.source or '')
            ImGui.TableNextColumn()
            local haveText = row.haveLabel or string.format('%d/%d', row.have or 0, state.quantity)
            ImGui.Text(haveText)
            if ImGui.IsItemHovered() then
                if row.inBook and (row.scrollCount or 0) == 0 then
                    if state.runMode == 'spell' or state.runMode == 'import' then
                        ImGui.SetTooltip('Scribed in spell book. Copies = scrolls to craft; Start is still allowed.')
                    else
                        ImGui.SetTooltip('Scribed in your spell book - you know this spell. Not a scroll in inventory.')
                    end
                elseif row.inBook and (row.scrollCount or 0) > 0 then
                    ImGui.SetTooltip('Scribed, plus scroll copies in bags.')
                elseif (row.scrollCount or 0) > 0 then
                    ImGui.SetTooltip('Scroll copies in inventory (not yet scribed).')
                end
            end
            ImGui.TableNextColumn()
            if row.inIni then
                ImGui.TextColored(0.45, 0.85, 0.45, 1.0, 'Yes')
            else
                ImGui.TextColored(0.95, 0.45, 0.35, 1.0, 'No')
            end
        end
        ImGui.EndTable()
    end
end

local function draw_ingredients(plan)
    if #plan.ingredients == 0 then return end
    if not ImGui.CollapsingHeader('Ingredients (need for this run)', ImGuiTreeNodeFlags.DefaultOpen) then return end

    local rows = {}
    for i, ing in ipairs(plan.ingredients) do rows[i] = ing end

    if ImGui.BeginTable('##rl_ings', 4, sortable_table_flags(), 0, 150) then
        local col = ImGuiTableColumnFlags
        ImGui.TableSetupColumn('Item', col.WidthStretch, 1.0, SORT_ING.ITEM)
        ImGui.TableSetupColumn('Need', col.WidthFixed, 56, SORT_ING.NEED)
        ImGui.TableSetupColumn('Have', col.WidthFixed, 56, SORT_ING.HAVE)
        ImGui.TableSetupColumn('Short', col.WidthFixed, 56, SORT_ING.SHORT)
        ImGui.TableSetupScrollFreeze(0, 1)
        ImGui.TableHeadersRow()

        local sortOk, sortSpecs = pcall(ImGui.TableGetSortSpecs)
        if sortOk and sortSpecs then
            apply_table_sort(rows, sortSpecs, function(uid, a, b)
                if uid == SORT_ING.ITEM then
                    local an, bn = (a.name or ''):lower(), (b.name or ''):lower()
                    if an < bn then return -1 elseif bn < an then return 1 end
                    return 0
                elseif uid == SORT_ING.NEED then
                    return (a.need or 0) - (b.need or 0)
                elseif uid == SORT_ING.HAVE then
                    return (a.have or 0) - (b.have or 0)
                elseif uid == SORT_ING.SHORT then
                    return (a.short or 0) - (b.short or 0)
                end
                return 0
            end)
        end

        for _, ing in ipairs(rows) do
            ImGui.TableNextRow()
            ImGui.TableNextColumn()
            ImGui.Text(ing.name)
            ImGui.TableNextColumn()
            ImGui.Text(string.format('%d', ing.need))
            ImGui.TableNextColumn()
            ImGui.Text(string.format('%d', ing.have))
            ImGui.TableNextColumn()
            if ing.short > 0 then
                ImGui.TextColored(0.95, 0.45, 0.35, 1.0, string.format('%d', ing.short))
            else
                ImGui.TextColored(0.45, 0.85, 0.45, 1.0, '0')
            end
        end
        ImGui.EndTable()
    end
    ImGui.TextWrapped('Macro auto-buys Short items from Scholar Klaz / Vori in PoK when you Start.')
end

local RUN_MODES = {
    { id = 'class', label = 'Class batch' },
    { id = 'spell', label = 'Single spell' },
    { id = 'import', label = 'Import list' },
}

local function draw_run_mode_controls()
    local modeLabel = 'Class batch'
    for _, m in ipairs(RUN_MODES) do
        if m.id == state.runMode then modeLabel = m.label; break end
    end
    if ImGui.BeginCombo('Run mode##rl_mode', modeLabel) then
        for _, m in ipairs(RUN_MODES) do
            if ImGui.Selectable(m.label .. '##rl_mode_' .. m.id, state.runMode == m.id) then
                if state.runMode ~= m.id then
                    state.runMode = m.id
                    state.planKey = ''
                    if m.id == 'import' then
                        state.importScanAt = nil
                        ensure_import_ready(true)
                    end
                end
            end
        end
        ImGui.EndCombo()
    end

    if state.runMode == 'spell' then
        state.spellName = ImGui.InputText('Spell name##rl_spell', state.spellName, 128)
        ImGui.TextDisabled('Example: Panoply of Vie')
        ImGui.TextDisabled('Copies = scrolls to craft (scribed does not block Start)')
    elseif state.runMode == 'import' then
        ImGui.TextDisabled('Friend: /lua run ResearchLearnExport (single file, no setup)')
        ImGui.TextDisabled('You: drop file in MacroQuest/Config/, pick list, Start')

        local files = state.importFiles or {}
        if ImGui.Button('Refresh##rl_import_refresh', 70, UI.btn_h) then
            ensure_import_ready(true)
            files = state.importFiles or {}
            set_status(string.format('Found %d import file(s).', #files))
        end
        ImGui.SameLine()
        local keepPath = (files[state.importListIndex] or {}).path or state.importPath
        local canClean = #files > 1
        if themed_button('Clean old##rl_import_clean', UI.amber, 78, UI.btn_h, not canClean) then
            local removed = clean_old_want_lists(keepPath)
            files = state.importFiles or {}
            if removed > 0 then
                set_status(string.format('Removed %d old want list(s). Kept current selection.', removed))
            else
                set_status('No other want lists to remove.')
            end
        end
        if canClean then
            ImGui.SameLine()
            ImGui.TextDisabled('Keeps selected list')
        end

        local pickLabel = 'No import files in Config/'
        if #files > 0 then
            if state.importListIndex < 1 or state.importListIndex > #files then
                state.importListIndex = pick_best_import_index(files)
            end
            pickLabel = import_list_label(files[state.importListIndex])
        elseif not state.importScanAt then
            ensure_import_ready(true)
            files = state.importFiles or {}
            if #files > 0 then
                state.importListIndex = pick_best_import_index(files)
                pickLabel = import_list_label(files[state.importListIndex])
            end
        end

        if ImGui.BeginCombo('Want list##rl_import_pick', pickLabel) then
            for i, f in ipairs(files) do
                if ImGui.Selectable(import_list_label(f) .. '##rl_imp_' .. i, state.importListIndex == i) then
                    if select_import_file(i) then
                        set_status(string.format('Loaded %d spells for %s.', f.spellCount or 0, f.meta.character or f.fname))
                    end
                end
            end
            ImGui.EndCombo()
        end

        local meta = state.importMeta or {}
        local n = state.importEntries and #state.importEntries or 0
        if n > 0 then
            ImGui.Text(string.format('Ready: %d spells for %s (%s)', n, meta.character or '?', meta.class or '?'))
        elseif #files == 0 then
            ImGui.TextColored(0.95, 0.45, 0.35, 1.0, 'No ResearchLearn_want_*.txt files in config yet.')
        end

        if ImGui.CollapsingHeader('Advanced: file path') then
            state.importPath = ImGui.InputText('Path##rl_import', state.importPath, 256)
            if ImGui.Button('Load path##rl_load_path', 80, UI.btn_h) then
                load_import_entries()
                set_status(string.format('Loaded %d spells from file.', #(state.importEntries or {})))
            end
        end
    else
        if ImGui.BeginCombo('Class##rl_class', state.classes[state.classIndex + 1] or 'cleric') then
            for i, cls in ipairs(state.classes) do
                if ImGui.Selectable(cls .. '##rl_cls_' .. i, state.classIndex == i - 1) then
                    state.classIndex = i - 1
                    state.planKey = ''
                end
            end
            ImGui.EndCombo()
        end

        if ImGui.BeginCombo('Level##rl_level', LEVELS[state.levelIndex + 1] or 'all') then
            for i, lvl in ipairs(LEVELS) do
                if ImGui.Selectable(lvl .. '##rl_lvl_' .. i, state.levelIndex == i - 1) then
                    state.levelIndex = i - 1
                    state.planKey = ''
                end
            end
            ImGui.EndCombo()
        end
    end

    if state.runMode ~= 'import' then
        local qtyBuf = tostring(state.quantity)
        qtyBuf = ImGui.InputText('Copies##rl_qty', qtyBuf, 8)
        local qn = tonumber(trim(qtyBuf))
        if qn and qn >= 1 then
            if qn ~= state.quantity then state.planKey = '' end
            state.quantity = math.floor(qn)
        end
    end

    if state.runMode == 'class' then
        local ro = state.researchOnly
        local roChk = ImGui.Checkbox('Research only (hide drop/Anguish/library)', ro)
        if roChk ~= nil then
            if roChk ~= ro then state.planKey = '' end
            state.researchOnly = roChk
        end

        local ho = state.hideOwned
        local hoChk = ImGui.Checkbox('Hide satisfied spells', ho)
        if hoChk ~= nil then
            if hoChk ~= ho then state.planKey = '' end
            state.hideOwned = hoChk
        end
    end
end

local function draw_skill_up()
    if not ImGui.CollapsingHeader('Skill-up (Pack10 combines)') then return end

    local skill = research_skill()
    ImGui.Text(string.format('Research skill: %d / %d', skill, RESEARCH_SKILL_CAP))

    for i, t in ipairs(SKILL_TIERS) do
        local done = skill >= (t.trivial or 0)
        if done then
            ImGui.TextColored(0.45, 0.85, 0.45, 1.0, string.format('  %s - trivial (%d)', t.label, t.trivial))
        elseif i == 1 or skill >= (SKILL_TIERS[i - 1].trivial or 0) then
            ImGui.TextColored(0.95, 0.85, 0.35, 1.0, string.format('  %s - active until %d', t.label, t.trivial))
        else
            ImGui.TextDisabled(string.format('  %s - trivial %d', t.label, t.trivial))
        end
    end

    local recTier, recId = recommended_skill_tier(skill)
    if state.skillTierIndex == 0 then
        if skill >= RESEARCH_SKILL_CAP then
            ImGui.TextColored(0.45, 0.85, 0.45, 1.0, 'Research skill capped — Pack10 skill-up not needed.')
        elseif recTier then
            ImGui.Text(string.format('Auto will use: %s', recTier.label))
        else
            ImGui.TextColored(0.45, 0.85, 0.45, 1.0, 'All Pack10 tiers are trivial at your skill.')
        end
    end

    local comboLabel = skill_tier_label(state.skillTierIndex)
    if ImGui.BeginCombo('Mode##rl_skill', comboLabel) then
        if ImGui.Selectable('Auto (advance when trivial)##rl_skill_auto', state.skillTierIndex == 0) then
            state.skillTierIndex = 0
        end
        for i, t in ipairs(SKILL_TIERS) do
            if ImGui.Selectable(string.format('%s (trivial %d)##rl_skill_%s', t.label, t.trivial, t.id), state.skillTierIndex == i) then
                state.skillTierIndex = i
            end
        end
        ImGui.EndCombo()
    end

    local displayTier = active_skill_tier()
    if displayTier then
        ImGui.TextWrapped(string.format('Open Pack10 container. Ingredients for %s:', displayTier.label))

        if ImGui.BeginTable('##rl_skill_ing', 2, ImGuiTableFlags.Borders or 0, 0, 0) then
            ImGui.TableSetupColumn('Ingredient', ImGuiTableColumnFlags.WidthStretch)
            ImGui.TableSetupColumn('Have', ImGuiTableColumnFlags.WidthFixed, 48)
            ImGui.TableHeadersRow()
            for _, itemName in ipairs(displayTier.items) do
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.Text(itemName)
                ImGui.TableNextColumn()
                ImGui.Text(string.format('%d', item_count(itemName)))
            end
            ImGui.EndTable()
        end
    end

    local skillBusy = skill_macro_running()
    local canStart = not skillBusy and not any_macro_running()
    if state.skillTierIndex == 0 and (not recTier or skill >= RESEARCH_SKILL_CAP) then canStart = false end
    if themed_button('Start skill-up##rl_skill_start', UI.green, 120, UI.btn_h, not canStart) then
        run_skill_start()
    end
    ImGui.SameLine()
    ImGui.TextDisabled(string.format('/mac %s auto', SKILL_MACRO))
end

local function render_window()
    if not state.windowOpen then return end

    if not state.sizeSet and ImGui.SetNextWindowSize then
        pcall(ImGui.SetNextWindowSize, 600, 720, ImGuiCond.FirstUseEver or 1)
        state.sizeSet = true
    end

    local flags = begin_window_flags()
    local styleVars, styleCols = push_ui_style()
    local open, shouldDraw = ImGui.Begin('Research Learn###researchlearn_ui', state.windowOpen, flags)
    state.windowOpen = open
    if shouldDraw == nil then shouldDraw = open end

    if shouldDraw then
        local ok, err = pcall(function()
            draw_preflight()
            ImGui.Separator()

            draw_run_mode_controls()

            ImGui.Separator()

            local plan = get_plan(false)
            draw_summary_line(plan)
            draw_manifest(plan)
            draw_ingredients(plan)

            ImGui.Separator()
            draw_skill_up()

            ImGui.Separator()

            local blocked = any_macro_running() or state.importRunning or not plan.canStart
            if themed_button('Start##rl_start', UI.green, UI.btn_w, UI.btn_h, blocked) then run_start() end
            ImGui.SameLine()
            if themed_button('Doctor##rl_doc', UI.blue, UI.btn_w, UI.btn_h) then run_doctor() end
            ImGui.SameLine()
            if themed_button('Stop##rl_stop', UI.red, UI.btn_w, UI.btn_h) then run_stop() end
            ImGui.SameLine()
            if ImGui.Button('Refresh##rl_ref', UI.btn_w, UI.btn_h) then
                state.planKey = ''
                get_plan(true)
            end

            if state.statusMsg ~= '' then
                ImGui.Spacing()
                ImGui.TextWrapped(state.statusMsg)
            end

            ImGui.Spacing()
            ImGui.TextDisabled('/rlui toggle | Friend export: /lua run ResearchLearnExport')
        end)
        if not ok then
            ImGui.TextColored(0.95, 0.35, 0.35, 1.0, 'UI error: ' .. tostring(err))
        end
    end

    ImGui.End()
    pop_ui_style(styleVars, styleCols)
end

local function ui_command(...)
    local arg = trim(({ ... })[1] or ''):lower()
    if arg == 'stop' then
        run_stop()
    elseif arg == 'doctor' or arg == 'doc' then
        run_doctor()
    elseif arg == 'hide' or arg == 'close' then
        state.windowOpen = false
    elseif arg == 'show' or arg == 'open' then
        state.windowOpen = true
    elseif arg == 'toggle' then
        state.windowOpen = not state.windowOpen
    else
        state.windowOpen = true
    end
end

local cliArg = trim(({ ... })[1] or ''):lower()
load_config()

if cliArg == 'doctor' or cliArg == 'doc' then
    run_doctor()
    return
end

if cliArg == 'toggle' then
elseif cliArg == 'hide' or cliArg == 'close' then
    state.windowOpen = false
elseif cliArg ~= '' and cliArg ~= 'show' and cliArg ~= 'open' then
    printf('\ay[ResearchLearn]\ax Unknown arg "%s" - opening UI.', cliArg)
end

pcall(function() mq.bind('/rlui', ui_command) end)
pcall(function() mq.bind('/researchlearnui', ui_command) end)

mq.imgui.init(scriptName, render_window)
printf('\ag[ResearchLearn]\ax UI open - \ay/lua run ResearchLearn\ax or \ay/rlui toggle\ax')

while state.windowOpen do
    tick_import_queue()
    mq.delay(10)
end

pcall(function() mq.unbind('/rlui') end)
pcall(function() mq.unbind('/researchlearnui') end)
mq.imgui.destroy(scriptName)
printf('\ag[ResearchLearn]\ax UI closed.')
