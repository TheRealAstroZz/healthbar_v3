-- Healthbar-Script für NPCs in FiveM
local visiblePeds = {}
local damageTriggered = {}

-- Konfiguration direkt eingebunden
local SpecialModels = {
    [`a_c_westy`] = "Begleiter",
    [`csb_ramp_marine`] = "Boss"
}

local FloatingColors = {
    low = "#ffffff",
    medium = "#ffaa00",
    high = "#ff4444"
}

local CritWeapons = {
    [`WEAPON_SNIPERRIFLE`] = true,
    [`WEAPON_HEAVYSNIPER`] = true,
    [`WEAPON_MARKSMANRIFLE`] = true,
    [`WEAPON_MARKSMANRIFLE_MK2`] = true,
    [`WEAPON_ASSAULTRIFLE`] = true,
    [`WEAPON_ASSAULTRIFLE_MK2`] = true,
    [`WEAPON_CARBINERIFLE`] = true,
    [`WEAPON_CARBINERIFLE_MK2`] = true,
    [`WEAPON_SPECIALCARBINE`] = true,
    [`WEAPON_SPECIALCARBINE_MK2`] = true,
    [`WEAPON_BULLPUPRIFLE`] = true,
    [`WEAPON_BULLPUPRIFLE_MK2`] = true,
    [`WEAPON_ADVANCEDRIFLE`] = true,
    [`WEAPON_MILITARYRIFLE`] = true,
    [`WEAPON_COMPACTRIFLE`] = true,
    [`WEAPON_COMBATPDW`] = true,
    [`WEAPON_GUSENBERG`] = true,
    [`WEAPON_MG`] = true,
    [`WEAPON_COMBATMG`] = true,
    [`WEAPON_COMBATMG_MK2`] = true,
    [`WEAPON_MINISMG`] = true,
    [`WEAPON_SMG`] = true,
    [`WEAPON_SMG_MK2`] = true,
    [`WEAPON_MICROSMG`] = true,
    [`WEAPON_MACHINEPISTOL`] = true,
    [`WEAPON_PISTOL`] = true,
    [`WEAPON_PISTOL_MK2`] = true,
    [`WEAPON_COMBATPISTOL`] = true,
    [`WEAPON_APPISTOL`] = true,
    [`WEAPON_HEAVYPISTOL`] = true,
    [`WEAPON_VINTAGEPISTOL`] = true,
    [`WEAPON_REVOLVER`] = true,
    [`WEAPON_REVOLVER_MK2`] = true,
    [`WEAPON_NAVYREVOLVER`] = true,
    [`WEAPON_DOUBLEACTION`] = true
}

function getEntityScreenCoordsUsingCenter(entity)
    local coords = GetEntityCoords(entity)
    local screenX, screenY = GetActiveScreenResolution()
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z + 1.0, screenX, screenY)

    if onScreen then
        return math.floor(x * screenX), math.floor(y * screenY)
    end
    return nil, nil
end

function updateHealthBarOnClient(entity, current, max, x, y, label)
    SendNUIMessage({
        type = "updateHealthBar",
        entityId = entity,
        currentHealth = current,
        maxHealth = max,
        x = x,
        y = y,
        label = label
    })
end

function hideHealthBarOnClient(entity)
    SendNUIMessage({
        type = "hideHealthBar",
        entityId = entity
    })
end

AddEventHandler("gameEventTriggered", function(name, args)
    if name == "CEventNetworkEntityDamage" then
        local victim = args[1]
        local weapon = args[3]

        if DoesEntityExist(victim) and IsEntityAPed(victim) and not IsPedAPlayer(victim) then
            local model = GetEntityModel(victim)
            local label = SpecialModels[model] or (IsPedHuman(victim) and "Zombie" or "Animal")

            local oldHealth = damageTriggered[victim] and damageTriggered[victim].lastHealth or GetEntityHealth(victim)

            -- Erfasse Bone sofort
            local _, bone = GetPedLastDamageBone(victim)

            -- Ermittle, ob es ein Headshot war, bevor wir warten
            local isCrit = (bone == 31086) or CritWeapons[weapon]
            local wasDead = IsPedDeadOrDying(victim, true)

            Wait(0)

            local newHealth = GetEntityHealth(victim)
            local dmg = oldHealth - newHealth
            if dmg < 0 then dmg = 0 end

            local x, y = getEntityScreenCoordsUsingCenter(victim)
            if x and y then
                updateHealthBarOnClient(victim, newHealth - 100, GetPedMaxHealth(victim) - 100, x, y, label)

                damageTriggered[victim] = {
                    time = GetGameTimer(),
                    lastHealth = newHealth
                }

                -- Farbe je nach Schaden
                local color = FloatingColors.low
                if dmg > 50 then
                    color = FloatingColors.high
                elseif dmg > 20 then
                    color = FloatingColors.medium
                end

                -- Floating Damage anzeigen
                if dmg > 0 or isCrit then
                    SendNUIMessage({
                        type = "floatingDamage",
                        entityId = victim,
                        amount = math.floor(dmg),
                        x = x,
                        y = y,
                        color = color,
                        crit = isCrit
                    })
                end

                -- HEADSHOT-Kill anzeigen, wenn tot + Kopftreffer
                if wasDead and bone == 31086 then
                    SendNUIMessage({
                        type = "headshotKill",
                        x = x,
                        y = y
                    })
                end
            end
        end
    end
end)


CreateThread(function()
    while true do
        local aiming, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())

        if aiming and IsEntityAPed(entity) and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity) then
            local model = GetEntityModel(entity)
            local label = SpecialModels[model] or (IsPedHuman(entity) and "Zombie" or "Animal")
            local health = GetEntityHealth(entity) - 100
            local max = GetPedMaxHealth(entity) - 100
            local x, y = getEntityScreenCoordsUsingCenter(entity)
            if x and y then
                updateHealthBarOnClient(entity, health, max, x, y, label)
                visiblePeds[entity] = GetGameTimer()
            end
        end

        local now = GetGameTimer()

        for entity, lastSeen in pairs(visiblePeds) do
            if not DoesEntityExist(entity) or IsPedDeadOrDying(entity, true) then
                hideHealthBarOnClient(entity)
                visiblePeds[entity] = nil
                damageTriggered[entity] = nil
            elseif (not SpecialModels[GetEntityModel(entity)]) and (now - lastSeen > 500) then
                hideHealthBarOnClient(entity)
                visiblePeds[entity] = nil
            else
                local label = SpecialModels[GetEntityModel(entity)] or (IsPedHuman(entity) and "Zombie" or "Animal")
                local hp = GetEntityHealth(entity) - 100
                local max = GetPedMaxHealth(entity) - 100
                local x, y = getEntityScreenCoordsUsingCenter(entity)
                if x and y then
                    updateHealthBarOnClient(entity, hp, max, x, y, label)
                end
            end
        end

        for entity, data in pairs(damageTriggered) do
            if not DoesEntityExist(entity) or IsPedDeadOrDying(entity, true) or (now - data.time > 1000) then
                hideHealthBarOnClient(entity)
                damageTriggered[entity] = nil
            end
        end

        Wait(100)
    end
end)
