--[[
    rp_character / client
    Zeigt beim ersten Join die Charaktererstellung (NUI) und setzt
    anschliessend Model, Kleidung und Spawnpunkt.
--]]

local uiOpen = false
local hasCharacter = false
local spawned = false
local selectedGender = 'm'

-- Konfiguration aus rp_core holen (Spawnpunkt)
local ok, coreConfig = pcall(function()
    return exports.rp_core:GetConfig()
end)

local spawnCoords = (ok and coreConfig and coreConfig.spawn) or vector4(-269.4, -957.3, 31.22, 205.0)

local function setUi(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'visibility', value = state })
end

local function freezePlayer(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    SetPlayerControl(PlayerId(), not state, 0)
    SetEntityInvincible(ped, state)
end

local function requestModel(model)
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 200 do
        Wait(10)
        tries = tries + 1
    end
    return HasModelLoaded(model)
end

local function placeAtSpawn()
    local coords = spawnCoords
    local ped = PlayerPedId()
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
end

local function teleportToSpawn()
    DoScreenFadeOut(400)
    Wait(500)
    placeAtSpawn()
    Wait(700)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(700)

    -- Falls spawnmanager kurz nach uns nochmal spawnt, Position halten
    SetTimeout(2500, function()
        if spawned then placeAtSpawn() end
    end)
end

local function finishCharacter(gender)
    if spawned then return end
    spawned = true

    local model = (gender == 'f') and `mp_f_freemode_01` or `mp_m_freemode_01`
    if requestModel(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        Wait(100)
        SetPedDefaultComponentVariation(PlayerPedId())
    end

    freezePlayer(false)
    teleportToSpawn()
    LocalPlayer.state:set('charReady', true, false)
end

local function openCreator()
    if uiOpen or hasCharacter or spawned then return end
    freezePlayer(true)
    setUi(true)
end

-- ------------------------------------------------------------- Profil vom Server

RegisterNetEvent('rp_core:client:profile', function(profile)
    if type(profile) ~= 'table' then return end

    if not profile.created then
        openCreator()
        return
    end

    hasCharacter = true
    selectedGender = profile.gender or 'm'
    if uiOpen then setUi(false) end
    finishCharacter(selectedGender)
end)

-- ------------------------------------------------------------- NUI

RegisterNUICallback('submit', function(data, cb)
    cb({ ok = true })
    if type(data) ~= 'table' then return end

    selectedGender = (data.gender == 'f') and 'f' or 'm'

    TriggerServerEvent('rp_core:server:characterSave', {
        firstName = data.firstName,
        lastName = data.lastName,
        birthdate = data.birthdate,
        gender = selectedGender,
    })
end)

RegisterNetEvent('rp_character:client:saved', function(ok, reason)
    if not ok then
        SendNUIMessage({ action = 'error', message = reason or 'Charakter konnte nicht gespeichert werden.' })
        return
    end

    hasCharacter = true
    if uiOpen then setUi(false) end
    finishCharacter(selectedGender)
end)

-- ------------------------------------------------------------- Start

CreateThread(function()
    LocalPlayer.state:set('charReady', false, false)
    Wait(1200)
    TriggerServerEvent('rp_core:server:requestProfile')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and uiOpen then
        SetNuiFocus(false, false)
    end
end)
