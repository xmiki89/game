--[[
    rp_core / client
    Haelt die eigenen Spielerdaten und stellt sie anderen Ressourcen bereit.
    Alle Ressourcen koennen das Event "rp_core:client:profile" abonnieren.
--]]

local profile = nil

RegisterNetEvent('rp_core:client:profile', function(data)
    profile = data
end)

exports('GetProfile', function()
    return profile
end)

-- Konfiguration fuer andere Ressourcen (rp_character, rp_tablet, ...)
exports('GetConfig', function()
    return {
        serverName = Config.ServerName,
        spawn = Config.Spawn,
        tabletControl = Config.TabletControl,
        factions = Config.Factions,
    }
end)

-- Wird vom Admin-Tablet ausgeloest: Spieler zum HQ der Fraktion bringen
RegisterNetEvent('rp_core:client:spawnHq', function(target)
    if type(target) ~= 'table' then return end

    local ped = PlayerPedId()

    DoScreenFadeOut(350)
    Wait(450)

    RequestCollisionAtCoord(target.x, target.y, target.z)
    SetEntityCoords(ped, target.x, target.y, target.z, false, false, false, false)
    SetEntityHeading(ped, target.w or 0.0)

    Wait(800)
    DoScreenFadeIn(400)
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('rp_core:server:requestProfile')
end)
