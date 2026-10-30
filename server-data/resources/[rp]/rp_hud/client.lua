--[[
    rp_hud / client
    Zeigt Bargeld, Bank, Job, Server-ID und Uhrzeit an.
    Die Daten kommen aus rp_core (Event "rp_core:client:profile").
--]]

local profile = nil

local function send()
    SendNUIMessage({ action = 'profile', data = profile })
end

RegisterNetEvent('rp_core:client:profile', function(data)
    profile = data
    send()
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('rp_core:server:requestProfile')
end)
