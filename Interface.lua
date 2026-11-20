local _, addon = ...

local display, swingBar, selectedSeal, optionsID, preview
local moving = false
local solid = "Interface\\Buttons\\WHITE8X8"
local wingTexture = "Interface\\AddOns\\AlexIra\\Media\\Wings.tga"
local anchors = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local layouts = {
    wings = {
        width = 366, height = 122, plate = { 166, 86, -7 },
        icon = { 9, -8, 19 }, title = { 34, -10, 125 }, number = { 76, -28 }, status = { 83, -68 },
        charges = { x = 11, y = -51, w = 44, h = 9, dx = 50, dy = 0 },
    },
    simple = {
        width = 178, height = 40, plate = { 178, 40, 0 },
        icon = { 7, -8, 24 }, title = { 37, -5, 99 }, number = { 151, -10 }, status = { 84, -22 },
    },
    relic = {
        width = 187, height = 67, plate = { 187, 67, 0 },
        icon = { 9, -11, 37 }, title = { 55, -8, 123 }, number = { 147, -27 }, status = { 123, -49 },
        gilded = true, charges = { x = 55, y = -29, w = 17, h = 15, dx = 21, dy = 0, lead = true },
    },
    glass = {
        width = 142, height = 127, plate = { 142, 127, 0 },
        icon = { 79, -28, 35 }, title = { 10, -9, 122 }, number = { 96, -69 }, status = { 71, -108 },
        charges = { x = 18, y = -78, w = 36, h = 20, dx = 0, dy = 24, lead = true },
    },
}

local function SealTexture(seal)
    return addon.Public(C_Spell.GetSpellTexture(seal.spell)) or 134400
end

local function PaintCharges(face, seal, count)
    local red, green, blue = unpack(seal.color)
    local ready = count == addon.maxStacks
    if ready then
        face:SetBackdropBorderColor(1, 0.78, 0.36)
        face.count:SetTextColor(1, 0.86, 0.50)
    else
        face:SetBackdropBorderColor(0.50, 0.36, 0.19)
        face.count:SetTextColor(0.97, 0.90, 0.76)
    end
    for index, charge in ipairs(face.charges) do
        if index <= count then
            charge.fill:SetColorTexture(red, green, blue, ready and 1 or 0.85)
            charge.shine:SetColorTexture(1, 0.96, 0.82, ready and 0.95 or 0.57)
        else
            charge.fill:SetColorTexture(0.15, 0.11, 0.08, 1)
            charge.shine:SetColorTexture(0.39, 0.29, 0.15, 1)
        end
    end
end

local function RenderSwingTimer(now)
    local timer = addon.swingTimer
    local flash = timer.at and now < timer.at + 0.4
    local counting = timer.endsAt and now < timer.endsAt + 0.4
    local sample = not flash and not counting and (preview or moving)
    if not addon.db.showSwingTimer or not (flash or counting or sample) then
        swingBar:Hide()
        return
    end

    local strata = (moving or preview) and "FULLSCREEN_DIALOG" or "MEDIUM"
    if swingBar.strata ~= strata then
        swingBar.strata = strata
        swingBar:SetFrameStrata(strata)
    end
    local remaining = counting and math.max(0, timer.endsAt - now)
    local progress = remaining and math.max(0, 1 - remaining / timer.period)
    swingBar.progress:SetValue(progress or (sample and 0.55 or 0))
    swingBar.time:SetText(remaining and string.format("%.1f s", remaining) or (sample and "Prévia" or ""))
    swingBar.flash:SetShown(flash == true)
    if flash then
        swingBar:SetBackdropBorderColor(1, 0.82, 0.4)
        swingBar.title:SetTextColor(1, 0.86, 0.47)
    else
        swingBar:SetBackdropBorderColor(0.48, 0.37, 0.21)
        swingBar.title:SetTextColor(0.96, 0.90, 0.78)
    end
    swingBar:Show()
end

function addon.Render()
    if not display then return end
    local tracker, now = addon.tracker, GetTime()
    tracker:Expire(now)
    local live = addon.GetSwingProjection(now) or tracker
    if preview and (now >= preview.expires or (preview.appearance and live.seal)) then
        preview = nil
    end
    RenderSwingTimer(now)
    local state = preview or (live.seal and live)
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
    local face = display.face
    local changedSeal = face.spell ~= seal.spell
    if changedSeal then
        face.spell = seal.spell
        face.icon:SetTexture(SealTexture(seal))
        face.title:SetText(addon.SealName(seal))
    end
    if changedSeal or face.lastCount ~= count then
        face.lastCount = count
        PaintCharges(face, seal, count)
        display.readySince = nil
    end
    local ok, nativeCount
    if state == live then ok, nativeCount = addon.GetEchoNumber(seal) end
    if ok and ((issecretvalue and issecretvalue(nativeCount)) or tonumber(nativeCount)) then
        -- Blizzard's formatted count can be private. The font widget accepts it directly.
        face.count:SetText(nativeCount)
    else
        face.count:SetText(count)
    end
    if display.style == "wings" and ready then
        display.readySince = display.readySince or now
        local flash = math.max(0, 1 - (now - display.readySince) / 0.75)
        display.wings:SetAlpha(0.79 + 0.21 * flash)
    elseif display.style == "wings" then
        display.wings:SetAlpha(0.30 + 0.16 * count)
    end
    if preview then
        face.status:SetText(preview.appearance and "Prévia do indicador" or "Teste de alerta")
    elseif state then
        local remaining = math.max(0, state.expires - now)
        local prefix = state.estimated and "Estimativa · " or (ready and "Troque o selo · " or "")
        face.status:SetText(string.format("%s%.1f s", prefix, remaining))
    else
        face.status:SetText("Arraste para mover")
    end
    display:Show()
end

local function Label(parent, style, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", style)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function PaintBackground()
    local alpha = addon.db.backgroundOpacity / 10
    display.face:SetBackdropColor(0.17, 0.18, 0.19, alpha)
    swingBar:SetBackdropColor(0.17, 0.18, 0.19, alpha)
end

local function ResetPosition()
    addon.db.position = nil
    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, "CENTER", 0, -154)
end

local function CreateFace(layout)
    local face = CreateFrame("Frame", nil, display, "BackdropTemplate")
    local width, height, offset = unpack(layout.plate)
    face:SetSize(width, height)
    face:SetPoint("CENTER", 0, offset)
    face:SetBackdrop({ bgFile = solid, edgeFile = solid, edgeSize = 1 })

    local x, y, size = unpack(layout.icon)
    face.icon = face:CreateTexture(nil, "ARTWORK")
    face.icon:SetPoint("TOPLEFT", x, y)
    face.icon:SetSize(size, size)
    face.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if layout.gilded then
        local setting = face:CreateTexture(nil, "BORDER")
        setting:SetPoint("TOPLEFT", face.icon, "TOPLEFT", -2, 2)
        setting:SetPoint("BOTTOMRIGHT", face.icon, "BOTTOMRIGHT", 2, -2)
        setting:SetColorTexture(0.72, 0.48, 0.20)
    end

    x, y, width = unpack(layout.title)
    face.title = Label(face, "GameFontNormal", "", x, y)
    face.title:SetWidth(width)
    face.title:SetJustifyH("LEFT")
    face.title:SetWordWrap(false)

    x, y = unpack(layout.number)
    face.count = face:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    face.count:SetPoint("TOPRIGHT", face, "TOPLEFT", x, y)
    local total = face:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    total:SetPoint("LEFT", face.count, "RIGHT", 3, -1)
    total:SetText("/ " .. addon.maxStacks)
    face.status = face:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    x, y = unpack(layout.status)
    face.status:SetPoint("TOP", face, "TOPLEFT", x, y)
    face.charges = {}

    local cells = layout.charges
    if cells then
        for index = 1, addon.maxStacks do
            local border = face:CreateTexture(nil, "BORDER")
            border:SetColorTexture(0.37, 0.26, 0.14, 1)
            border:SetSize(cells.w, cells.h)
            border:SetPoint("TOPLEFT", cells.x + (index - 1) * cells.dx, cells.y + (index - 1) * cells.dy)
            local fill = face:CreateTexture(nil, "ARTWORK")
            fill:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
            fill:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
            local shine = face:CreateTexture(nil, "OVERLAY")
            shine:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, 0)
            shine:SetPoint("TOPRIGHT", fill, "TOPRIGHT", -1, 0)
            shine:SetHeight(1)
            if cells.lead then
                local lead = face:CreateTexture(nil, "OVERLAY")
                lead:SetColorTexture(0.18, 0.13, 0.08, 0.58)
                lead:SetPoint("TOP", fill, "TOP", 0, -1)
                lead:SetPoint("BOTTOM", fill, "BOTTOM", 0, 1)
                lead:SetWidth(1)
            end
            face.charges[index] = { fill = fill, shine = shine }
        end
    end
    return face
end

local function ApplyStyle()
    local id = addon.db.indicatorStyle
    local layout = layouts[id]
    if display.face then display.face:Hide() end
    display.style = id
    display:SetSize(layout.width, layout.height)
    display.wings:SetShown(id == "wings")
    display.faces[id] = display.faces[id] or CreateFace(layout)
    display.face = display.faces[id]
    display.face:Show()
    display.readySince = nil
    swingBar:SetWidth(layout.plate[1])
    swingBar:ClearAllPoints()
    swingBar:SetPoint("TOP", display.face, "BOTTOM", 0, -4)
    PaintBackground()
end

local function BuildSwingBar()
    swingBar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    swingBar:SetHeight(24)
    swingBar:SetClampedToScreen(true)
    swingBar:SetBackdrop({ bgFile = solid, edgeFile = solid, edgeSize = 1 })
    swingBar.title = Label(swingBar, "GameFontHighlightSmall", "Ataque branco", 7, -4)
    swingBar.time = swingBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    swingBar.time:SetPoint("TOPRIGHT", -7, -4)

    local bar = CreateFrame("StatusBar", nil, swingBar)
    bar:SetPoint("BOTTOMLEFT", 6, 4)
    bar:SetPoint("BOTTOMRIGHT", -6, 4)
    bar:SetHeight(4)
    bar:SetStatusBarTexture(solid)
    bar:SetStatusBarColor(0.89, 0.62, 0.26)
    bar:SetMinMaxValues(0, 1)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.14, 0.12, 0.10, 0.85)
    swingBar.flash = bar:CreateTexture(nil, "OVERLAY")
    swingBar.flash:SetAllPoints()
    swingBar.flash:SetColorTexture(1, 0.84, 0.46, 1)
    swingBar.progress = bar

    local accumulated = 0
    swingBar:SetScript("OnUpdate", function(_, elapsed)
        accumulated = accumulated + elapsed
        if accumulated >= 1 / 30 then
            accumulated = 0
            RenderSwingTimer(GetTime())
        end
    end)
    swingBar:Hide()
end

local function BuildDisplay()
    display = CreateFrame("Frame", "AlexIraDisplay", UIParent)
    display.faces = {}
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
    BuildSwingBar()
    ApplyStyle()
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

local function PreviewAppearance()
    if not addon.tracker.seal and not moving and (not preview or preview.appearance) then
        preview = { seal = selectedSeal, count = addon.maxStacks, expires = GetTime() + 4, appearance = true }
    end
    addon.Render()
end

local function BuildStyleOption(panel)
    Label(panel, "GameFontNormal", "Estilo do indicador", 24, -403)
    local dropdown = Dropdown(panel, 186, 24, -423)
    dropdown:SetupMenu(function(_, menu)
        for _, style in ipairs(addon.styles) do
            menu:CreateRadio(style.name, function(id)
                return addon.db.indicatorStyle == id
            end, function(id)
                if addon.db.indicatorStyle == id then return end
                addon.db.indicatorStyle = id
                ApplyStyle()
                PreviewAppearance()
            end, style.id)
        end
    end)
end

local function BuildOpacityOption(panel)
    Label(panel, "GameFontNormal", "Opacidade do fundo", 234, -403)
    Label(panel, "GameFontHighlightSmall", "1 mais transparente, 10 opaco", 234, -449)
    local valueLabel = Label(panel, "GameFontHighlight", "", 385, -427)

    local slider = CreateFrame("Slider", nil, panel)
    slider:SetPoint("TOPLEFT", 234, -421)
    slider:SetSize(137, 22)
    slider:EnableMouse(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(1, 10)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    track:SetHeight(11)
    track:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(26, 26)
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetThumbTexture(thumb)

    slider:SetValue(addon.db.backgroundOpacity)
    valueLabel:SetText(addon.db.backgroundOpacity .. " / 10")
    slider:SetScript("OnValueChanged", function(_, value)
        addon.db.backgroundOpacity = value
        valueLabel:SetText(value .. " / 10")
        PaintBackground()
        PreviewAppearance()
    end)
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
    BuildStyleOption(panel)
    BuildOpacityOption(panel)

    local timer = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    timer:SetPoint("TOPLEFT", 21, -470)
    Label(panel, "GameFontHighlight", "Mostrar timer de ataque branco", 52, -480)
    timer:SetChecked(addon.db.showSwingTimer)
    timer:SetScript("OnClick", function(self)
        addon.db.showSwingTimer = self:GetChecked() == true
        if addon.db.showSwingTimer then
            PreviewAppearance()
        else
            addon.Render()
        end
    end)
    panel:SetScript("OnHide", function()
        moving = false
        if preview and preview.appearance then preview = nil end
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
    SLASH_ALEXIRA1 = "/alex"
    SLASH_ALEXIRA2 = "/alexira"
    SlashCmdList.ALEXIRA = function() Settings.OpenToCategory(optionsID) end
end
