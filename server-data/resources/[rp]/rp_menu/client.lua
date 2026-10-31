--[[
    rp_menu / client
    Kreismenü auf G. Es erscheint nur für Mitglieder einer Fraktion aus
    AllowedFactions - aktuell ausschliesslich Fraktion Nr. 1 (LSPD).

    Das Menü ist bewusst leer: der einzige Eintrag ist "Bodycam" und der
    Eintrag macht noch nichts. Weitere Einträge einfach in Entries ergaenzen,
    dann erscheinen sie im Kreis im Uhrzeigersinn ab 12 Uhr.
--]]

-- Fraktionen, die das Menü öffnen dürfen
local AllowedFactions = {
    [1] = true, -- 1 = LSPD
}

-- Einträge im Kreismenü
local Entries = {
    {
        id = 'bodycam',
        label = 'Bodycam',
        -- Wird angezeigt, solange action fehlt. "action" ist der Platz für
        -- die spätere Funktion - dann wurde das Menü nichts tun.
        hint = 'Bodycam ist noch nicht angeschlossen.',
    },
}

local profile = nil
local isOpen = false

local function ownFaction()
    if not profile then return 0 end
    return tonumber(profile.faction) or 0
end

local function hasAccess()
    if not profile or not profile.created then return false end
    return AllowedFactions[ownFaction()] == true
end

local function entriesForUi()
    local list = {}

    for i = 1, #Entries do
        local entry = Entries[i]
        list[i] = {
            id = entry.id,
            label = entry.label,
            hint = entry.hint,
        }
    end

    return list
end

local function setOpen(state)
    if state and not hasAccess() then return end
    if isOpen == state then return end

    isOpen = state
    SetNuiFocus(state, state)

    if state then
        SendNUIMessage({
            action = 'open',
            data = {
                faction = ownFaction(),
                entries = entriesForUi(),
            },
        })
    else
        SendNUIMessage({ action = 'close' })
    end
end

-- ------------------------------------------------------------- Tastatur

RegisterCommand('factionmenu', function()
    setOpen(not isOpen)
end, false)

RegisterKeyMapping('factionmenu', 'Kreismenü (Fraktion)', 'keyboard', 'G')

CreateThread(function()
    while true do
        if isOpen then
            Wait(0)

            -- Spieler soll sich im Menü nicht bewegen
            DisableControlAction(0, 1, true)    -- Kamera
            DisableControlAction(0, 2, true)    -- Kamera
            DisableControlAction(0, 22, true)   -- Springen
            DisableControlAction(0, 24, true)   -- Angriff
            DisableControlAction(0, 25, true)   -- Zielen
            DisableControlAction(0, 37, true)   -- Waffenrad
            DisableControlAction(0, 44, true)   -- Deckung
            DisableControlAction(0, 140, true)  -- Nahkampf
            DisableControlAction(0, 141, true)  -- Nahkampf
            DisableControlAction(0, 142, true)  -- Nahkampf
        else
            Wait(250)
        end
    end
end)

-- ------------------------------------------------------------- Profil

RegisterNetEvent('rp_core:client:profile', function(data)
    profile = data
    if isOpen and not hasAccess() then
        setOpen(false)
    end
end)

CreateThread(function()
    -- Falls das Profil schon vor dem Start dieser Ressource geladen wurde
    Wait(1500)
    if not profile then
        local ok, loaded = pcall(function()
            return exports.rp_core:GetProfile()
        end)
        if ok and loaded then profile = loaded end
    end
end)

-- ------------------------------------------------------------- NUI

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    setOpen(false)
end)

RegisterNUICallback('select', function(data, cb)
    local id = data and data.id
    cb({ ok = true })

    for i = 1, #Entries do
        local entry = Entries[i]
        if entry.id == id then
            if entry.action then
                setOpen(false)
                entry.action()
            else
                SendNUIMessage({
                    action = 'hint',
                    data = { message = entry.hint or 'Diese Funktion ist noch nicht verfügbar.' },
                })
            end
            return
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
