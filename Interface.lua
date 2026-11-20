local _, addon = ...

local display, selectedSeal, optionsID, preview
local moving = false
local solid = "Interface\\Buttons\\WHITE8X8"
local wingTexture = "Interface\\AddOns\\AlexIra\\Media\\Wings.tga"
local anchors = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local function SealTexture(seal)
    return addon.Public(C_Spell.GetSpellTexture(seal.spell)) or 134400
end

local function PaintCharges(seal, count)
    local red, green, blue = unpack(seal.color)
    local ready = count == addon.maxStacks
    display.count:SetText(string.format("%d / %d", count, addon.maxStacks))
    if ready then
        display.crest:SetBackdropBorderColor(1, 0.78, 0.36)
        display.count:SetTextColor(1, 0.86, 0.50)
    else
        display.crest:SetBackdropBorderColor(0.50, 0.36, 0.19)
        display.count:SetTextColor(0.97, 0.90, 0.76)
    end
    for index, charge in ipairs(display.charges) do
        if index <= count then
            charge.fill:SetColorTexture(red, green, blue, ready and 1 or 0.85)
            charge.shine:SetColorTexture(1, 0.96, 0.82, ready and 0.95 or 0.57)
        else
            charge.fill:SetColorTexture(0.15, 0.11, 0.08, 1)
            charge.shine:SetColorTexture(0.39, 0.29, 0.15, 1)
        end
    end
end

function addon.Render()
    if not display then return end
    local tracker, now = addon.tracker, GetTime()
    tracker:Expire(now)
    if preview and now >= preview.expires then preview = nil end
    local state = preview or (tracker.seal and tracker)
    if not state and not moving then
        display.readySince = nil
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
    local ready = count == addon.maxStacks
    local changedSeal = display.spell ~= seal.spell
    if changedSeal then
        display.spell = seal.spell
        display.icon:SetTexture(SealTexture(seal))
        display.title:SetText(addon.SealName(seal))
    end
    if changedSeal or display.lastCount ~= count then
        display.lastCount = count
        PaintCharges(seal, count)
        display.readySince = nil
    end
    if ready then
        display.readySince = display.readySince or now
        local flash = math.max(0, 1 - (now - display.readySince) / 0.75)
        display.wings:SetAlpha(0.79 + 0.21 * flash)
    else
        display.wings:SetAlpha(0.30 + 0.16 * count)
    end
    if preview then
        display.status:SetText("Teste de alerta")
    elseif state then
        local remaining = math.max(0, state.expires - now)
        local prefix = state.estimated and "Estimativa · " or (ready and "Troque o selo · " or "")
        display.status:SetText(string.format("%s%.1f s", prefix, remaining))
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
    display = CreateFrame("Frame", "AlexIraDisplay", UIParent)
    display:SetSize(366, 122)
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

    display.wings = display:CreateTexture(nil, "BACKGROUND")
    display.wings:SetAllPoints(display)
    display.wings:SetTexture(wingTexture)
    display.wings:SetTexCoord(0, 1, 42 / 256, 214 / 256)

    local crest = CreateFrame("Frame", nil, display, "BackdropTemplate")
    crest:SetSize(166, 86)
    crest:SetPoint("CENTER", 0, -7)
    crest:SetBackdrop({ bgFile = solid, edgeFile = solid, edgeSize = 1 })
    crest:SetBackdropColor(0.052, 0.037, 0.022, 0.98)
    display.crest = crest

    display.icon = crest:CreateTexture(nil, "ARTWORK")
    display.icon:SetPoint("TOPLEFT", 9, -8)
    display.icon:SetSize(19, 19)
    display.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    display.title = Label(crest, "GameFontNormal", "", 34, -10)
    display.title:SetWidth(125)
    display.title:SetJustifyH("LEFT")
    display.title:SetWordWrap(false)
    display.count = crest:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    display.count:SetPoint("TOP", 0, -28)
    display.status = crest:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    display.status:SetPoint("BOTTOM", 0, 8)
    display.charges = {}
    for index = 1, addon.maxStacks do
        local frame = crest:CreateTexture(nil, "BORDER")
        frame:SetColorTexture(0.37, 0.26, 0.14, 1)
        frame:SetSize(44, 9)
        frame:SetPoint("TOPLEFT", 11 + (index - 1) * 50, -51)
        local fill = crest:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        local shine = crest:CreateTexture(nil, "OVERLAY")
        shine:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, 0)
        shine:SetPoint("TOPRIGHT", fill, "TOPRIGHT", -1, 0)
        shine:SetHeight(1)
        display.charges[index] = { fill = fill, shine = shine }
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
    return button
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
    Label(panel, "GameFontHighlight", "Selecione um selo para configurar seus três alertas.", 24, -58)

    local sealButtons, soundMenus = {}, {}
    local sealHeading = Label(panel, "GameFontNormal", "", 24, -205)
    local function SelectSeal(seal)
        selectedSeal = seal
        preview = nil
        sealHeading:SetText(addon.SealName(seal))
        for _, button in ipairs(sealButtons) do
            if button.seal == seal then
                button:LockHighlight()
                button.label:SetTextColor(1, 0.83, 0.46)
            else
                button:UnlockHighlight()
                button.label:SetTextColor(0.94, 0.90, 0.83)
            end
        end
        for _, dropdown in ipairs(soundMenus) do
            dropdown:GenerateMenu()
        end
        addon.Render()
    end

    for _, seal in ipairs(addon.seals) do
        if seal.echo then
            local index = #sealButtons
            local x = 24 + (index % 2) * 204
            local y = -85 - math.floor(index / 2) * 35
            local button = Button(panel, "", 194, x, y, function(self) SelectSeal(self.seal) end)
            button:SetHeight(29)
            button.seal = seal
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetSize(19, 19)
            icon:SetPoint("LEFT", 7, 0)
            icon:SetTexture(SealTexture(seal))
            button.label = Label(button, "GameFontHighlight", addon.SealName(seal), 34, -8)
            button.label:SetWidth(153)
            button.label:SetWordWrap(false)
            button.label:SetJustifyH("LEFT")
            sealButtons[#sealButtons + 1] = button
        end
    end

    for count = 1, addon.maxStacks do
        local y = -231 - (count - 1) * 35
        Label(panel, "GameFontHighlight", count == 1 and "1 acúmulo" or count .. " acúmulos", 24, y - 6)
        local dropdown = Dropdown(panel, 222, 122, y)
        dropdown:SetupMenu(function(_, menu)
            local choices = addon.db.sounds[selectedSeal.echo]
            menu:SetScrollMode(280)
            for _, sound in ipairs(addon.sounds) do
                menu:CreateRadio(sound.name, function(id)
                    return choices[count] == id
                end, function(id)
                    choices[count] = id
                end, sound.id)
            end
        end)
        soundMenus[count] = dropdown
        Button(panel, "Testar", 68, 354, y, function()
            preview = { seal = selectedSeal, count = count, expires = GetTime() + 4 }
            display.readySince = nil
            addon.PlayAlert(selectedSeal, count)
            addon.Render()
        end)
    end
    SelectSeal(selectedSeal)

    local move = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    move:SetPoint("TOPLEFT", 21, -351)
    Label(panel, "GameFontHighlight", "Mover indicador", 52, -361)
    move:SetScript("OnClick", function(self)
        moving = self:GetChecked()
        display:EnableMouse(moving)
        addon.Render()
    end)
    Button(panel, "Restaurar posição", 146, 180, -355, ResetPosition)
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
