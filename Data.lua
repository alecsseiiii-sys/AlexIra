local _, addon = ...

addon.maxStacks = 3
addon.echoDuration = 15
addon.talent = 1310735

addon.styles = {
    { id = "wings", name = "Asas Douradas" },
    { id = "simple", name = "Simples" },
    { id = "relic", name = "Relicário" },
    { id = "glass", name = "Vitral Sagrado" },
    { id = "phoenix", name = "Fênix Dourada" },
    { id = "hammer", name = "Martelo da Aurora" },
    { id = "prism", name = "Escudo Prismático" },
    { id = "lantern", name = "Farol Sagrado" },
    { id = "constellation", name = "Constelação do Juramento" },
}

addon.seals = {
    { spell = 20375, echo = 1311703, name = "Selo do Comando", color = { 1, 0.72, 0.25 },
        ranks = { 20375, 20915, 20918, 20919, 20920 } },
    { spell = 20154, echo = 1311704, name = "Selo da Retidão", color = { 1, 0.88, 0.50 },
        ranks = { 20154, 20287, 20288, 20289, 20290, 20291, 20292, 20293 } },
    { spell = 20166, echo = 1328206, name = "Selo da Sabedoria", color = { 0.43, 0.72, 1 },
        ranks = { 20166, 20356, 20357, 20358 } },
    { spell = 20165, echo = 1328198, name = "Selo da Luz", color = { 0.43, 0.88, 0.65 },
        ranks = { 20165, 20347, 20348, 20349, 20350 } },
    { spell = 20164, echo = 1311705, name = "Selo da Justiça", color = { 0.76, 0.62, 1 },
        ranks = { 20164 } },
    { spell = 20418, echo = 1311701, name = "Selo da Fúria", color = { 1, 0.46, 0.39 },
        ranks = { 20418, 20419, 20420, 20421, 20422, 20423 } },
    { spell = 21082, name = "Selo do Cruzado",
        ranks = { 21082, 20162, 20305, 20306, 20307, 20308 } },
}

local procSound = 23287 -- SOUNDKIT.UI_POWER_AURA_GENERIC
local mediaPath = "Interface\\AddOns\\AlexIra\\Media\\Sounds\\"
addon.volumeStep = 20
addon.sounds = {
    { id = 0, name = "Sem som" },
    { id = procSound, name = "Proc do Choque Sagrado reforçado", file = "ProcChime.ogg" },
    { id = "proc-native", name = "Proc do Choque Sagrado nativo", kit = procSound },
    { id = 8959, name = "Aviso de raide" },
    { id = 12197, name = "Alerta de chefe" },
    { id = 37666, name = "Sussurro de chefe" },
    { id = 8960, name = "Verificação de prontidão" },
    { id = 25477, name = "Contagem da batalha" },
    { id = 25478, name = "Início da batalha" },
    { id = 36609, name = "Fila de batalha de mascotes" },
    { id = 12867, name = "Alarme" },
    { id = 18871, name = "Alarme 2" },
    { id = 12889, name = "Alarme 3" },
    { id = 3175, name = "Ping do mapa" },
    { id = 23404, name = "Missão concluída" },
    { id = 31578, name = "Saque épico" },
    { id = 31581, name = "Recompensa extra" },
    { id = 28814, name = "Armadilha pronta" },
    { id = 43936, name = "Progresso de missão" },
    { id = 18019, name = "Notificação da Battle.net" },
    { id = 880, name = "Convite para grupo" },
    { id = 829, name = "Abrir grimório" },
    { id = 120, name = "Moedas" },
    { id = "rubber-duck", name = "Pato de borracha", file = "RubberDuck.ogg" },
    { id = "clown-horn", name = "Buzina de palhaço", file = "ClownHorn.ogg" },
    { id = "boing", name = "Boing", file = "Boing.ogg" },
    { id = "chicken", name = "Galinha surpresa", file = "Chicken.ogg" },
    { id = "cartoon-fail", name = "Falha de desenho animado", file = "CartoonFail.ogg" },
    { id = "coin-8-bit", name = "Moeda de 8 bits", file = "Coin8Bit.ogg" },
    { id = "holy-bell", name = "Sino da Luz", file = "HolyBell.ogg" },
    { id = "trumpet", name = "Trombeta da vitória", file = "Trumpet.ogg" },
}

local soundByID, sealByCast, sealByEcho = {}, {}, {}
for _, sound in ipairs(addon.sounds) do
    soundByID[sound.id] = sound
end
for _, seal in ipairs(addon.seals) do
    for _, spell in ipairs(seal.ranks) do
        sealByCast[spell] = seal
    end
    if seal.echo then
        sealByEcho[seal.echo] = seal
    end
end
addon.sealByCast, addon.sealByEcho = sealByCast, sealByEcho

function addon.Public(value)
    if not issecretvalue or not issecretvalue(value) then
        return value
    end
end

function addon.SealName(seal)
    return addon.Public(C_Spell.GetSpellName(seal.spell)) or seal.name
end

function addon.InitializeSettings()
    AlexIraDB = type(AlexIraDB) == "table" and AlexIraDB or {}
    local styleID = "wings"
    for _, style in ipairs(addon.styles) do
        if style.id == AlexIraDB.indicatorStyle then
            styleID = style.id
            break
        end
    end
    AlexIraDB.indicatorStyle = styleID
    local opacity = AlexIraDB.backgroundOpacity
    AlexIraDB.backgroundOpacity = type(opacity) == "number" and opacity >= 1 and opacity <= 10
        and math.floor(opacity + 0.5) or 6
    AlexIraDB.showSwingTimer = AlexIraDB.showSwingTimer ~= false
    AlexIraDB.swingTimerPosition = AlexIraDB.swingTimerPosition == "below" and "below" or "above"
    AlexIraDB.swingTimerThickness = AlexIraDB.swingTimerThickness == "thin" and "thin" or "thick"
    AlexIraDB.showBuffDisplay = AlexIraDB.showBuffDisplay == true
    AlexIraDB.preferBuffCount = AlexIraDB.preferBuffCount ~= false
    AlexIraDB.instantMaxAlert = AlexIraDB.instantMaxAlert ~= false
    local volume = AlexIraDB.alertVolume
    local step = addon.volumeStep
    AlexIraDB.alertVolume = type(volume) == "number" and volume >= 0 and volume <= 100
        and math.floor(volume / step + 0.5) * step or 100
    AlexIraDB.sounds = type(AlexIraDB.sounds) == "table" and AlexIraDB.sounds or {}
    for echo in pairs(sealByEcho) do
        local choices = AlexIraDB.sounds[echo]
        choices = type(choices) == "table" and choices or {}
        for count = 1, addon.maxStacks do
            if not soundByID[choices[count]] then
                choices[count] = count == addon.maxStacks and procSound or 0
            end
        end
        AlexIraDB.sounds[echo] = choices
    end
    addon.db = AlexIraDB
end

local function PlayKit(kit, volume)
    if C_Sound and C_Sound.PlaySound then
        local ok, played = pcall(C_Sound.PlaySound, kit, "Master", false, false, nil, volume / 100)
        if ok then return played end
    end
    return PlaySound(kit, "Master")
end

function addon.PlayAlert(seal, count)
    local volume = addon.db.alertVolume
    if volume == 0 then return end
    local id = addon.db.sounds[seal.echo][count]
    local sound = soundByID[id]
    if not sound or id == 0 then return end

    local kit = sound.kit or (type(id) == "number" and id)
    local played = kit and PlayKit(kit, volume)
    if sound.file then
        -- PlaySoundFile has no gain parameter. Lower levels use pre-scaled audio.
        local folder = volume < 100 and volume .. "\\" or ""
        return PlaySoundFile(mediaPath .. folder .. sound.file, "Master") or played
    end
    return played
end
