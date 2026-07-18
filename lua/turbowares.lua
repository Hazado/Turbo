--[[
  turbowares.lua — standalone TurboWares merchant companion
  ----------------------------------------------------------
  Shows the TurboWares sidecar when MerchantWnd is open WITHOUT requiring
  the full Turbo hub UI. Intended for boxes that run turbogear_bg (or
  nothing) but still want merchant sell/watch tooling.

  /lua run turbowares
  /turbowares          — toggle auto-show (when hub is NOT running)
  /turbowares stop     — exit companion

  Coexistence: if Lua.Script[Turbo] is running, this companion draws
  nothing so the hub's sidecar owns the merchant UI.

  @version lua/turbowares.lua 1.0.0
]]

local mq = require('mq')
local Paths = require('Turbo.paths')
local Theme = require('Turbo.theme')
local Ui = require('Turbo.ui.components')
local ShellOpen = require('Turbo.shell_open')
local IniIo = require('Turbo.ini_io')
local TurbolootPath = require('Turbo.turboloot_path')
local Wares = require('Turbo.wares')
local WaresSidecar = require('Turbo.ui.wares_sidecar')

local SCRIPT_IMGUI = 'TurboWaresCompanion'
local TAG = '\at[TurboWares]\ax '
local running = true
local claimedTurbowaresBind = false

local g = {
    -- Hub layout stubs (SELL NOW restoreUi may write these; keep harmless).
    windowOpen = false,
    slimGUI = false,
    minimizedGUI = false,
    slimWhenExpanded = false,
    x = 0,
    y = 0,
    statusMessage = '',
    profileList = {},

    waresAutoShow = true,
    waresWindowOpen = false,
    waresWindowWidth = 440,
    waresTab = 'items',
    waresRequestedTab = nil,
    waresBuyQty = 1,
    waresSearchItems = '',
    waresSearchMerchant = '',
    waresFilterSellable = false,
    waresHideEmptyStacks = true,
    waresSelectedKey = nil,
    waresMerchantSelectedKey = nil,
    waresWatchDraft = '',
    waresIniTargetOverride = nil,
    waresIniTargetPath = nil,
    waresIniTargetProfile = nil,
    waresSellInProgress = false,
    waresPendingSellNow = nil,
    waresPendingSellStackNow = nil,
    waresPendingBuyNow = nil,
    _waresInvRows = nil,
    _waresMerchRows = nil,
    _waresQtyMap = nil,
    _waresWatchHits = nil,
    _waresInvalidateSellCache = nil,
    _waresInvalidateMerchantCache = nil,
}

local function printf(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    print(TAG .. (ok and msg or tostring(fmt)))
end

local function scriptRunning(name)
    local ok, status = pcall(function()
        return tostring(mq.TLO.Lua.Script(name).Status() or '')
    end)
    if not ok then return false end
    status = status:lower()
    if status:find('not', 1, true) or status:find('stop', 1, true)
        or status:find('end', 1, true) then
        return false
    end
    return status:find('running', 1, true) ~= nil or status == 'run'
end

--- Full Turbo hub owns its own wares sidecar — never double-draw.
local function hubOwnsWares()
    return scriptRunning('Turbo') or scriptRunning('turbo')
end

local function settingsPath()
    local char = tostring(mq.TLO.Me.CleanName() or mq.TLO.Me.Name() or 'unknown')
        :match('^%s*(.-)%s*$') or 'unknown'
    char = char:gsub('[^%w_%-]', '_')
    return Paths.state_file('turbowares_' .. char .. '.lua')
        or Paths.config_file('turbowares_' .. char .. '.lua')
end

local function loadSettings()
    local path = settingsPath()
    if not path then return end
    local ok, tbl = pcall(function()
        local chunk = loadfile(path)
        if not chunk then return nil end
        local result = chunk()
        return type(result) == 'table' and result or nil
    end)
    if ok and type(tbl) == 'table' then
        if tbl.waresAutoShow ~= nil then g.waresAutoShow = tbl.waresAutoShow ~= false end
        if tonumber(tbl.waresWindowWidth) then
            g.waresWindowWidth = math.max(400, math.floor(tonumber(tbl.waresWindowWidth)))
        end
        if type(tbl.waresIniTargetOverride) == 'string' and tbl.waresIniTargetOverride ~= '' then
            g.waresIniTargetOverride = tbl.waresIniTargetOverride
        end
    end
end

local function saveSettings()
    local path = settingsPath()
    if not path then return end
    local f = io.open(path, 'w')
    if not f then return end
    f:write('return {\n')
    f:write(string.format('  waresAutoShow = %s,\n', tostring(g.waresAutoShow ~= false)))
    f:write(string.format('  waresWindowWidth = %d,\n', math.floor(tonumber(g.waresWindowWidth) or 440)))
    if g.waresIniTargetOverride and g.waresIniTargetOverride ~= '' then
        f:write(string.format('  waresIniTargetOverride = %q,\n', tostring(g.waresIniTargetOverride)))
    end
    f:write('}\n')
    f:close()
end

local function refreshProfileList()
    g.profileList = TurbolootPath.listProfileNames()
end

local function getActiveProfile()
    return TurbolootPath.resolveActiveProfileName()
end

local function setupSidecar()
    WaresSidecar.setup({
        Ui = Ui,
        Theme = Theme,
        TurboKeyRGB = (Theme.col and Theme.col.turboKeyRGB) or {},
        ACTION_BTN_H = 24,
        writeIniKey = IniIo.writeIniKey,
        readIniKey = IniIo.readIniKey,
        readIniSectionPairs = IniIo.readIniSectionPairs,
        deleteIniKey = IniIo.deleteIniKey,
        resolveTurbolootIniPathForProfile = TurbolootPath.resolveTurbolootIniPathForProfile,
        cleanProfileName = TurbolootPath.cleanProfileName,
        shellOpenFile = function(path, args)
            return ShellOpen.shellOpenFile(path, args)
        end,
        getActiveProfile = getActiveProfile,
        openAllaItemPage = function(itemId)
            itemId = tonumber(itemId)
            if not itemId or itemId <= 0 then return end
            local base = 'https://www.eqprogression.com/alla/?a=item&id='
            if ShellOpen.openAllaPage then
                pcall(function() ShellOpen.openAllaPage(base, itemId) end)
            else
                pcall(function() ShellOpen.shellOpenUrl(base .. tostring(itemId)) end)
            end
        end,
        -- No hub shared-control lease when standalone; allow rule writes.
        -- When hub is present we never draw, so this stub is unused.
        canSharedControlWrite = function() return true end,
        requireSharedControl = function() return true end,
        creditGainsSale = function() return false end,
        saveSettings = saveSettings,
    })
end

local function render()
    if not running then return end
    if hubOwnsWares() then return end
    if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then return end
    WaresSidecar.render(g)
end

local function handleCommand(...)
    local args = { ... }
    local sub = tostring(args[1] or ''):lower():match('^%s*(.-)%s*$') or ''
    if sub == 'stop' or sub == 'quit' or sub == 'exit' then
        running = false
        printf('stopping.')
        return
    end
    if sub == 'status' then
        printf('autoShow=%s hub=%s activeIni=%s',
            tostring(g.waresAutoShow ~= false),
            hubOwnsWares() and 'yes' or 'no',
            tostring(getActiveProfile()))
        return
    end
    if sub == 'help' then
        printf('commands: (no arg)=toggle auto-show | status | stop')
        return
    end
    -- Default: toggle auto-show (mirrors hub /turbowares).
    g.waresAutoShow = not (g.waresAutoShow ~= false)
    if g.waresAutoShow then g.waresWindowOpen = true end
    saveSettings()
    printf('auto-show at merchants: %s', g.waresAutoShow and 'ON' or 'OFF')
end

local function syncTurbowaresBind()
    -- Only claim /turbowares when the hub is absent so we don't steal its bind.
    if hubOwnsWares() then
        if claimedTurbowaresBind then
            pcall(function() mq.unbind('/turbowares') end)
            claimedTurbowaresBind = false
        end
        return
    end
    if not claimedTurbowaresBind then
        local ok = pcall(function() mq.bind('/turbowares', handleCommand) end)
        claimedTurbowaresBind = ok == true
    end
end

local function boot()
    loadSettings()
    refreshProfileList()
    setupSidecar()
    pcall(function() mq.bind('/twcompanion', handleCommand) end)
    syncTurbowaresBind()
    mq.imgui.init(SCRIPT_IMGUI, render)
    local active = getActiveProfile()
    local path = TurbolootPath.resolveTurbolootIniPathForProfile(active)
    printf('online - active INI \\ag%s\\ax (%s). Open a vendor to show TurboWares.',
        tostring(active), tostring(path or '?'))
    if hubOwnsWares() then
        printf('Turbo hub is running - companion will not draw (hub owns wares). Use /twcompanion.')
    elseif g.waresAutoShow == false then
        printf('auto-show is OFF - /turbowares to enable.')
    end
end

boot()

while running do
    syncTurbowaresBind()
    if not hubOwnsWares() then
        -- Non-negotiable: execute queued SELL NOW / BUY NOW outside ImGui.
        pcall(function() Wares.processPendingActions(g) end)
    end
    mq.delay(150)
end

pcall(function() mq.unbind('/turbowares') end)
pcall(function() mq.unbind('/twcompanion') end)
pcall(function() mq.imgui.destroy(SCRIPT_IMGUI) end)
printf('stopped.')
