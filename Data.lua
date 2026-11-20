local _, addon = ...

addon.maxStacks = 3
addon.echoDuration = 15
addon.talent = 1310735

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
addon.sounds = {
    { id = 0, name = "Sem som" },
    { id = procSound, name = "Proc do Choque Sagrado" },
    { id = 8959, name = "Aviso de raide" },
    { id = 12867, name = "Alarme" },
    { id = 8960, name = "Verificação de prontidão" },
    { id = 25478, name = "Início da batalha" },
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

function addon.PlayAlert(seal, count)
    local sound = addon.db.sounds[seal.echo][count]
    if sound > 0 then
        return PlaySound(sound, "Master")
    end
end
