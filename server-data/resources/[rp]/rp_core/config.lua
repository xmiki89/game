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

-- Fraktion bei der Charaktererstellung (0 = keine Fraktion)
Config.StartFaction = 0

-- Fraktionen: Der Tabellenschlüssel ist die Fraktionsnummer.
-- Neue Fraktionen einfach mit der nächsten Nummer ergänzen.
Config.Factions = {
    [1] = {
        id = 1,
        short = 'LSPD',
        name = 'Los Santos Police Department',
        kind = 'Behörde',
        description = 'Die Polizei von Los Santos. Streifendienst in der City, Verkehrskontrollen, Absicherung von Einsätzen und Schutz der Bürger.',
        hqName = 'Mission Row Police Station',
        -- 440.2348, -983.1437, 33.0029, Blickrichtung 269.4280
        hq = vector4(440.2348, -983.1437, 33.0029, 269.4280),
    },
}
