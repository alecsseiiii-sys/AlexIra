local _, addon = ...

local display, swingBar, selectedSeal, optionsID, preview
local buffView, buffToggle, nativeIndicator
local nativeStyles = {}
local moving = false
local solid = "Interface\\Buttons\\WHITE8X8"
local media = "Interface\\AddOns\\AlexIra\\Media\\"
local starlight = "Interface\\Cooldown\\star4"
local anchors = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local layouts = {
    wings = {
        width = 366, height = 122, plate = { 166, 86, -7 },
        art = "Wings.tga", crop = { 0, 1, 42 / 256, 214 / 256 }, idleAlpha = 0.30,
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
    phoenix = {
        width = 356, height = 178, plate = { 174, 68, -12 },
        art = "Phoenix.tga", idleAlpha = 0.68,
        icon = { 10, -9, 22 }, title = { 39, -11, 130 }, number = { 139, -29 }, status = { 87, -54 },
        charges = { x = 10, y = -40, w = 25, h = 8, dx = 29, dy = 0 },
    },
    hammer = {
        width = 326, height = 163, plate = { 232, 59, -20 },
        art = "DawnHammer.tga", idleAlpha = 0.65,
        icon = { 14, -13, 28 }, title = { 53, -9, 132 }, number = { 199, -9 }, status = { 123, -42 },
        charges = { x = 53, y = -26, w = 43, h = 8, dx = 48, dy = 0 },
    },
    prism = {
        width = 112, height = 112,
        sealIcon = true,
        lightStages = {
            { { art = "PrismaticShield.tga", tint = { 0.34, 0.95, 0.39 }, alternateTint = { 0.98, 0.48, 0.24 } } },
            { { art = "PrismaticShield.tga", tint = { 1, 0.83, 0.23 }, alternateTint = { 0.31, 0.75, 1 } } },
            { { art = "PrismaticShield.tga", tint = { 1, 0.25, 0.20 }, alternateTint = { 1, 0.92, 0.51 } },
                { texture = starlight, size = 43, y = 10, tint = { 1, 0.37, 0.25, 0.78 },
                    alternateTint = { 1, 0.80, 0.32, 0.78 }, glow = true } },
        },
    },
    lantern = {
        width = 122, height = 122,
        lightStages = {
            { { art = "LanternEmber.tga", tint = { 0.43, 0.41, 0.46 } } },
            { { art = "LanternKindled.tga", tint = { 0.77, 0.70, 0.65 } } },
            { { art = "HolyLantern.tga" },
                { texture = starlight, size = 56, y = 7, tint = { 1, 0.81, 0.45, 0.68 }, glow = true } },
        },
    },
    constellation = {
        width = 126, height = 126,
        lightStages = {
            { { art = "OathConstellation.tga", tint = { 0.68, 0.75, 0.91 } },
                { texture = starlight, size = 33, x = -30, y = 28, tint = { 0.61, 0.87, 1, 1 }, glow = true } },
            { { texture = starlight, size = 33, x = 32, y = 26, tint = { 0.83, 0.62, 1, 1 }, glow = true } },
            { { texture = starlight, size = 42, y = -32, tint = { 1, 0.89, 0.49, 1 }, glow = true },
                { texture = starlight, size = 36, y = 29, tint = { 0.75, 0.81, 1, 0.68 }, glow = true } },
        },
    },
}

local function SealTexture(seal)
    return addon.Public(C_Spell.GetSpellTexture(seal.spell)) or 134400
end

local function PaintCharges(face, seal, count, nativeOnly)
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
        for _, texture in pairs(charge) do texture:SetShown(not nativeOnly) end
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
    if layouts[display.style].lightStages then
        swingBar:Hide()
        return
    end
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
    local live = addon.GetEchoView(now)
    if preview and (now >= preview.expires or (preview.appearance and live.seal)) then
        preview = nil
    end
    RenderSwingTimer(now)
    if nativeIndicator then
        local showLive = not (preview or moving)
        if nativeIndicator.showLive ~= showLive
            and pcall(nativeIndicator.host.SetAlpha, nativeIndicator.host, showLive and 1 or 0) then
            nativeIndicator.showLive = showLive
        end
        if nativeIndicator.showLive then
            display:Hide()
            return
        end
    end
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
    local layout = layouts[display.style]
    local face = display.face
    if layout.lightStages then
        if state and state.nativeOnly and tracker.seal == seal then count = tracker.count or 0 end
        count = math.max(1, count)
        for stage, art in ipairs(face.lightStages) do art:SetShown(stage <= count) end
        if face.sealIcon then
            if face.spell ~= seal.spell then
                face.spell = seal.spell
                face.sealIcon:SetTexture(SealTexture(seal))
            end
            face.sealIcon:SetShown(addon.db.showPrismSeal)
        end
        display:Show()
        return
    end
    local nativeOnly = state and state.nativeOnly == true
    local ready = count == addon.maxStacks
    local changedSeal = face.spell ~= seal.spell
    if changedSeal then
        face.spell = seal.spell
        face.icon:SetTexture(SealTexture(seal))
        face.title:SetText(addon.SealName(seal))
    end
    if changedSeal or face.lastCount ~= count or face.nativeOnly ~= nativeOnly then
        face.lastCount = count
        face.nativeOnly = nativeOnly
        PaintCharges(face, seal, count, nativeOnly)
        display.readySince = nil
    end
    if nativeOnly then
        -- The font widget accepts the formatted count even when Lua cannot read it.
        face.count:SetText(state.nativeText)
    else
        face.count:SetText(count)
    end
    if layout.art and ready then
        display.readySince = display.readySince or now
        local flash = math.max(0, 1 - (now - display.readySince) / 0.75)
        display.art:SetAlpha(0.79 + 0.21 * flash)
    elseif layout.art then
        display.art:SetAlpha(layout.idleAlpha + (0.79 - layout.idleAlpha) * count / addon.maxStacks)
    end
    if preview then
        face.status:SetText(preview.appearance and "Prévia do indicador" or "Teste de alerta")
    elseif state then
        local remaining = math.max(0, state.expires - now)
        local prefix = state.estimated and "Estimativa · " or (ready and "Troque o selo · " or "Buff · ")
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
    if layouts[display.style].lightStages then return end
    local alpha = addon.db.backgroundOpacity / 10
    display.face:SetBackdropColor(0.17, 0.18, 0.19, alpha)
    swingBar:SetBackdropColor(0.17, 0.18, 0.19, alpha)
end

local function PositionIndicator(frame)
    local position = addon.db.position
    frame:ClearAllPoints()
    if type(position) == "table" and anchors[position[1]] and anchors[position[2]]
        and type(position[3]) == "number" and type(position[4]) == "number" then
        frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -154)
    end
end

local function ResetPosition()
    addon.db.position = nil
    PositionIndicator(display)
    addon.RefreshBuffDisplay()
end

local function SetIndicatorArt(art, layout)
    art:SetShown(layout.art ~= nil)
    if not layout.art then return end
    art:SetTexture(media .. layout.art)
    art:SetTexCoord(unpack(layout.crop or { 0, 1, 0, 1 }))
end

local function ApplyLightTint(texture, layer)
    local tint = layer.tint
    if layer.alternateTint and not addon.db.prismTrafficColors then tint = layer.alternateTint end
    if tint then texture:SetVertexColor(unpack(tint)) end
end

local function RefreshLightTints(textures)
    for _, entry in ipairs(textures) do ApplyLightTint(entry.texture, entry.layer) end
end

local function DrawLightStage(parent, layers, tintUpdates)
    for _, layer in ipairs(layers) do
        local texture = parent:CreateTexture(nil, layer.glow and "OVERLAY" or "ARTWORK")
        texture:SetTexture(layer.texture or media .. layer.art)
        if layer.size then
            texture:SetSize(layer.size, layer.size)
            texture:SetPoint("CENTER", parent, "CENTER", layer.x or 0, layer.y or 0)
        else
            texture:SetAllPoints(parent)
        end
        ApplyLightTint(texture, layer)
        if layer.alternateTint then tintUpdates[#tintUpdates + 1] = { texture = texture, layer = layer } end
        if layer.glow then texture:SetBlendMode("ADD") end
    end
end

local function CreateLightSealIcon(parent)
    local layer = CreateFrame("Frame", nil, parent)
    layer:SetAllPoints(parent)
    layer:SetFrameLevel(parent:GetFrameLevel() + addon.maxStacks + 1)
    local icon = layer:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", layer, "CENTER", 0, 12)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return icon, layer
end

local function CreateLightFace(layout)
    local face = CreateFrame("Frame", nil, display)
    face:SetAllPoints(display)
    face.lightStages = {}
    face.lightTints = {}
    for stage, layers in ipairs(layout.lightStages) do
        local art = CreateFrame("Frame", nil, face)
        art:SetAllPoints(face)
        art:SetFrameLevel(face:GetFrameLevel() + stage)
        DrawLightStage(art, layers, face.lightTints)
        face.lightStages[stage] = art
    end
    if layout.sealIcon then face.sealIcon = CreateLightSealIcon(face) end
    return face
end

local function CreateFace(layout, parent, native)
    local face = CreateFrame("Frame", nil, parent, "BackdropTemplate")
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
    if cells and not native then
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
            local lead
            if cells.lead then
                lead = face:CreateTexture(nil, "OVERLAY")
                lead:SetColorTexture(0.18, 0.13, 0.08, 0.58)
                lead:SetPoint("TOP", fill, "TOP", 0, -1)
                lead:SetPoint("BOTTOM", fill, "BOTTOM", 0, 1)
                lead:SetWidth(1)
            end
            face.charges[index] = { border = border, fill = fill, shine = shine, lead = lead }
        end
    end
    return face
end

local function LayoutSwingBar()
    local layout = layouts[display.style]
    if layout.lightStages then
        swingBar:Hide()
        return
    end
    local face = display.face
    local above = addon.db.swingTimerPosition == "above"
    local height = addon.db.swingTimerThickness == "thick" and 9 or 4
    swingBar:SetWidth(layout.plate[1])
    swingBar:SetHeight(20 + height)
    swingBar.progress:SetHeight(height)
    swingBar:ClearAllPoints()
    if above then
        swingBar:SetPoint("BOTTOM", face, "TOP", 0, 4)
    else
        swingBar:SetPoint("TOP", face, "BOTTOM", 0, -4)
    end
end

local function ApplyStyle()
    local id = addon.db.indicatorStyle
    local layout = layouts[id]
    if display.face then display.face:Hide() end
    display.style = id
    display:SetSize(layout.width, layout.height)
    SetIndicatorArt(display.art, layout)
    if not display.faces[id] then
        display.faces[id] = layout.lightStages and CreateLightFace(layout) or CreateFace(layout, display)
    end
    display.face = display.faces[id]
    display.face:Show()
    display.readySince = nil
    LayoutSwingBar()
    PaintBackground()
end

local function BuildSwingBar()
    swingBar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    swingBar:SetClampedToScreen(true)
    swingBar:SetBackdrop({ bgFile = solid, edgeFile = solid, edgeSize = 1 })
    swingBar.title = Label(swingBar, "GameFontHighlightSmall", "Ataque branco", 7, -4)
    swingBar.time = swingBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    swingBar.time:SetPoint("TOPRIGHT", -7, -4)

    local bar = CreateFrame("StatusBar", nil, swingBar)
    bar:SetPoint("BOTTOMLEFT", 6, 4)
    bar:SetPoint("BOTTOMRIGHT", -6, 4)
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
        addon.RefreshBuffDisplay()
    end)
    PositionIndicator(display)

    display.art = display:CreateTexture(nil, "BACKGROUND")
    display.art:SetAllPoints(display)
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

local function BuildSwingAppearance(panel)
    local dropdown = Dropdown(panel, 177, 245, -20)
    dropdown:OverrideText("Barra de ataque branco")
    dropdown:SetupMenu(function(_, menu)
        local function AddChoice(label, setting, value)
            menu:CreateRadio(label, function()
                return addon.db[setting] == value
            end, function()
                addon.db[setting] = value
                LayoutSwingBar()
                if addon.db.showSwingTimer then PreviewAppearance() end
            end)
        end
        menu:CreateTitle("Posição")
        AddChoice("Acima", "swingTimerPosition", "above")
        AddChoice("Abaixo", "swingTimerPosition", "below")
        menu:CreateTitle("Espessura")
        AddChoice("Grossa", "swingTimerThickness", "thick")
        AddChoice("Fina", "swingTimerThickness", "thin")
    end)
end

local function BuildStyleOption(panel)
    Label(panel, "GameFontNormal", "Estilo do indicador", 24, -367)
    local dropdown = Dropdown(panel, 186, 24, -387)
    dropdown:SetupMenu(function(_, menu)
        for _, style in ipairs(addon.styles) do
            menu:CreateRadio(style.name, function(id)
                return addon.db.indicatorStyle == id
            end, function(id)
                if addon.db.indicatorStyle == id then return end
                addon.db.indicatorStyle = id
                ApplyStyle()
                addon.RefreshBuffDisplay()
                PreviewAppearance()
            end, style.id)
        end
        if addon.db.indicatorStyle == "prism" then
            menu:CreateDivider()
            local function AddOption(label, key)
                local option = menu:CreateCheckbox(label, function()
                    return addon.db[key]
                end, function()
                    addon.db[key] = not addon.db[key]
                    addon.RefreshBuffDisplay()
                    PreviewAppearance()
                end)
                option:SetSelectionIgnored()
            end
            AddOption("Ícone do selo no escudo", "showPrismSeal")
            AddOption("Cores de semáforo", "prismTrafficColors")
        end
    end)
end

local function MakeSlider(panel, x, y, width, minimum, maximum, step)
    local slider = CreateFrame("Slider", nil, panel)
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetSize(width, 22)
    slider:EnableMouse(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
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
    return slider
end

local function BuildOpacityOption(panel)
    Label(panel, "GameFontNormal", "Opacidade do fundo", 234, -367)
    Label(panel, "GameFontHighlightSmall", "1 mais transparente, 10 opaco", 234, -413)
    local valueLabel = Label(panel, "GameFontHighlight", "", 385, -391)
    local slider = MakeSlider(panel, 234, -385, 137, 1, 10, 1)
    slider:SetValue(addon.db.backgroundOpacity)
    valueLabel:SetText(addon.db.backgroundOpacity .. " / 10")
    slider:SetScript("OnValueChanged", function(_, value)
        addon.db.backgroundOpacity = value
        valueLabel:SetText(value .. " / 10")
        PaintBackground()
        addon.RefreshBuffDisplay()
        PreviewAppearance()
    end)
end

local function BuildVolumeOption(panel)
    Label(panel, "GameFontNormal", "Volume dos alertas", 185, -205)
    local valueLabel = Label(panel, "GameFontHighlight", addon.db.alertVolume .. "%", 386, -205)
    local slider = MakeSlider(panel, 302, -199, 74, 0, 100, addon.volumeStep)
    slider:SetValue(addon.db.alertVolume)
    slider:SetScript("OnValueChanged", function(_, value)
        addon.db.alertVolume = value
        valueLabel:SetText(value .. "%")
    end)
end

local function BindBuffCharges(button, face, cells)
    if not cells then return end
    local divisions = addon.maxStacks
    local width = cells.w + (divisions - 1) * cells.dx
    local height = cells.h + (divisions - 1) * cells.dy
    local vertical = cells.dy > 0
    local bar = CreateFrame("StatusBar", nil, face)
    bar:SetPoint("TOPLEFT", face, "TOPLEFT", cells.x, cells.y + (divisions - 1) * cells.dy)
    bar:SetSize(width, height)
    bar:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
    bar:SetStatusBarTexture(solid)
    bar:SetStatusBarColor(0.92, 0.67, 0.30)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.23, 0.16, 0.09, 0.9)
    for index = 1, divisions - 1 do
        local divider = bar:CreateTexture(nil, "OVERLAY")
        divider:SetColorTexture(0.13, 0.09, 0.05)
        if vertical then
            divider:SetSize(width, 2)
            divider:SetPoint("CENTER", bar, "BOTTOM", 0, index * height / divisions)
        else
            divider:SetSize(2, height)
            divider:SetPoint("CENTER", bar, "LEFT", index * width / divisions, 0)
        end
    end
    if not pcall(button.SetApplicationBar, button, bar, { minApplications = 0, maxApplications = divisions }) then
        bar:Hide()
    end
end

local function BindBuffFace(button, layout)
    local art = button:CreateTexture(nil, "BACKGROUND")
    art:SetAllPoints(button)
    SetIndicatorArt(art, layout)
    art:SetAlpha(0.79)
    local face = CreateFace(layout, button, true)
    face:SetBackdropBorderColor(0.50, 0.36, 0.19)
    button:SetIcon(face.icon)
    if not pcall(button.SetSpellName, button, face.title) then face.title:SetText("Eco do selo") end
    if not pcall(button.SetDurationText, button, face.status) then face.status:SetText("Buff") end
    BindBuffCharges(button, face, layout.charges)
    return face
end

local function AddEchoSlot(view, layout, spells, initialize, levelOffset)
    local host = view.host
    local container = CreateFrame("AuraContainer", nil, host, "CustomAuraContainerTemplate")
    container:SetAllPoints(host)
    if levelOffset then container:SetFrameLevel(host:GetFrameLevel() + levelOffset) end
    container:SetUnit("player")
    container:AddAuraSlot("echo", "HELPFUL", {
        candidateFilters = { includeSpellIDs = spells },
        initializeFrame = function(button)
            button:SetSize(layout and layout.width or 76, layout and layout.height or 28)
            button:SetPoint("CENTER", container, "CENTER")
            if levelOffset then button:SetFrameLevel(container:GetFrameLevel() + 1) end
            button:EnableMouse(false)
            initialize(button)
        end,
    })
    view.containers[#view.containers + 1] = container
end

local function BindLightThreshold(button, layers, stacks, tintUpdates)
    -- The client controls visibility. Only the artwork attached to this frame is visible.
    local gate = CreateFrame("StatusBar", nil, button)
    gate:SetAllPoints(button)
    gate:SetStatusBarTexture(solid)
    gate:SetStatusBarColor(0, 0, 0, 0)
    DrawLightStage(gate, layers, tintUpdates)
    button:SetApplicationBar(gate, { minApplications = stacks, maxApplications = addon.maxStacks })
end

local function BuildBuffDisplay(view, layout)
    if not C_AuraContainerUtil then C_AddOns.LoadAddOn("Blizzard_AuraContainer") end
    local spells = {}
    for id in pairs(addon.sealByEcho) do spells[id] = true end
    if layout and layout.lightStages then
        local stages = layout.lightStages
        view.lightTints = {}
        AddEchoSlot(view, layout, spells, function(button)
            DrawLightStage(button, stages[1], view.lightTints)
            BindLightThreshold(button, stages[2], 2, view.lightTints)
            view.hasSecondStage = true
        end, 1)
        AddEchoSlot(view, layout, spells, function(button)
            BindLightThreshold(button, stages[3], 3, view.lightTints)
            if layout.sealIcon then
                local icon, layer = CreateLightSealIcon(button)
                button:SetIcon(icon)
                view.sealIconLayer = layer
            end
            view.hasThirdStage = true
        end, 5)
        return
    end

    local formatter = C_StringUtil.CreateAbbreviatedNumberFormatter()
    if layout and C_StringUtil.CreateNumericRuleFormatter then
        local ruleFormatter = C_StringUtil.CreateNumericRuleFormatter()
        ruleFormatter:SetBreakpoints({
            { threshold = 0, format = "" },
            { threshold = 1, format = "%d" },
            { threshold = addon.maxStacks, format = "|cffffdc80%d|r" },
        })
        formatter = ruleFormatter
    end
    AddEchoSlot(view, layout, spells, function(button)
        local count
        if layout then
            view.face = BindBuffFace(button, layout)
            count = view.face.count
        else
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("LEFT")
            icon:SetSize(24, 24)
            button:SetIcon(icon)
            count = Label(button, "GameFontHighlightLarge", "", 32, -5)
        end
        button:SetApplicationCount(count, { formatter = formatter })
    end)
end

local function CreateBuffDisplay(layout)
    -- Keep managed widgets away from the draggable frame and its anchor chain.
    local name = not layout and "AlexIraBuffBadge" or nil
    local host = CreateFrame("Frame", name, UIParent)
    host:Hide()
    host:SetSize(layout and layout.width or 76, layout and layout.height or 28)
    if layout then
        host:SetClampedToScreen(true)
        PositionIndicator(host)
    else
        host:SetPoint("TOP", UIParent, "TOP", 0, -90)
    end
    local view = { host = host, showLive = true, containers = {} }
    if pcall(BuildBuffDisplay, view, layout)
        and (not layout or view.face or (view.hasSecondStage and view.hasThirdStage)) then
        return view
    end
end

local function ShowBuffView(view, shown)
    if not view or view.enabled == shown then return end
    for _, container in ipairs(view.containers) do container:SetEnabled(shown) end
    view.host:SetShown(shown)
    view.enabled = shown
end

function addon.RefreshBuffDisplay()
    if display.face.lightTints then RefreshLightTints(display.face.lightTints) end
    if not buffToggle then return end
    if addon.Public(InCombatLockdown()) ~= false then
        addon.Render()
        return
    end
    local layout = layouts[display.style]
    local showBadge = addon.db.showBuffDisplay and not layout.lightStages
    if showBadge and not buffView then
        buffView = CreateBuffDisplay()
        if not buffView then
            addon.db.showBuffDisplay = false
            buffToggle:SetChecked(false)
            DEFAULT_CHAT_FRAME:AddMessage("AlexIra: o cliente não disponibilizou o visor nativo do buff.")
        end
    end
    ShowBuffView(buffView, showBadge)

    local nextIndicator
    if addon.db.preferBuffCount then
        local id = display.style
        if nativeStyles[id] == nil then
            nativeStyles[id] = CreateBuffDisplay(layout) or false
            if not nativeStyles[id] then
                DEFAULT_CHAT_FRAME:AddMessage("AlexIra: usando o indicador original até o visor nativo estar disponível.")
            end
        end
        nextIndicator = nativeStyles[id] or nil
    end
    if nativeIndicator ~= nextIndicator then ShowBuffView(nativeIndicator, false) end
    nativeIndicator = nextIndicator
    if nativeIndicator then
        PositionIndicator(nativeIndicator.host)
        if nativeIndicator.face then
            nativeIndicator.face:SetBackdropColor(0.17, 0.18, 0.19, addon.db.backgroundOpacity / 10)
        end
        if nativeIndicator.sealIconLayer then
            nativeIndicator.sealIconLayer:SetShown(addon.db.showPrismSeal)
        end
        if nativeIndicator.lightTints then RefreshLightTints(nativeIndicator.lightTints) end
        ShowBuffView(nativeIndicator, true)
    end
    addon.Render()
end

local function CheckOption(panel, label, x, y, setting, onChange)
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", x, y)
    Label(panel, "GameFontHighlight", label, x + 31, y - 10)
    check:SetChecked(addon.db[setting])
    check:SetScript("OnClick", function(self)
        addon.db[setting] = self:GetChecked() == true
        if onChange then onChange() end
    end)
    return check
end

local function BuildOptions(isPaladin)
    local panel = CreateFrame("Frame")
    Label(panel, "GameFontNormalHuge", "AlexIra", 24, -22)
    Label(panel, "GameFontHighlight", "Selecione um selo para configurar seus três alertas.", 24, -58)
    BuildSwingAppearance(panel)
    BuildVolumeOption(panel)

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
    move:SetPoint("TOPLEFT", 21, -327)
    Label(panel, "GameFontHighlight", "Mover indicador", 52, -337)
    move:SetScript("OnClick", function(self)
        moving = self:GetChecked()
        display:EnableMouse(moving)
        addon.Render()
    end)
    Button(panel, "Restaurar posição", 146, 180, -331, ResetPosition)
    BuildStyleOption(panel)
    BuildOpacityOption(panel)

    CheckOption(panel, "Mostrar timer de ataque branco", 21, -429, "showSwingTimer", function()
        if addon.db.showSwingTimer then
            PreviewAppearance()
        else
            addon.Render()
        end
    end)
    if isPaladin then
        buffToggle = CheckOption(panel, "Mostrar buff separado", 267, -429, "showBuffDisplay", addon.RefreshBuffDisplay)
        CheckOption(panel, "Buff nativo no indicador", 21, -460, "preferBuffCount", addon.RefreshBuffDisplay)
        CheckOption(panel, "Som de 3 sem espera", 267, -460, "instantMaxAlert")
    end
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

function addon.CreateUI(isPaladin)
    selectedSeal = addon.seals[1]
    BuildDisplay()
    BuildOptions(isPaladin)
    addon.RefreshBuffDisplay()
    SLASH_ALEXIRA1 = "/alex"
    SLASH_ALEXIRA2 = "/alexira"
    SlashCmdList.ALEXIRA = function() Settings.OpenToCategory(optionsID) end
end
