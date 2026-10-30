--[[
    rp_tablet / client
    Oeffnet das Tablet mit Pfeil runter (Control 173) oder per /tablet.
    Apps: Uebersicht, Jobs, Fraktion, Ueberweisen, Charakter, Regeln.
--]]

-- Jobliste fuer die Tablet-App. Ueber "x", "y", "z" laesst sich direkt eine
-- Route auf der Karte setzen. Neue Jobs einfach hier ergaenzen.
local Jobs = {
    {
        id = 'taxi',
        label = 'Taxifahrer',
        company = 'Downtown Cab Co.',
        place = 'Little Seoul, Vespucci Blvd',
        description = 'Fahrgäste durch die Stadt bringen und Trinkgeld kassieren.',
        pay = 'ca. 2.400 $ pro Schicht',
        coords = vector3(-1082.0, -1199.5, 5.6),
    },
    {
        id = 'mechaniker',
        label = 'Mechaniker',
        company = 'Los Santos Customs',
        place = 'Burton, Carcer Way',
        description = 'Fahrzeuge reparieren und tunen, Abschleppdienste fahren.',
        pay = 'ca. 3.000 $ pro Schicht',
        coords = vector3(-365.7, -131.0, 38.7),
    },
    {
        id = 'kurier',
        label = 'Paketkurier',
        company = 'Hafenlogistik',
        place = 'Hafen von Los Santos, Terminal',
        description = 'Pakete vom Hafen in die ganze Stadt ausliefern.',
        pay = 'ca. 2.800 $ pro Schicht',
        coords = vector3(1205.0, -3115.0, 5.5),
    },
    {
        id = 'entsorgung',
        label = 'Müllabfuhr',
        company = 'Städtische Entsorgung',
        place = 'La Mesa, Elgin Avenue',
        description = 'Mülltonnen leeren und die Straßen sauber halten.',
        pay = 'ca. 2.200 $ pro Schicht',
        coords = vector3(829.0, -1290.0, 28.2),
    },
}

local ok, coreConfig = pcall(function()
    return exports.rp_core:GetConfig()
end)

local config = (ok and coreConfig) or {}
local openControl = config.tabletControl or 173

local isOpen = false
local profile = nil

-- Jobs fuer die NUI aufbereiten (vektoren lassen sich nicht serialisieren)
local function jobListForUi()
    local list = {}

    for i = 1, #Jobs do
        local job = Jobs[i]
        list[i] = {
            id = job.id,
            label = job.label,
            company = job.company,
            place = job.place,
            description = job.description,
            pay = job.pay,
            x = job.coords.x,
            y = job.coords.y,
            z = job.coords.z,
        }
    end

    return list
end

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
        SendNUIMessage({ action = 'jobs', data = jobListForUi() })
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

-- Job auswaehlen: Route auf der Karte setzen und Tablet schliessen
RegisterNUICallback('waypoint', function(data, cb)
    local jobId = data and data.id
    local job = nil

    for _, entry in ipairs(Jobs) do
        if entry.id == jobId then
            job = entry
            break
        end
    end

    if not job then
        cb({ ok = false })
        return
    end

    cb({ ok = true })
    SetNewWaypoint(job.coords.x, job.coords.y)
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
