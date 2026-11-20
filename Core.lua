local addonName, addon = ...
local public, tracker = addon.Public, addon.tracker
local activeSeal, sealExpires, echoInstance, echoSeal
local talentKnown, isPaladin, pendingSwing
local echoRevision = 0
local echoByName, spellNames = {}, {}

local function Read(getter, ...)
    if getter then
        local ok, value = pcall(getter, ...)
        if ok then return public(value) end
    end
end

local function SpellName(spell)
    local name = spellNames[spell] or public(C_Spell.GetSpellName(spell))
    spellNames[spell] = name
    return name
end

local function ReadNamedAura(spell)
    local name = SpellName(spell)
    return name and Read(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
end

local function ReadTalent()
    if C_SpellBook and Read(C_SpellBook.IsSpellKnown, addon.talent) then
        return true
    end
    local configID = public(C_ClassTalents.GetActiveConfigID())
    local config = configID and public(C_Traits.GetConfigInfo(configID))
    if not config then return nil end
    for _, tree in ipairs(config.treeIDs or {}) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(tree) or {}) do
            local node = public(C_Traits.GetNodeInfo(configID, nodeID))
            local active = node and public(node.activeEntry)
            if active and (public(node.activeRank) or public(active.rank) or 0) > 0 then
                local entry = public(C_Traits.GetEntryInfo(configID, active.entryID))
                local definition = entry and public(C_Traits.GetDefinitionInfo(entry.definitionID))
                if definition and public(definition.spellID) == addon.talent then
                    return true
                end
            end
        end
    end
    return false
end

local function RefreshTalent()
    local ok, learned = pcall(ReadTalent)
    if ok and learned ~= nil then talentKnown = learned end
end

local function RefreshActiveSeal()
    activeSeal, sealExpires = nil, nil
    for _, seal in ipairs(addon.seals) do
        local aura = ReadNamedAura(seal.spell)
        if aura then
            activeSeal = seal
            sealExpires = public(aura.expirationTime) or GetTime() + 30
            return
        end
    end
end

local function ObserveEcho(aura, seal, refresh, audible)
    if not aura then return false end
    local instance = public(aura.auraInstanceID)
    seal = seal or addon.sealByEcho[public(aura.spellId)] or echoByName[public(aura.name)]
        or (instance and instance == echoInstance and echoSeal)
    if not seal then return false end
    echoInstance, echoSeal = instance, seal
    talentKnown = true
    local count, expires = public(aura.applications), public(aura.expirationTime)
    if type(count) ~= "number" or count < 1 or count > addon.maxStacks then
        return false
    end
    local now = GetTime()
    if expires == 0 then expires = nil end
    if expires and expires <= now then return false end
    if tracker:Observe(seal, count, expires, now, refresh, audible) then
        echoRevision = echoRevision + 1
    end
    return true
end

local function RefreshEcho(update, audible)
    if update then
        for _, instance in ipairs(public(update.removedAuraInstanceIDs) or {}) do
            if echoInstance and public(instance) == echoInstance then
                if tracker.seal == echoSeal then tracker:Clear() end
                echoInstance, echoSeal = nil, nil
                echoRevision = echoRevision + 1
            end
        end
        for _, aura in ipairs(public(update.addedAuras) or {}) do
            if ObserveEcho(public(aura), nil, true, audible) then return true end
        end
        for _, instance in ipairs(public(update.updatedAuraInstanceIDs) or {}) do
            if public(instance) and instance == echoInstance then
                local aura = Read(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", instance)
                if ObserveEcho(aura, echoSeal, true, audible) then return true end
            end
        end
    end
    if echoInstance then
        local aura = Read(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", echoInstance)
        if ObserveEcho(aura, echoSeal, false, audible) then return true end
    end
    for spell, seal in pairs(addon.sealByEcho) do
        local aura = ReadNamedAura(spell) or Read(C_UnitAuras.GetPlayerAuraBySpellID, spell)
        if ObserveEcho(aura, seal, false, audible) then return true end
    end
    return false
end

local function RecordSwing(swingType)
    if not activeSeal or not talentKnown or GetTime() >= sealExpires then return end
    if issecretvalue and issecretvalue(swingType) then return end
    if swingType ~= nil and swingType ~= Enum.PlayerSwingType.MainHand then return end
    local now = GetTime()
    if pendingSwing and now - pendingSwing.at < 0.15 then return end
    pendingSwing = { at = now, seal = activeSeal, revision = echoRevision }
    -- A readable aura can already have arrived when the client signals the swing.
    RefreshEcho(nil, true)
end

local outcomes = { WOUND = true, MISS = true, DODGE = true, PARRY = true }
local function RecordFeedback(unit, action, school)
    if not pendingSwing or public(unit) ~= "target" or public(school) ~= 1 then return end
    action = public(action)
    if not outcomes[action] then return end
    local swing = pendingSwing
    local now = GetTime()
    local elapsed = now - swing.at
    -- Forever sends the target's hit reaction after the player's swing event.
    if elapsed < 0.25 or elapsed > 1.25 then return end
    pendingSwing = nil
    if action ~= "WOUND" then return end
    -- Prefer the aura if it is readable. A later UNIT_AURA can reconcile an
    -- estimate without replaying the alert for the same stack.
    if not RefreshEcho(nil, true) and swing.revision == echoRevision then
        tracker:Hit(swing.seal, now)
    end
end

local function SyncPlayer()
    pendingSwing = nil
    RefreshTalent()
    RefreshActiveSeal()
    if not RefreshEcho(nil, false) then
        tracker:Clear()
        echoInstance, echoSeal = nil, nil
    end
    addon.Render()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if (...) ~= addonName then return end
        self:UnregisterEvent(event)
        addon.InitializeSettings()
        local _, class = UnitClass("player")
        isPaladin = class == "PALADIN"
        self:RegisterEvent("PLAYER_LOGIN")
        return
    end
    if event == "PLAYER_LOGIN" then
        addon.CreateUI()
        if not isPaladin then return end
        for _, seal in ipairs(addon.seals) do
            local name = seal.echo and SpellName(seal.echo)
            if name then echoByName[name] = seal end
        end
        self:RegisterUnitEvent("UNIT_AURA", "player")
        self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        for _, name in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_ENABLED",
            "PLAYER_DEAD", "PLAYER_SWING", "UNIT_COMBAT", "TRAIT_CONFIG_UPDATED", "PLAYER_TALENT_UPDATE" }) do
            if C_EventUtils.IsEventValid(name) then self:RegisterEvent(name) end
        end
        C_Timer.After(0.3, SyncPlayer)
    elseif event == "UNIT_AURA" then
        local _, update = ...
        RefreshEcho(public(update), true)
        if public(InCombatLockdown()) == false then RefreshActiveSeal() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spell = ...
        local seal = addon.sealByCast[public(spell)]
        if seal then activeSeal, sealExpires = seal, GetTime() + 30 end
    elseif event == "PLAYER_SWING" then
        local _, swingType = ...
        RecordSwing(swingType)
    elseif event == "UNIT_COMBAT" then
        local unit, action, _, _, school = ...
        RecordFeedback(unit, action, school)
    elseif event == "PLAYER_TARGET_CHANGED" then
        pendingSwing = nil
    elseif event == "PLAYER_DEAD" then
        pendingSwing, activeSeal, sealExpires, echoInstance, echoSeal = nil, nil, nil, nil, nil
        tracker:Clear()
    elseif event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_TALENT_UPDATE" then
        if public(InCombatLockdown()) == false then SyncPlayer() end
    else
        SyncPlayer()
    end
    addon.Render()
end)
