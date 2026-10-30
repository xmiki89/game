Config = {}

-- Name des Servers (wird im Tablet angezeigt)
Config.ServerName = 'Los Santos Life'

-- Spawnpunkt nach der Charaktererstellung (x, y, z, Blickrichtung)
-- Legion Square, Los Santos
Config.Spawn = vector4(-269.4, -957.3, 31.22, 205.0)

-- Startwerte für neue Charaktere
Config.StartCash = 500
Config.StartBank = 2500
Config.StartJob = 'Arbeitslos'

-- Speicherintervall der Spielerdaten (in Millisekunden)
Config.SaveInterval = 5 * 60 * 1000

-- Taste zum Öffnen des Tablets: 173 = Pfeil runter (INPUT_FRONTEND_DOWN)
-- Andere Tasten-IDs: https://docs.fivem.net/docs/game-references/controls/
Config.TabletControl = 173
