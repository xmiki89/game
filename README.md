# Los Santos Life – FiveM Roleplay / Reallife Server

Eigener, selbst geschriebener Roleplay-Server für GTA V / FiveM.
Kein ESX, kein QBCore – das Framework ist komplett standalone und ohne Datenbank lauffähig.

## Was drin ist

| Ressource | Aufgabe |
| --- | --- |
| `rp_core` | Spielerdaten, Bargeld + Bank, Job, Speicherung (`data/players.json`), Banküberweisungen |
| `rp_character` | Charaktererstellung beim ersten Join (Vor-/Nachname, Geburtsdatum, Geschlecht), Model + Spawn |
| `rp_hud` | HUD: Bargeld, Bank, Job, Server-ID, Uhrzeit |
| `rp_tablet` | Tablet-Menü auf **Pfeil runter**: Übersicht, Überweisen, Charakter, Regeln, Server |

## Voraussetzungen

- Windows-Server oder Windows-PC mit der FiveM-Server-Build (liegt bereits im Projektordner: `FXServer.exe` + DLLs)
- Ein kostenloser Lizenzschlüssel von <https://keymaster.fivem.net>
- Port `30120` (TCP + UDP) in der Firewall freigegeben

## Installation

1. **Lizenzschlüssel eintragen** – in [`server-data/server.cfg`](server-data/server.cfg):

   ```
   sv_licenseKey "DEIN_LIZENZKEY_HIER"
   ```

2. **Admin eintragen** (optional) – eigene Lizenz in derselben Datei aktivieren:

   ```
   add_principal identifier.license:DEINE_LICENSE group.admin
   ```

3. **Server starten** – einfach [`start-server.bat`](start-server.bat) doppelklicken, oder in der Konsole:

   ```
   cd server-data
   ..\FXServer.exe +exec server.cfg
   ```

   Wichtig: FXServer muss **aus dem Ordner `server-data`** gestartet werden, sonst findet er den
   Ordner `resources/` nicht. Beim Start müssen die Zeilen
   `Started resource rp_core`, `rp_character`, `rp_hud` und `rp_tablet` erscheinen.

4. **Verbinden** – im FiveM-Client mit der Konsole (`F8`):

   ```
   connect localhost:30120
   ```

   Für Freunde: `connect DEINE-IP:30120` (Port freigeben, ggf. `sv_endpointPrivacy` prüfen).

## Steuerung im Spiel

| Aktion | Taste |
| --- | --- |
| Tablet öffnen/schließen | **Pfeil runter** (oder Chat-Befehl `/tablet`) |
| Tablet schließen | `ESC` |

Die Taste ist in [`rp_core/config.lua`](server-data/resources/%5Brp%5D/rp_core/config.lua) über `Config.TabletControl` änderbar
(173 = Pfeil runter, siehe [Control-Liste](https://docs.fivem.net/docs/game-references/controls/)).

## Erster Start / erster Join

1. Spieler verbindet sich → Loading Screen
2. Charaktererstellung erscheint (Vor-/Nachname, Geburtsdatum, Geschlecht)
3. Nach dem Absenden: Freemode-Model, Standardkleidung, Spawn am Legion Square
4. Startguthaben: 500 $ Bargeld, 2.500 $ auf der Bank
5. HUD zeigt Geld, Job, Server-ID und Uhrzeit; das Tablet zeigt alle Daten und erlaubt Überweisungen

Alle Daten werden alle 5 Minuten und beim Verlassen des Servers gespeichert.

## Projektstruktur

```
FXServer.exe, *.dll, citizen/     FiveM-Server-Build (nicht im Git)
server-data/
├── server.cfg                    Serverkonfiguration
└── resources/
    └── [rp]/
        ├── rp_core/              Framework: Profile, Geld, Speicherung
        ├── rp_character/         Charaktererstellung + Spawn
        ├── rp_hud/               HUD
        └── rp_tablet/            Tablet (NUI)
```

## Für andere Ressourcen (Exports von `rp_core`)

```lua
local profile = exports.rp_core:GetProfile(source)     -- Profil eines Spielers
exports.rp_core:AddMoney(source, 250, 'cash')          -- Geld geben ('cash' oder 'bank')
exports.rp_core:RemoveMoney(source, 100, 'bank')       -- Geld abziehen
local cash = exports.rp_core:GetMoney(source, 'cash')  -- Kontostand lesen
```

Clientseitig verschickt `rp_core` bei jeder Änderung das Event `rp_core:client:profile`
(enthält `serverId`, `firstName`, `lastName`, `birthdate`, `gender`, `job`, `cash`, `bank`).

## Wenn der Server nicht startet

| Meldung | Ursache / Lösung |
| --- | --- |
| `Could not authenticate server license key. Invalid key format specified.` | In `server.cfg` steht noch `DEIN_LIZENZKEY_HIER`. Key auf <https://keymaster.fivem.net> erstellen und eintragen. `start-server.bat` prüft das inzwischen und zeigt eine Anleitung. |
| `Could not authenticate server license key. Invalid key specified.` | Key ist falsch abgetippt, abgelaufen oder gehört zu einem anderen Server – neu erstellen. |
| `Couldn't find resource rp_core` / nur wenige Ressourcen gefunden | FXServer wurde aus dem falschen Ordner gestartet. Immer aus `server-data` starten (`start-server.bat` macht das automatisch). |
| `Failed to bind on port 30120` | Port ist belegt (oft ein noch laufender alter Server). Alle `FXServer.exe` im Task-Manager beenden. |
| Server läuft, Client verbindet nicht von außen | Port `30120` TCP **und** UDP in der Windows-Firewall freigeben, ggf. Router-Portfreigabe einrichten. |
| `players.json` bleibt leer | Speicherung erfolgt alle 5 Minuten und beim Verlassen des Servers – vorher `/quit` oder Server ordentlich stoppen. |

## Nächste Ausbaustufen

Das Framework ist bewusst klein gehalten, damit Jobs, Fahrzeughandel, Immobilien oder Fraktionen
sauber darauf aufbauen können – ohne Abhängigkeit zu ESX/QBCore.

## Hinweise

- Die Server-Build (`FXServer.exe`, DLLs, `citizen/`) ist über `.gitignore` ausgenommen.
  Sie lässt sich jederzeit neu von <https://runtime.fivem.net/artifacts/fivem/> laden.
- `players.json` enthält Spieler-Identifiers und wird ebenfalls nicht committet.
- Der Server ist ohne Datenbank lauffähig; für viele Spieler lohnt sich später MySQL/oxmysql.
