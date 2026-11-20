local addonName, addon = ...
local public, tracker = addon.Public, addon.tracker
local activeSeal, sealExpires, sealInstance, echoInstance, echoSeal
local echoRestricted, echoExpiry
local retiredInstances = {}
local talentKnown, isPaladin, pendingSwing
local echoRevision, lastEchoSignal = 0, -math.huge
local echoByName, spellNames = {}, {}
local feedbackWindow, burstGap = 1.25, 0.15

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
    local now = GetTime()
    for _, seal in ipairs(addon.seals) do
        local aura = ReadNamedAura(seal.spell)
        if aura then
            local expires = public(aura.expirationTime)
            if not expires or expires == 0 then expires = seal == activeSeal and sealExpires or now + 30 end
            local instance = public(aura.auraInstanceID) or (seal == activeSeal and sealInstance) or nil
            activeSeal, sealExpires, sealInstance = seal, expires, instance
            return
        end
    end
    -- A scan may still be restricted just after combat ends. Keep the seal
    -- known from the successful cast until it is removed or its timer ends.
    if sealExpires and now >= sealExpires then
        activeSeal, sealExpires, sealInstance = nil, nil, nil
    end
end

local function RecentSwing(now)
    if pendingSwing and now - pendingSwing.at <= feedbackWindow then
        return pendingSwing
    end
end

local function AcceptEcho(seal, count, expires, now, refresh, audible, estimated)
    if tracker:Observe(seal, count, expires, now, refresh, audible, estimated) then
        echoRevision, lastEchoSignal = echoRevision + 1, now
    end
    return true
end

local function RetireEcho()
    if echoInstance then
        local now = GetTime()
        for id, deadline in pairs(retiredInstances) do
            if deadline <= now then retiredInstances[id] = nil end
        end
        retiredInstances[echoInstance] = now + addon.echoDuration
    end
    echoInstance, echoSeal, echoRestricted, echoExpiry = nil, nil, nil, nil
end

function addon.GetEchoNumber(seal)
    local displayCount = C_UnitAuras.GetAuraApplicationDisplayCount
    if echoRestricted and echoInstance and seal == echoSeal and displayCount then
        return pcall(displayCount, "player", echoInstance, 1, addon.maxStacks)
    end
    return false
end

local function ObserveEcho(aura, seal, change, audible)
    if not aura then return false end
    local instance = public(aura.auraInstanceID)
    if instance and retiredInstances[instance] then return false end
    seal = seal or addon.sealByEcho[public(aura.spellId)] or echoByName[public(aura.name)]
        or (instance and instance == echoInstance and echoSeal)
    if not seal then return false end
    local now = GetTime()
    local expires = public(aura.expirationTime)
    if expires == 0 then expires = nil end
    if expires and expires <= now then return false end

    tracker:Expire(now)
    local fresh = seal ~= echoSeal or (instance and instance ~= echoInstance)
    if fresh and instance and echoInstance then
        if seal == echoSeal and tracker.seal == seal then tracker:Clear() end
        RetireEcho()
    end
    local previousExpiry = not fresh and echoExpiry or nil
    local expiryAdvanced = expires and previousExpiry and expires > previousExpiry
    echoInstance = instance or (seal == echoSeal and echoInstance) or nil
    echoSeal, echoExpiry = seal, expires or previousExpiry
    talentKnown = true

    local count = public(aura.applications)
    if not count or count == 0 then
        local display = echoInstance and Read(C_UnitAuras.GetAuraApplicationDisplayCount,
            "player", echoInstance, 1, addon.maxStacks)
        count = display and tonumber(display)
    end
    echoRestricted = type(count) ~= "number" or count < 1 or count > addon.maxStacks
    if not echoRestricted then
        return AcceptEcho(seal, count, expires, now, change ~= nil, audible, false)
    end

    local previous = tracker.seal == seal and tracker.count or 0
    local swing = RecentSwing(now)
    local matches = swing and swing.seal == seal
    -- An identified new Echo can start a stack even when its applications
    -- field and the melee hit reaction are both restricted.
    if previous == 0 and (change or (fresh and audible and matches)) then
        return AcceptEcho(seal, 1, expires, now, true, audible, true)
    end
    if change == "updated" then
        local uncountedSwing = matches and swing.revision == echoRevision
        local distinctUpdate = not matches and now - lastEchoSignal >= burstGap
            and (expiryAdvanced or not (expires and previousExpiry))
        if uncountedSwing or distinctUpdate then
            return AcceptEcho(seal, math.min(previous + 1, addon.maxStacks), expires, now, true, audible, true)
        end
    end
    return false
end

local function RefreshEcho(update, audible)
    if update then
        for _, instance in ipairs(public(update.removedAuraInstanceIDs) or {}) do
            instance = public(instance)
            if sealInstance and instance == sealInstance then
                activeSeal, sealExpires, sealInstance = nil, nil, nil
            end
            if echoInstance and instance == echoInstance then
                local swing = RecentSwing(GetTime())
                if swing and swing.stored == echoSeal and swing.seal ~= echoSeal then
                    echoRevision = echoRevision + 1
                end
                if tracker.seal == echoSeal then tracker:Clear() end
                RetireEcho()
            end
        end
        for _, aura in ipairs(public(update.addedAuras) or {}) do
            if ObserveEcho(public(aura), nil, "added", audible) then return true end
        end
        for _, instance in ipairs(public(update.updatedAuraInstanceIDs) or {}) do
            if public(instance) then
                local aura = Read(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", instance)
                local seal = instance == echoInstance and echoSeal or nil
                if ObserveEcho(aura, seal, "updated", audible) then return true end
            end
        end
    end
    if echoInstance then
        local aura = Read(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", echoInstance)
        if ObserveEcho(aura, echoSeal, nil, audible) then return true end
    end
    for spell, seal in pairs(addon.sealByEcho) do
        local aura = ReadNamedAura(spell) or Read(C_UnitAuras.GetPlayerAuraBySpellID, spell)
        if ObserveEcho(aura, seal, nil, audible) then return true end
    end
    return false
end

local function RecordSwing(swingType)
    if not activeSeal or not talentKnown or GetTime() >= sealExpires then return end
    if issecretvalue and issecretvalue(swingType) then return end
    if swingType ~= nil and swingType ~= Enum.PlayerSwingType.MainHand then return end
    local now = GetTime()
    if pendingSwing and now - pendingSwing.at < burstGap then return end
    tracker:Expire(now)
    -- The Echo event can precede PLAYER_SWING in the same event burst.
    local seenBeforeSwing = tracker.seal == activeSeal and now - lastEchoSignal < 0.05
    pendingSwing = {
        at = now, seal = activeSeal, stored = tracker.seal or echoSeal,
        revision = not seenBeforeSwing and echoRevision or nil,
    }
    -- A readable aura can already have arrived when the client signals the swing.
    RefreshEcho(nil, true)
end

local outcomes = { WOUND = true, MISS = true, DODGE = true, PARRY = true }
local function RecordFeedback(unit, action, school)
    if not pendingSwing or pendingSwing.feedback or public(unit) ~= "target" or public(school) ~= 1 then return end
    action = public(action)
    if not outcomes[action] then return end
    local swing = pendingSwing
    local now = GetTime()
    local elapsed = now - swing.at
    -- Forever sends the target's hit reaction after the player's swing event.
    if elapsed < 0.25 or elapsed > feedbackWindow then return end
    swing.feedback = true
    if action ~= "WOUND" then return end
    -- Prefer the aura if it is readable. A later UNIT_AURA can reconcile an
    -- estimate without replaying the alert for the same stack.
    if not RefreshEcho(nil, true) and swing.revision == echoRevision then
        local previous = tracker.seal
        tracker:Hit(swing.seal, now)
        if previous and previous ~= swing.seal and previous == echoSeal then RetireEcho() end
        echoRevision, lastEchoSignal = echoRevision + 1, now
    end
end

local function SyncPlayer()
    pendingSwing = nil
    RefreshTalent()
    RefreshActiveSeal()
    if not RefreshEcho(nil, false) and talentKnown == false then
        tracker:Clear()
        RetireEcho()
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
        if seal then activeSeal, sealExpires, sealInstance = seal, GetTime() + 30, nil end
    elseif event == "PLAYER_SWING" then
        local _, swingType = ...
        RecordSwing(swingType)
    elseif event == "UNIT_COMBAT" then
        local unit, action, _, _, school = ...
        RecordFeedback(unit, action, school)
    elseif event == "PLAYER_TARGET_CHANGED" then
        pendingSwing = nil
    elseif event == "PLAYER_DEAD" then
        pendingSwing, activeSeal, sealExpires, sealInstance = nil, nil, nil, nil
        RetireEcho()
        tracker:Clear()
    elseif event == "PLAYER_ENTERING_WORLD" then
        activeSeal, sealExpires, sealInstance = nil, nil, nil
        RetireEcho()
        retiredInstances = {}
        tracker:Clear()
        SyncPlayer()
    elseif event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_TALENT_UPDATE" then
        if public(InCombatLockdown()) == false then SyncPlayer() end
    else
        SyncPlayer()
    end
    addon.Render()
end)
