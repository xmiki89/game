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
    }
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('rp_core:server:requestProfile')
end)
