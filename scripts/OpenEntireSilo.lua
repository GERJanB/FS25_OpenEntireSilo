--
-- OpenEntireSilo
--
-- Öffnet ein Silo komplett. Bisher nur das Grundgerüst, noch ohne Funktion.
--
-- Author: Jan
-- License: GPL-3.0 (siehe LICENSE)
--

OpenEntireSilo = {}

-- g_currentModName und g_currentModDirectory sind nur beim Laden dieser Datei gültig
OpenEntireSilo.MOD_NAME = g_currentModName
OpenEntireSilo.MOD_DIRECTORY = g_currentModDirectory

-- Karte geladen, g_currentMission existiert
function OpenEntireSilo:loadMap(filename)
    Logging.info("[%s] Mod geladen", OpenEntireSilo.MOD_NAME)
end

-- Spielstand wird verlassen, hier später alles aufräumen
function OpenEntireSilo:deleteMap()
end

addModEventListener(OpenEntireSilo)
