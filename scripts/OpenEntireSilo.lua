--
-- OpenEntireSilo
--
-- Öffnet ein Fahrsilo mit dem Knopf "Silo öffnen" sofort komplett statt nur
-- den ersten Abschnitt. Gilt für alle Fahrsilos, die die Basisklasse BunkerSilo
-- nutzen (Basisspiel, Karten, Mods).
--
-- Author: Jan
-- License: GPL-3.0 (siehe LICENSE)
--

OpenEntireSilo = {}

-- g_currentModName und g_currentModDirectory sind nur beim Laden dieser Datei gültig
OpenEntireSilo.MOD_NAME = g_currentModName
OpenEntireSilo.MOD_DIRECTORY = g_currentModDirectory

-- Wandelt den gesamten Siloinhalt in Silage um: gärenden Inhalt und Häckselgut,
-- das nach dem Abdecken noch obenauf gekippt wurde. Dieselben Eckpunkte nutzt
-- BunkerSilo:loadFromXMLFile für ein offenes Silo.
function OpenEntireSilo.convertEntireSilo(silo)
    local area = silo.bunkerSiloArea
    DensityMapHeightUtil.changeFillTypeAtArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz,
        silo.fermentingFillType, silo.outputFillType)
    DensityMapHeightUtil.changeFillTypeAtArea(area.sx, area.sz, area.wx, area.wz, area.hx, area.hz,
        silo.inputFillType, silo.outputFillType)
end

-- Gibt true zurück, wenn im Silo kein gärender Inhalt mehr liegt
function OpenEntireSilo.getHasNoFermentingLeft(silo)
    local area = silo.bunkerSiloArea
    local fillLevel = DensityMapHeightUtil.getFillLevelAtArea(silo.fermentingFillType,
        area.sx, area.sz, area.wx, area.wz, area.hx, area.hz)
    return fillLevel <= 0
end

-- Hook für BunkerSilo:openSilo (läuft nur auf dem Server, aufgerufen von BunkerSiloOpenEvent)
function OpenEntireSilo.openSilo(silo, superFunc, px, py, pz)
    local wasFullyOpen = silo.isOpenedAtFront and silo.isOpenedAtBack
    superFunc(silo, px, py, pz)

    -- kein doppelter Knopfdruck, nur wenn das Silo jetzt offen ist
    if not silo.isServer or wasFullyOpen or silo.state ~= BunkerSilo.STATE_DRAIN then
        return
    end

    OpenEntireSilo.convertEntireSilo(silo)

    silo.isOpenedAtFront = true
    silo.isOpenedAtBack = true
    silo.oesFullyOpened = true
    silo:raiseDirtyFlags(silo.bunkerSiloDirtyFlag)
end

-- Hook für BunkerSilo.onChangedFillLevelCallback (Schaufel entnimmt Material, nur Server).
-- Bei einem komplett geöffneten Silo gibt es keine Öffnungskante mehr zum Weiterschieben.
-- Ohne diesen Hook würde das Spiel die ganze Silolänge vergeblich nach gärendem Inhalt absuchen.
function OpenEntireSilo.onChangedFillLevelCallback(silo, superFunc, vehicle, fillDelta, fillType, x, y, z)
    if silo.oesFullyOpened then
        return
    end
    superFunc(silo, vehicle, fillDelta, fillType, x, y, z)
end

-- Hook für BunkerSilo:loadFromXMLFile. Das Merkfeld wird nicht gespeichert, sondern beim
-- Laden aus dem Silo abgeleitet: offen an beiden Seiten und kein gärender Rest mehr.
-- So greift der Callback-Hook nicht bei einem Silo, das ohne den Mod von beiden Enden
-- geöffnet wurde und noch gärenden Inhalt hat.
function OpenEntireSilo.loadFromXMLFile(silo, superFunc, xmlFile, key)
    local result = superFunc(silo, xmlFile, key)

    silo.oesFullyOpened = silo.state == BunkerSilo.STATE_DRAIN
        and silo.isOpenedAtFront and silo.isOpenedAtBack
        and OpenEntireSilo.getHasNoFermentingLeft(silo)

    return result
end

-- Hook für BunkerSilo:setState. Sobald das Silo den Zustand "offen" verlässt
-- (leer, wieder befüllt), gilt es nicht mehr als komplett geöffnet.
function OpenEntireSilo.setState(silo, _state, _showNotification)
    if silo.state ~= BunkerSilo.STATE_DRAIN then
        silo.oesFullyOpened = false
    end
end

function OpenEntireSilo.installHooks()
    -- nicht doppelt umschließen, falls die Datei erneut geladen wird
    if BunkerSilo.oesHooksInstalled then
        return
    end
    BunkerSilo.oesHooksInstalled = true

    BunkerSilo.openSilo = Utils.overwrittenFunction(BunkerSilo.openSilo, OpenEntireSilo.openSilo)
    BunkerSilo.onChangedFillLevelCallback = Utils.overwrittenFunction(BunkerSilo.onChangedFillLevelCallback,
        OpenEntireSilo.onChangedFillLevelCallback)
    BunkerSilo.loadFromXMLFile = Utils.overwrittenFunction(BunkerSilo.loadFromXMLFile, OpenEntireSilo.loadFromXMLFile)
    BunkerSilo.setState = Utils.appendedFunction(BunkerSilo.setState, OpenEntireSilo.setState)
end

-- Beim Laden der Skriptdatei, also bevor die Karte und ihre Silos geladen werden
OpenEntireSilo.installHooks()

-- Karte geladen, g_currentMission existiert
function OpenEntireSilo:loadMap(_filename)
    Logging.info("[%s] Mod geladen, Fahrsilos werden komplett geöffnet", OpenEntireSilo.MOD_NAME)
end

-- Spielstand wird verlassen, hier später alles aufräumen
function OpenEntireSilo:deleteMap()
end

addModEventListener(OpenEntireSilo)
