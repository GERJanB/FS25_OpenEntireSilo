#!/usr/bin/env bash
# Packt den Mod als FS25_OpenEntireSilo.zip nach dist/.
# Nur die Dateien, die das Spiel braucht, landen im ZIP (kein README, LICENSE, .git usw.).
set -euo pipefail

MOD_NAME="FS25_OpenEntireSilo"

# Alles, was ins ZIP gehört. Neue Ordner (z. B. i3d/, textures/, sounds/) hier ergänzen.
INCLUDE=(
    modDesc.xml
    icon_OpenEntireSilo.dds
    scripts
    translations
)

cd "$(dirname "$0")"

mkdir -p dist
rm -f "dist/${MOD_NAME}.zip"
# -MM: Abbruch, wenn eine Datei aus INCLUDE fehlt; -x: Editor-Reste und versteckte Dateien weglassen
zip -r -X -MM "dist/${MOD_NAME}.zip" "${INCLUDE[@]}" \
    -x '*~' '*.swp' '.*' '*/.*'

echo "Erstellt: dist/${MOD_NAME}.zip"
