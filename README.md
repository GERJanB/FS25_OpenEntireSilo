# FS25_OpenEntireSilo

Mod für FS25, um ein Fahrsilo komplett zu öffnen.

Im Basisspiel öffnet der Knopf „Silo öffnen“ nur den ersten Abschnitt, der Rest wird erst beim Entnehmen Stück für Stück freigelegt. Mit diesem Mod öffnet derselbe Knopf sofort das ganze Silo. Das gilt für alle Fahrsilos, die die Basisklasse `BunkerSilo` nutzen (Basisspiel, Karten, Mods), auch im Multiplayer.

**Stand:** Version 0.2.0.0. Funktion umgesetzt und mit Unit-Tests abgedeckt, noch nicht im Spiel getestet. Es gibt noch keine fertige ZIP zum Herunterladen, sie wird mit `build.sh` selbst gebaut (siehe [Bauen und lokal installieren](#bauen-und-lokal-installieren)).

## Funktionsweise

`scripts/OpenEntireSilo.lua` hängt sich schon beim Laden der Skriptdatei, also vor dem Laden der Karte, an die Spielklasse `BunkerSilo`. `setState` wird per `Utils.appendedFunction` ergänzt, die übrigen drei Funktionen per `Utils.overwrittenFunction`:

- `openSilo`: Nach dem Öffnen durch das Spiel wird der ganze Siloinhalt (gärender Inhalt und nach dem Abdecken noch obenauf gekipptes Häckselgut) in Silage umgewandelt, und beide Seiten werden als geöffnet markiert. Das passiert nur auf dem Server, nur wenn das Silo danach im Zustand „offen“ (`STATE_DRAIN`) ist und nur, wenn es vorher nicht schon an beiden Seiten geöffnet war. Höhenkarte und Flags synchronisiert das Spiel an die Clients.
- `onChangedFillLevelCallback`: Bei einem komplett geöffneten Silo wird die Originalfunktion übersprungen. Es gibt keine Öffnungskante mehr, die weitergeschoben werden müsste, und das Spiel sucht nicht mehr die ganze Silolänge nach gärendem Inhalt ab.
- `loadFromXMLFile`: Das Merkfeld `oesFullyOpened` („komplett geöffnet“) wird nicht im Spielstand gespeichert, sondern beim Laden abgeleitet: Silo im Zustand „offen“, an beiden Seiten geöffnet und kein gärender Inhalt mehr. Ein ohne den Mod an beiden Seiten geöffnetes Silo mit gärendem Rest zählt deshalb nicht als komplett geöffnet.
- `setState`: Setzt das Merkfeld zurück, sobald das Silo den Zustand „offen“ verlässt (leer oder wieder befüllt).

Der Mod-Event-Listener (`loadMap`) schreibt nur eine Meldung ins Log.

## Aufbau

```
modDesc.xml                  Einstieg für das Spiel (Titel, Beschreibung, Version, Skript)
icon_OpenEntireSilo.dds      Mod-Icon (512x512, DXT5 mit Mipmaps)
scripts/OpenEntireSilo.lua   Hauptskript (Hooks an BunkerSilo, Mod-Event-Listener für die Log-Meldung)
translations/                Übersetzungen (de, en), derzeit nur der noch ungenutzte Schlüssel oes_modName
build.sh                     Packt den Mod als ZIP nach dist/
tests/                       Unit-Tests (busted), nicht im ZIP
tests/helpers/fs25_stubs.lua Nachbau der Spiel-Globals für die Tests
.busted, .luacheckrc         Konfiguration für busted und luacheck
LICENSE                      GPL-3.0
```

## Bauen und lokal installieren

Mod-Ordner des Spiels:
- Windows: `Dokumente\My Games\FarmingSimulator2025\mods`
- Linux mit Steam/Proton: `~/.local/share/Steam/steamapps/compatdata/2300320/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/mods`

**Als ZIP (wie veröffentlicht):**
1. Im Repo-Wurzelordner `./build.sh` ausführen (braucht `zip`). Ergebnis: `dist/FS25_OpenEntireSilo.zip`.
2. Die ZIP-Datei ungeöffnet in den Mod-Ordner kopieren.

Ins ZIP kommen nur die Einträge der `INCLUDE`-Liste in `build.sh` (`modDesc.xml`, Icon, `scripts/`, `translations/`). `tests/`, `.busted`, `.luacheckrc`, README und LICENSE bleiben draußen, ebenso versteckte Dateien und Editor-Reste.

**Als Ordner (zum Entwickeln, ohne neu zu bauen):** das Repo per Symlink in den Mod-Ordner legen. Im Repo-Wurzelordner:
- Linux: `ln -s "$PWD" "<Mod-Ordner>/FS25_OpenEntireSilo"`
- Windows: `mklink /J "<Mod-Ordner>\FS25_OpenEntireSilo" "<Repo-Pfad>"`

Nie Ordner und ZIP gleichzeitig im Mod-Ordner haben, sonst ist der Mod doppelt vorhanden. Der Ordner- bzw. ZIP-Name muss `FS25_OpenEntireSilo` bleiben: Das Spiel leitet daraus den Mod-Namen ab (`g_currentModName`), unter dem auch Spielstände den Mod führen und den das Skript in seiner Log-Meldung nutzt.

Danach Spiel starten, den Mod beim Laden bzw. Anlegen des Spielstands auswählen und in der `log.txt` (liegt im Ordner `FarmingSimulator2025` neben `mods`) nach `[FS25_OpenEntireSilo] Mod geladen, Fahrsilos werden komplett geöffnet` suchen.

## Tests

Unit-Tests mit [busted](https://lunarmodules.github.io/busted/), Linter [luacheck](https://github.com/lunarmodules/luacheck), beide unter Lua 5.1. Die Spielfunktionen (`BunkerSilo`, `Utils`, `DensityMapHeightUtil` usw.) sind in `tests/helpers/fs25_stubs.lua` nachgebaut und schreiben ihre Aufrufe mit, das Spiel selbst wird nicht gebraucht. Skripte bleiben deshalb in Lua-5.1-Syntax (kein `+=`, kein `continue`).

Einmalig installieren. Dafür werden Lua 5.1 samt Headern, `luarocks` und ein C-Compiler gebraucht, weil busted einige C-Module baut:
- Arch: `lua51`, `luarocks`, `base-devel`
- Debian/Ubuntu: `lua5.1`, `liblua5.1-0-dev`, `luarocks`, `build-essential`

```bash
luarocks --local --lua-version=5.1 install busted
luarocks --local --lua-version=5.1 install luacheck
```

Im Repo-Wurzelordner ausführen:

```bash
eval "$(luarocks --lua-version=5.1 path)"
busted
luacheck scripts tests
```

## Lizenz

GPL-3.0, siehe [LICENSE](LICENSE).
