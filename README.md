# Los Santos Life – FiveM Roleplay / Reallife Server

Eigener, selbst geschriebener Roleplay-Server für GTA V / FiveM.
Kein ESX, kein QBCore – das Framework ist komplett standalone und ohne Datenbank lauffähig.

## Was drin ist

| Ressource | Aufgabe |
| --- | --- |
| `rp_core` | Spielerdaten, Bargeld + Bank, Job, Speicherung (`data/players.json`), Banküberweisungen |
| `rp_character` | Charaktererstellung beim ersten Join (Vor-/Nachname, Geburtsdatum, Geschlecht), Model + Spawn |
| `rp_hud` | HUD: Bargeld, Bank, Job, Server-ID, Uhrzeit |
| `rp_tablet` | Tablet-Menü auf **Pfeil runter**: Übersicht, Jobs (Standort + Route auf der Karte), Fraktion (LSPD mit HQ + Route), Überweisen, Charakter, Regeln, Admin (nur nach `/admin <Passwort>`) |
| `rp_menu` | Kreismenü auf **G** – erscheint nur für Fraktion Nr. 1 (LSPD), aktuell mit dem Eintrag **Bodycam** (noch ohne Funktion) |
| `mapmanager`, `spawnmanager`, `chat` | offizielle Cfx.re-Basissysteme – ohne sie spawnt kein Spieler und es gibt keinen Chat |

## Voraussetzungen

- Windows-Server oder Windows-PC mit der FiveM-Server-Build (liegt bereits im Projektordner: `FXServer.exe` + DLLs)
- Ein kostenloser Lizenzschlüssel von <https://keymaster.fivem.net>
- Port `30120` (TCP + UDP) in der Firewall freigegeben

## Installation

1. **Lizenzschlüssel eintragen** – in der Datei `server-data/license.cfg`
   (die `server.cfg` lädt sie per `exec license.cfg`):

   ```
   sv_licenseKey "DEIN_LIZENZKEY_HIER"
   ```

   `license.cfg` steht in `.gitignore` und landet deshalb nicht auf GitHub – als Vorlage dient
   [`license.example.cfg`](server-data/license.example.cfg).`start-server.bat` legt sie beim ersten
   Start automatisch an.

2. **Admin-Passwort festlegen** (optional) – in `server-data/admin.cfg`
   (Vorlage: [`admin.example.cfg`](server-data/admin.example.cfg), wird ebenfalls nicht committet):

   ```
   setr rp_adminPassword "dein-passwort"
   ```

   Damit schaltest du im Spiel per `/admin dein-passwort` den Admin-Tab im Tablet frei
   (Details unter [Admin-Modus](#admin-modus)).

3. **ACE-Admin eintragen** (optional) – eigene Lizenz in `license.cfg` aktivieren:

   ```
   add_principal identifier.license:DEINE_LICENSE group.admin
   ```

4. **Server starten** – einfach [`start-server.bat`](start-server.bat) doppelklicken, oder in der Konsole:

   ```
   cd server-data
   ..\FXServer.exe +exec server.cfg
   ```

   Wichtig: FXServer muss **aus dem Ordner `server-data`** gestartet werden, sonst findet er den
   Ordner `resources/` nicht. Beim Start müssen die Zeilen
   `Started resource rp_core`, `rp_character`, `rp_hud`, `rp_tablet` und `rp_menu` erscheinen.

5. **Verbinden** – im FiveM-Client mit der Konsole (`F8`):

   ```
   connect localhost:30120
   ```

   Für Freunde: `connect DEINE-IP:30120` (Port freigeben, ggf. `sv_endpointPrivacy` prüfen).

## Steuerung im Spiel

| Aktion | Taste |
| --- | --- |
| Tablet öffnen/schließen | **Pfeil runter** (oder Chat-Befehl `/tablet`) |
| Tablet schließen | `ESC` |
| Kreismenü öffnen/schließen (nur Fraktion 1) | **G** (oder Chat-Befehl `/factionmenu`) |
| Kreismenü schließen | `ESC` |
| Admin-Modus freischalten | Chat: `/admin <Passwort>` |

Die Taste **G** lässt sich in den FiveM-Einstellungen unter *Einstellungen → Tastenbelegung → FiveM*
neu belegen. Der Eintrag heißt dort „Kreismenü (Fraktion)“.

Die Taste ist in [`rp_core/config.lua`](server-data/resources/%5Brp%5D/rp_core/config.lua) über `Config.TabletControl` änderbar
(173 = Pfeil runter, siehe [Control-Liste](https://docs.fivem.net/docs/game-references/controls/)).

## Admin-Modus

Der Admin-Tab im Tablet wird per Chat-Befehl freigeschaltet:

```
/admin nero89
```

Das Passwort steht in `server-data/admin.cfg` (nicht im Git, Vorlage: [`admin.example.cfg`](server-data/admin.example.cfg)): 

```
setr rp_adminPassword "dein-passwort"
```

Nach korrektem Passwort erscheint im Tablet der Tab **Admin**:

| Funktion | Wirkung |
| --- | --- |
| Liste | alle Spieler online mit RP-Name und aktueller Fraktion |
| Fraktion wählen + **Setzen** | schreibt die Fraktion ins Profil (sofort sichtbar, wird gespeichert) |
| **Spawn HQ** | setzt den Spieler an das Hauptquartier seiner Fraktion (Blickrichtung aus `Config.Factions`) |
| Aktualisieren | holt die Liste neu (Spieler betreten/verlassen den Server) |

Der Admin-Modus gilt nur für die laufende Sitzung – nach einem Reconnect wieder `/admin` eingeben.
Träger der ACE-Berechtigung `rp.admin` sehen den Tab ohne Passwort.

> Hinweis: Der Befehl wird im Chat getippt und taucht deshalb in Chat-Logs auf.
> Verwende ein eigenes Passwort, das du nirgendwo sonst benutzt.

## Fraktionen

Fraktionen stehen in [`rp_core/config.lua`](server-data/resources/%5Brp%5D/rp_core/config.lua) unter `Config.Factions`.
Der Tabellenschlüssel ist die Fraktionsnummer.

| Nr. | Kürzel | Name | HQ |
| --- | --- | --- | --- |
| 1 | LSPD | Los Santos Police Department | Mission Row Police Station – `440.23, -983.14, 33.00` |

**Fraktion vergeben** – in der txAdmin-Konsole (oder FXServer-Konsole):

```
setfaction 1 1
```

Das ist `setfaction <Server-ID> <Fraktionsnummer>`; `setfaction 1 0` nimmt die Fraktion wieder weg.
Im Spiel funktioniert der Befehl nur mit Admin-Rechten (`rp.admin`, siehe Schritt 2 der Installation).

Mit Fraktion Nr. 1 siehst du außerdem das Kreismenü auf **G**. Es ist bewusst leer – der einzige
Eintrag ist **Bodycam**, der noch nichts tut.

Neue Fraktionen: einfach einen weiteren Eintrag mit der nächsten Nummer in `Config.Factions` anlegen –
Tablet und Kreismenü lesen die Liste automatisch. Für ein neues Kreismenü-Fraktionsmitglied in
[`rp_menu/client.lua`](server-data/resources/%5Brp%5D/rp_menu/client.lua) die Nummer in `AllowedFactions` ergänzen.

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
├── license.cfg                   Lizenzschlüssel (nicht im Git)
├── admin.cfg                     Admin-Passwort für /admin (nicht im Git)
└── resources/
    ├── [managers]/
    │   ├── mapmanager/           offiziell: Map-Streaming
    │   └── spawnmanager/         offiziell: Spieler-Spawning
    ├── [system]/
    │   └── chat/                 offiziell: Chat
    └── [rp]/
        ├── rp_core/              Framework: Profile, Geld, Speicherung
        ├── rp_character/         Charaktererstellung + Spawn
        ├── rp_hud/               HUD
        ├── rp_tablet/            Tablet (NUI)
        └── rp_menu/              Kreismenü auf G (NUI)
```

## Für andere Ressourcen (Exports von `rp_core`)

```lua
local profile = exports.rp_core:GetProfile(source)     -- Profil eines Spielers
exports.rp_core:AddMoney(source, 250, 'cash')          -- Geld geben ('cash' oder 'bank')
exports.rp_core:RemoveMoney(source, 100, 'bank')       -- Geld abziehen
local cash = exports.rp_core:GetMoney(source, 'cash')  -- Kontostand lesen
local faction = exports.rp_core:GetFaction(source)      -- Fraktionsnummer (0 = keine)
exports.rp_core:SetFaction(source, 1)                  -- Fraktion setzen (1 = LSPD)
```

Clientseitig verschickt `rp_core` bei jeder Änderung das Event `rp_core:client:profile`
(enthält `serverId`, `firstName`, `lastName`, `birthdate`, `gender`, `job`, `faction`, `cash`, `bank`).

## Wenn der Server nicht startet

| Meldung | Ursache / Lösung |
| --- | --- |
| `Could not authenticate server license key. Invalid key format specified.` | In `server.cfg` steht noch `DEIN_LIZENZKEY_HIER`. Key auf <https://keymaster.fivem.net> erstellen und eintragen. `start-server.bat` prüft das inzwischen und zeigt eine Anleitung. |
| `Could not authenticate server license key. Invalid key specified.` | Key ist falsch abgetippt, abgelaufen oder gehört zu einem anderen Server – neu erstellen. |
| `Couldn't find resource rp_core` / nur wenige Ressourcen gefunden | FXServer wurde aus dem falschen Ordner gestartet. Immer aus `server-data` starten (`start-server.bat` macht das automatisch). |
| `Failed to bind on port 30120` | Port ist belegt (oft ein noch laufender alter Server). Alle `FXServer.exe` im Task-Manager beenden. |
| Server läuft, Client verbindet nicht von außen | Port `30120` TCP **und** UDP in der Windows-Firewall freigeben, ggf. Router-Portfreigabe einrichten. |
| `players.json` bleibt leer | Speicherung erfolgt alle 5 Minuten und beim Verlassen des Servers – vorher `/quit` oder Server ordentlich stoppen. |
| `Couldn't find resource mapmanager / chat / spawnmanager` | Diese Pflicht-Ressourcen fehlen in `server-data/resources`. Sie liegen hier bereits bei – wenn die Meldung kommt, wurde der falsche `resources`-Ordner geladen. |
| txAdmin: `Failed to get processes tree usage data` / `wmic` fehlt | Harmlos, nur die CPU-/RAM-Statistik im txAdmin-Dashboard fehlt. Fix: Windows-Einstellungen → „Optionale Features“ → „WMIC“ installieren, oder Meldung ignorieren. |
| Spieler bleibt im Ladebildschirm | `spawnmanager` läuft nicht (siehe oben) – er beendet den Ladebildschirm. |

## Nächste Ausbaustufen

Das Framework ist bewusst klein gehalten, damit Jobs, Fahrzeughandel, Immobilien oder Fraktionen
sauber darauf aufbauen können – ohne Abhängigkeit zu ESX/QBCore.

## Hinweise

- Die Server-Build (`FXServer.exe`, DLLs, `citizen/`) ist über `.gitignore` ausgenommen.
  Sie lässt sich jederzeit neu von <https://runtime.fivem.net/artifacts/fivem/> laden.
- `players.json` enthält Spieler-Identifiers und wird ebenfalls nicht committet.
- Der Server ist ohne Datenbank lauffähig; für viele Spieler lohnt sich später MySQL/oxmysql.
