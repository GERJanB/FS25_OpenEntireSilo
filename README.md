# FS25_OpenEntireSilo

Mod für FS25, um ein Silo komplett zu öffnen.

**Stand:** Grundgerüst, noch ohne Funktion. Der Mod lädt und schreibt beim Laden eines Spielstands eine Zeile in die `log.txt`.

## Aufbau

```
modDesc.xml                  Einstieg für das Spiel (Titel, Version, Skripte, Übersetzungen)
icon_OpenEntireSilo.dds      Mod-Icon (Platzhalter, 512x512)
scripts/OpenEntireSilo.lua   Haupt-Skript (globaler Mod Event Listener)
translations/                Übersetzungen (de, en)
build.sh                     Packt den Mod als ZIP nach dist/
```

## Bauen und testen

Mod-Ordner des Spiels:
- Windows: `Dokumente\My Games\FarmingSimulator2025\mods`
- Linux mit Steam/Proton: `~/.local/share/Steam/steamapps/compatdata/<AppID>/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/mods`

**Als ZIP (wie veröffentlicht):**
1. `./build.sh` ausführen (braucht `zip`). Ergebnis: `dist/FS25_OpenEntireSilo.zip`.
2. Die ZIP in den Mod-Ordner kopieren.

**Als Ordner (zum Entwickeln, ohne neu zu bauen):** das Repo per Symlink in den Mod-Ordner legen, z. B.
`ln -s ~/Dev/fsModding/FS25_OpenEntireSilo "<Mod-Ordner>/FS25_OpenEntireSilo"`.
Nie Ordner und ZIP gleichzeitig im Mod-Ordner haben, sonst ist der Mod doppelt vorhanden.

Danach Spiel starten, Mod im Spielstand aktivieren und in der `log.txt` nach `[FS25_OpenEntireSilo] Mod geladen` suchen.

Der Ordner- bzw. ZIP-Name muss `FS25_OpenEntireSilo` bleiben, er ist zugleich der Mod-Name im Code.

## Lizenz

GPL-3.0, siehe [LICENSE](LICENSE).
