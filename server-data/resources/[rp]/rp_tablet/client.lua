--[[
    rp_tablet / client
    Oeffnet das Tablet mit Pfeil runter (Control 173) oder per /tablet.
    Apps: Uebersicht, Ueberweisen, Charakter, Regeln, Server.
--]]

local ok, coreConfig = pcall(function()
    return exports.rp_core:GetConfig()
end)

local config = (ok and coreConfig) or {}
local openControl = config.tabletControl or 173

local isOpen = false
local profile = nil

local function sendServerInfo()
    SendNUIMessage({
        action = 'serverInfo',
        data = {
            name = config.serverName or 'FiveM Server',
            players = #GetActivePlayers() + 1,
            max = GetConvarInt('sv_maxclients', 32),
        },
    })
end

local function setOpen(state)
    if isOpen == state then return end
    isOpen = state

    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })

    if state then
        SendNUIMessage({ action = 'profile', data = profile })
        sendServerInfo()
    end
end

RegisterNetEvent('rp_core:client:profile', function(data)
    profile = data
    if isOpen then
        SendNUIMessage({ action = 'profile', data = profile })
    end
end)

-- ------------------------------------------------------------- Tastatur

CreateThread(function()
    TriggerServerEvent('rp_core:server:requestProfile')

    while true do
        if not profile or not profile.created then
            Wait(500)
        elseif isOpen then
            Wait(300)
        elseif IsPauseMenuActive() then
            Wait(250)
        else
            Wait(0)
            if IsControlJustReleased(0, openControl) then
                setOpen(true)
            end
        end
    end
end)

RegisterCommand('tablet', function()
    if profile and profile.created then
        setOpen(not isOpen)
    end
end, false)

-- ------------------------------------------------------------- NUI

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    setOpen(false)
end)

RegisterNUICallback('transfer', function(data, cb)
    local targetId = tonumber(data and data.targetId)
    local amount = tonumber(data and data.amount)

    if not targetId or not amount or amount < 1 then
        cb({ ok = false, message = 'Bitte gueltige ID und Betrag angeben.' })
        return
    end

    cb({ ok = true })
    TriggerServerEvent('rp_core:server:transfer', math.floor(targetId), math.floor(amount))
end)

RegisterNetEvent('rp_tablet:client:feedback', function(ok, message)
    SendNUIMessage({
        action = 'feedback',
        data = { ok = ok and true or false, message = message or '' },
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
