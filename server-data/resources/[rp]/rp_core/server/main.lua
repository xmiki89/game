--[[
    rp_core / server
    Spielerdaten, Geld (Bargeld + Bank), Job und Speicherung.
    Gespeichert wird in data/players.json - es wird keine MySQL-Datenbank benötigt.

    Andere Ressourcen koennen die Exports nutzen:
        exports.rp_core:GetProfile(src)
        exports.rp_core:AddMoney(src, menge, 'cash'|'bank')
        exports.rp_core:RemoveMoney(src, menge, 'cash'|'bank')
        exports.rp_core:GetMoney(src, 'cash'|'bank')
--]]

local Players = {}   -- [serverId] = Profil (laufende Sitzung)
local Profiles = {}  -- [license]  = Profil (dauerhaft gespeichert)
local JoinedAt = {}  -- [serverId] = os.time()

-- ---------------------------------------------------------------- Hilfsfunktionen

local function getLicense(src)
    local identifiers = GetPlayerIdentifiers(src)
    if not identifiers then return nil end
    for i = 1, #identifiers do
        if identifiers[i]:find('^license:') then
            return identifiers[i]
        end
    end
    return nil
end

local function formatMoney(value)
    local text = tostring(math.floor(value))
    local thousands
    repeat
        text, thousands = text:gsub('^(-?%d+)(%d%d%d)', '%1.%2')
    until thousands == 0
    return text .. '$'
end

local function notify(src, message)
    TriggerClientEvent('chat:addMessage', src, {
        color = { 130, 200, 255 },
        multiline = true,
        args = { 'RP', message },
    })
end

-- ---------------------------------------------------------------- Speicherung

local function loadDatabase()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/players.json')
    if not raw or raw == '' then return {} end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print('^1[rp_core] data/players.json ist beschaedigt - es wird leer gestartet.^7')
        return {}
    end
    return decoded
end

local function saveDatabase()
    local ok, encoded = pcall(json.encode, Profiles)
    if not ok or not encoded then
        print('^1[rp_core] Spielerdaten konnten nicht serialisiert werden.^7')
        return
    end
    SaveResourceFile(GetCurrentResourceName(), 'data/players.json', encoded, -1)
end

Profiles = loadDatabase()

do
    local count = 0
    for _ in pairs(Profiles) do count = count + 1 end
    print(('^2[rp_core]^7 %d Spielerprofil(e) geladen.'):format(count))
end

-- ---------------------------------------------------------------- Profile

local function createProfile(license)
    return {
        license = license,
        created = false,           -- Charakter schon erstellt?
        firstName = '',
        lastName = '',
        birthdate = '',
        gender = 'm',              -- 'm' oder 'f'
        job = Config.StartJob,
        cash = Config.StartCash,
        bank = Config.StartBank,
        playtime = 0,              -- Spielzeit in Sekunden
        lastSeen = os.time(),
    }
end

-- Daten, die der Client sehen darf (ohne License-Identifier)
local function publicProfile(src, profile)
    return {
        serverId = tonumber(src),
        created = profile.created,
        firstName = profile.firstName,
        lastName = profile.lastName,
        birthdate = profile.birthdate,
        gender = profile.gender,
        job = profile.job,
        cash = profile.cash,
        bank = profile.bank,
    }
end

local function pushProfile(src)
    local profile = Players[tonumber(src)]
    if profile then
        TriggerClientEvent('rp_core:client:profile', tonumber(src), publicProfile(src, profile))
    end
end

function GetProfile(src)
    src = tonumber(src)
    if not src then return nil end
    if Players[src] then return Players[src] end

    local license = getLicense(src)
    if not license then return nil end

    local profile = Profiles[license]
    if not profile then
        profile = createProfile(license)
        Profiles[license] = profile
        print(('^3[rp_core]^7 Neues Profil angelegt: %s'):format(GetPlayerName(src) or 'unbekannt'))
    end

    Players[src] = profile
    JoinedAt[src] = os.time()

    if profile.created and #profile.firstName > 0 then
        local wanted = profile.firstName .. ' ' .. profile.lastName
        if GetPlayerName(src) ~= wanted then
            SetPlayerName(src, wanted)
        end
    end

    return profile
end

-- ---------------------------------------------------------------- Geld

function AddMoney(src, amount, account)
    local profile = GetProfile(src)
    if not profile then return false end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    account = (account == 'bank') and 'bank' or 'cash'
    profile[account] = profile[account] + amount
    pushProfile(src)
    return true
end

function RemoveMoney(src, amount, account)
    local profile = GetProfile(src)
    if not profile then return false end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    account = (account == 'bank') and 'bank' or 'cash'
    if profile[account] < amount then return false end

    profile[account] = profile[account] - amount
    pushProfile(src)
    return true
end

function GetMoney(src, account)
    local profile = GetProfile(src)
    if not profile then return 0 end
    account = (account == 'bank') and 'bank' or 'cash'
    return profile[account]
end

exports('GetProfile', GetProfile)
exports('AddMoney', AddMoney)
exports('RemoveMoney', RemoveMoney)
exports('GetMoney', GetMoney)

-- ---------------------------------------------------------------- Events: Client

RegisterNetEvent('rp_core:server:requestProfile', function()
    local src = source
    if GetProfile(src) then pushProfile(src) end
end)

-- Banküberweisung vom Tablet
RegisterNetEvent('rp_core:server:transfer', function(targetId, amount)
    local src = source
    local me = GetProfile(src)
    if not me or not me.created then return end

    targetId = tonumber(targetId)
    amount = math.floor(tonumber(amount) or 0)

    local function fail(message)
        notify(src, message)
        TriggerClientEvent('rp_tablet:client:feedback', src, false, message)
    end

    if not targetId or targetId == src then
        return fail('Ungueltiger Empfaenger.')
    end
    if amount < 1 then
        return fail('Ungueltiger Betrag.')
    end

    local target = GetProfile(targetId)
    if not target or not target.created then
        return fail('Spieler nicht gefunden.')
    end
    if me.bank < amount then
        return fail('Nicht genug Geld auf der Bank.')
    end

    me.bank = me.bank - amount
    target.bank = target.bank + amount

    pushProfile(src)
    pushProfile(targetId)
    saveDatabase()

    notify(src, ('Ueberweisung gesendet: %s an ID %d.'):format(formatMoney(amount), targetId))
    notify(targetId, ('Ueberweisung erhalten: %s von ID %d.'):format(formatMoney(amount), src))
    TriggerClientEvent('rp_tablet:client:feedback', src, true, ('%s an ID %d ueberwiesen.'):format(formatMoney(amount), targetId))
end)

-- Charaktererstellung abschliessen (kommt von rp_character)
local function cleanName(value)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
    if #value < 2 or #value > 24 then return nil end
    if value:find('[%c<>]') then return nil end
    return value
end

RegisterNetEvent('rp_core:server:characterSave', function(payload)
    local src = source
    local profile = GetProfile(src)
    if not profile then
        TriggerClientEvent('rp_character:client:saved', src, false, 'Spielerdaten konnten nicht geladen werden.')
        return
    end
    if profile.created then
        TriggerClientEvent('rp_character:client:saved', src, false, 'Du hast bereits einen Charakter.')
        return
    end
    if type(payload) ~= 'table' then
        TriggerClientEvent('rp_character:client:saved', src, false, 'Ungueltige Daten.')
        return
    end

    local firstName = cleanName(payload.firstName)
    local lastName = cleanName(payload.lastName)
    if not firstName or not lastName then
        TriggerClientEvent('rp_character:client:saved', src, false, 'Vor- und Nachname muessen 2 bis 24 Zeichen haben.')
        return
    end

    local birthdate = tostring(payload.birthdate or '')
    if not birthdate:match('^%d%d%.%d%d%.%d%d%d%d$') then
        TriggerClientEvent('rp_character:client:saved', src, false, 'Geburtsdatum bitte als TT.MM.JJJJ angeben.')
        return
    end

    profile.firstName = firstName
    profile.lastName = lastName
    profile.birthdate = birthdate
    profile.gender = (payload.gender == 'f') and 'f' or 'm'
    profile.created = true

    saveDatabase()
    SetPlayerName(src, firstName .. ' ' .. lastName)
    pushProfile(src)

    TriggerClientEvent('rp_character:client:saved', src, true)
    notify(src, ('Willkommen in Los Santos, %s %s!'):format(firstName, lastName))
end)

-- ---------------------------------------------------------------- Sitzung

AddEventHandler('playerDropped', function()
    local src = source
    local profile = Players[src]
    if not profile then return end

    if JoinedAt[src] then
        profile.playtime = (profile.playtime or 0) + (os.time() - JoinedAt[src])
    end
    profile.lastSeen = os.time()

    Players[src] = nil
    JoinedAt[src] = nil
    saveDatabase()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for src, profile in pairs(Players) do
        if JoinedAt[src] then
            profile.playtime = (profile.playtime or 0) + (os.time() - JoinedAt[src])
        end
        profile.lastSeen = os.time()
    end
    saveDatabase()
end)

-- Regelmäßiges Speichern
CreateThread(function()
    while true do
        Wait(Config.SaveInterval)
        saveDatabase()
    end
end)
