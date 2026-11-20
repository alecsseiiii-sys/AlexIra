local _, addon = ...

local display, selectedSeal, optionsID, preview
local moving = false
local anchors = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

function addon.Render()
    if not display then return end
    local tracker, now = addon.tracker, GetTime()
    tracker:Expire(now)
    if preview and now >= preview.expires then preview = nil end
    local state = preview or (tracker.seal and tracker)
    if not state and not moving then
        display:Hide()
        return
    end

    local strata = (moving or preview) and "FULLSCREEN_DIALOG" or "MEDIUM"
    if display.strata ~= strata then
        display.strata = strata
        display:SetFrameStrata(strata)
    end
    local seal = state and state.seal or selectedSeal
    local count = state and state.count or 0
    local red, green, blue = unpack(seal.color)
    local ready = count == addon.maxStacks
    if display.spell ~= seal.spell then
        display.spell = seal.spell
        display.icon:SetTexture(addon.Public(C_Spell.GetSpellTexture(seal.spell)) or 134400)
        display.title:SetText(addon.SealName(seal))
    end
    display:SetBackdropBorderColor(ready and red or 0.30, ready and green or 0.23, ready and blue or 0.15)
    for index, segment in ipairs(display.segments) do
        if index <= count then
            segment:SetColorTexture(red, green, blue, ready and 1 or 0.85)
        else
            segment:SetColorTexture(0.30, 0.25, 0.20, 0.53)
        end
    end
    display.count:SetText(string.format("%d / %d", count, addon.maxStacks))
    if preview then
        display.status:SetText("Teste de alerta")
    elseif state then
        local remaining = math.max(0, state.expires - now)
        display.status:SetText(string.format("%s%.1f s", state.estimated and "Estimativa · " or "", remaining))
    else
        display.status:SetText("Arraste para mover")
    end
    display:Show()
end

local function Label(parent, style, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", style)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function ResetPosition()
    addon.db.position = nil
    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, "CENTER", 0, -154)
end

local function BuildDisplay()
    display = CreateFrame("Frame", "AlexIraDisplay", UIParent, "BackdropTemplate")
    display:SetSize(242, 70)
    display:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    display:SetBackdropColor(0.085, 0.067, 0.055, 0.94)
    display:SetMovable(true)
    display:SetClampedToScreen(true)
    display:EnableMouse(false)
    display:RegisterForDrag("LeftButton")
    display:SetScript("OnDragStart", function(self)
        if moving then self:StartMoving() end
    end)
    display:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
        local point, _, relativePoint, x, y = self:GetPoint()
        addon.db.position = { point, relativePoint, x, y }
    end)
    local position = addon.db.position
    if type(position) == "table" and anchors[position[1]] and anchors[position[2]]
        and type(position[3]) == "number" and type(position[4]) == "number" then
        display:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else
        ResetPosition()
    end

    display.icon = display:CreateTexture(nil, "ARTWORK")
    display.icon:SetPoint("TOPLEFT", 10, -11)
    display.icon:SetSize(44, 44)
    display.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    display.title = Label(display, "GameFontNormal", "", 63, -10)
    display.title:SetWidth(124)
    display.title:SetJustifyH("LEFT")
    display.title:SetWordWrap(false)
    display.count = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    display.count:SetPoint("TOPRIGHT", -10, -8)
    display.status = Label(display, "GameFontHighlightSmall", "", 63, -48)
    display.segments = {}
    for index = 1, addon.maxStacks do
        local segment = display:CreateTexture(nil, "ARTWORK")
        segment:SetSize(53, 10)
        segment:SetPoint("TOPLEFT", 63 + (index - 1) * 58, -31)
        display.segments[index] = segment
    end
    local accumulated = 0
    display:SetScript("OnUpdate", function(_, elapsed)
        accumulated = accumulated + elapsed
        if accumulated >= 0.1 then
            accumulated = 0
            addon.Render()
        end
    end)
    display:Hide()
end

local function Button(parent, text, width, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
end

local function Dropdown(parent, width, x, y)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    dropdown:SetSize(width, 26)
    return dropdown
end

local function BuildOptions()
    local panel = CreateFrame("Frame")
    Label(panel, "GameFontNormalHuge", "AlexIra", 24, -22)
    Label(panel, "GameFontHighlight", "Escolha o alerta de cada acúmulo da Ira Desatada.", 24, -62)
    Label(panel, "GameFontNormal", "Selo", 24, -109)

    local soundMenus = {}
    local sealMenu = Dropdown(panel, 222, 122, -102)
    sealMenu:SetupMenu(function(_, menu)
        for _, seal in ipairs(addon.seals) do
            if seal.echo then
                menu:CreateRadio(addon.SealName(seal), function(value)
                    return selectedSeal == value
                end, function(value)
                    selectedSeal = value
                    preview = nil
                    for _, dropdown in ipairs(soundMenus) do dropdown:GenerateMenu() end
                    addon.Render()
                end, seal)
            end
        end
    end)

    for count = 1, addon.maxStacks do
        local y = -148 - (count - 1) * 35
        Label(panel, "GameFontHighlight", count == 1 and "1 acúmulo" or count .. " acúmulos", 24, y - 6)
        local dropdown = Dropdown(panel, 222, 122, y)
        dropdown:SetupMenu(function(_, menu)
            for _, sound in ipairs(addon.sounds) do
                menu:CreateRadio(sound.name, function(id)
                    return addon.db.sounds[selectedSeal.echo][count] == id
                end, function(id)
                    addon.db.sounds[selectedSeal.echo][count] = id
                end, sound.id)
            end
        end)
        soundMenus[count] = dropdown
        Button(panel, "Testar", 68, 354, y, function()
            preview = { seal = selectedSeal, count = count, expires = GetTime() + 4 }
            addon.PlayAlert(selectedSeal, count)
            addon.Render()
        end)
    end

    local move = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    move:SetPoint("TOPLEFT", 21, -271)
    Label(panel, "GameFontHighlight", "Mover indicador", 52, -281)
    move:SetScript("OnClick", function(self)
        moving = self:GetChecked()
        display:EnableMouse(moving)
        addon.Render()
    end)
    Button(panel, "Restaurar posição", 146, 180, -275, ResetPosition)
    panel:SetScript("OnHide", function()
        moving = false
        move:SetChecked(false)
        display:EnableMouse(false)
        addon.Render()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "AlexIra")
    Settings.RegisterAddOnCategory(category)
    optionsID = category:GetID()
end

function addon.CreateUI()
    selectedSeal = addon.seals[1]
    BuildDisplay()
    BuildOptions()
    SLASH_ALEXIRA1 = "/alexira"
    SlashCmdList.ALEXIRA = function() Settings.OpenToCategory(optionsID) end
end
