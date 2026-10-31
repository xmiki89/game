--[[
    rp_menu / client
    Kreismenü auf G. Es erscheint nur für Mitglieder einer Fraktion aus
    AllowedFactions - aktuell ausschliesslich Fraktion Nr. 1 (LSPD).

    Einträge: "Bodycam" legt eine Koerperkamera an die Brust (an/aus).
    Weitere Einträge einfach in Entries ergaenzen, sie erscheinen im Kreis
    im Uhrzeigersinn ab 12 Uhr.
--]]

-- Fraktionen, die das Menü öffnen dürfen
local AllowedFactions = {
    [1] = true, -- 1 = LSPD
}

-- Bodycam-Prop: das erste Modell aus dieser Liste, das im Spiel existiert,
-- wird benutzt. Wenn deine Bodycam nicht erscheint, hier den Modellnamen
-- deines eigenen Props eintragen (z.B. aus einem Addon-Pack).
local BodycamModels = {
    'prop_cs_bodycam',
    'prop_bodycam',
    'prop_bodycam_01',
}

-- Position der Kamera an der Brust (Bone 24818 = SKEL_Spine3)
local BodycamBone = 24818
local BodycamOffset = { x = 0.11, y = 0.10, z = 0.14 }
local BodycamRotation = { x = 0.0, y = 90.0, z = 0.0 }

local profile = nil
local isOpen = false

local bodycamObject = nil
local bodycamPed = nil

-- ------------------------------------------------------------- Bodycam

-- Probiert die Modelle der Reihe nach und gibt das erste ladbare zurück
local function loadBodycamModel()
    local candidates = {}

    for i = 1, #BodycamModels do
        local hash = GetHashKey(BodycamModels[i])
        if IsModelValid(hash) then
            candidates[#candidates + 1] = { hash = hash, name = BodycamModels[i] }
        end
    end

    -- Nichts vorab erkannt: trotzdem das erste Modell probieren, damit auch
    -- Addon-Modelle funktionieren, die erst beim Laden bekannt werden.
    if #candidates == 0 then
        candidates[1] = { hash = GetHashKey(BodycamModels[1]), name = BodycamModels[1] }
    end

    for i = 1, #candidates do
        local entry = candidates[i]
        RequestModel(entry.hash)

        local tries = 0
        while not HasModelLoaded(entry.hash) and tries < 50 do
            Wait(10)
            tries = tries + 1
        end

        if HasModelLoaded(entry.hash) then
            return entry.hash, entry.name
        end
    end

    return nil
end

local function removeBodycam()
    if bodycamObject and DoesEntityExist(bodycamObject) then
        DeleteEntity(bodycamObject)
    end
    bodycamObject = nil
    bodycamPed = nil
end

local function toggleBodycam()
    if bodycamObject and DoesEntityExist(bodycamObject) then
        removeBodycam()
        return false, 'Bodycam ausgezogen.'
    end

    local model, name = loadBodycamModel()
    if not model then
        print('^3[rp_menu]^7 Kein Bodycam-Modell gefunden. Bitte in BodycamModels eintragen.^7')
        return false, 'Kein Bodycam-Modell im Spiel gefunden.'
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local object = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    SetModelAsNoLongerNeeded(model)

    if not object or object == 0 then
        return false, 'Bodycam konnte nicht erstellt werden.'
    end

    AttachEntityToEntity(
        object, ped, GetPedBoneIndex(ped, BodycamBone),
        BodycamOffset.x, BodycamOffset.y, BodycamOffset.z,
        BodycamRotation.x, BodycamRotation.y, BodycamRotation.z,
        true, true, false, true, 1, true
    )

    bodycamObject = object
    bodycamPed = ped

    return true, ('Bodycam angelegt (%s).'):format(name)
end

-- Einträge im Kreismenü
local Entries = {
    {
        id = 'bodycam',
        label = 'Bodycam',
        stayOpen = true, -- Menü bleibt offen, damit man direkt wieder ausziehen kann
        action = toggleBodycam,
    },
}

-- ------------------------------------------------------------- Menü

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

-- Bodycam aufräumen, wenn der Spieler stirbt oder das Model wechselt
CreateThread(function()
    while true do
        Wait(1500)

        if bodycamObject then
            if not DoesEntityExist(bodycamObject) or not DoesEntityExist(bodycamPed)
                or bodycamPed ~= PlayerPedId() or IsEntityDead(PlayerPedId()) then
                removeBodycam()
            end
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
                local ok, message = entry.action()

                if entry.stayOpen then
                    SendNUIMessage({
                        action = 'hint',
                        data = { message = message, error = not ok },
                    })
                else
                    setOpen(false)
                end
            else
                SendNUIMessage({
                    action = 'hint',
                    data = { message = entry.hint or 'Diese Funktion ist noch nicht verfügbar.', error = true },
                })
            end
            return
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        removeBodycam()
        if isOpen then SetNuiFocus(false, false) end
    end
end)
