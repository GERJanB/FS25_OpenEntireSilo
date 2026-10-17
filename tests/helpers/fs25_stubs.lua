--
-- Nachbau der Spiel-Globals, die scripts/OpenEntireSilo.lua benutzt.
-- Nur so viel wie nötig, die Utils-Funktionen entsprechen der Semantik des Spiels.
--
-- Jeder Aufruf einer Spielfunktion landet in stubs.calls (in Aufrufreihenfolge),
-- damit die Specs Reihenfolge und Argumente prüfen können.
--

local stubs = {}

stubs.MOD_NAME = "FS25_OpenEntireSilo"
stubs.MOD_DIRECTORY = "/mods/FS25_OpenEntireSilo/"
stubs.SCRIPT_PATH = "scripts/OpenEntireSilo.lua"

-- Fülltypen als Zahlen wie im Spiel (FillType.*), Werte frei gewählt
stubs.FILLTYPE_INPUT = 11      -- Häckselgut
stubs.FILLTYPE_FERMENTING = 12 -- gärender Inhalt
stubs.FILLTYPE_OUTPUT = 13     -- Silage

local function record(name, ...)
    local entry = { name = name, n = select("#", ...), args = { ... } }
    table.insert(stubs.calls, entry)
    return entry
end

-- Alle Aufrufe mit diesem Namen, in Reihenfolge
function stubs.callsTo(name)
    local result = {}
    for _, entry in ipairs(stubs.calls) do
        if entry.name == name then
            table.insert(result, entry)
        end
    end
    return result
end

-- Setzt alle Globals frisch, ohne Mod-Skript
function stubs.install()
    stubs.calls = {}
    stubs.modEventListeners = {}
    -- Rückgabe von DensityMapHeightUtil.getFillLevelAtArea
    stubs.fermentingFillLevel = 0
    -- Rückgabe der originalen BunkerSilo:loadFromXMLFile
    stubs.loadFromXMLFileResult = true

    _G.g_currentModName = stubs.MOD_NAME
    _G.g_currentModDirectory = stubs.MOD_DIRECTORY

    _G.addModEventListener = function(listener)
        table.insert(stubs.modEventListeners, listener)
    end

    _G.Logging = {
        info = function(...) record("Logging.info", ...) end,
        warning = function(...) record("Logging.warning", ...) end,
        error = function(...) record("Logging.error", ...) end,
    }

    -- wie im Spiel (dataS/scripts/utils/Utils.lua)
    _G.Utils = {
        overwrittenFunction = function(oldFunc, newFunc)
            return function(self, ...)
                return newFunc(self, oldFunc, ...)
            end
        end,
        appendedFunction = function(oldFunc, newFunc)
            if oldFunc ~= nil then
                return function(...)
                    oldFunc(...)
                    newFunc(...)
                end
            end
            return newFunc
        end,
    }

    _G.DensityMapHeightUtil = {
        changeFillTypeAtArea = function(...)
            record("DensityMapHeightUtil.changeFillTypeAtArea", ...)
        end,
        getFillLevelAtArea = function(...)
            record("DensityMapHeightUtil.getFillLevelAtArea", ...)
            return stubs.fermentingFillLevel
        end,
    }

    -- Klasse mit den Funktionen, die der Mod umschließt. Die Originale schreiben nur mit,
    -- setState setzt zusätzlich den Zustand wie das Spiel.
    local BunkerSilo = {
        STATE_FILL = 0,
        STATE_CLOSED = 1,
        STATE_FERMENTED = 2,
        STATE_DRAIN = 3,
    }
    local BunkerSilo_mt = { __index = BunkerSilo }
    stubs.BunkerSilo_mt = BunkerSilo_mt

    function BunkerSilo:openSilo(...)
        record("BunkerSilo.openSilo", self, ...)
        if stubs.onOriginalOpenSilo ~= nil then
            stubs.onOriginalOpenSilo(self, ...)
        end
    end

    function BunkerSilo:onChangedFillLevelCallback(...)
        record("BunkerSilo.onChangedFillLevelCallback", self, ...)
    end

    function BunkerSilo:loadFromXMLFile(...)
        record("BunkerSilo.loadFromXMLFile", self, ...)
        return stubs.loadFromXMLFileResult
    end

    function BunkerSilo:setState(state, ...)
        record("BunkerSilo.setState", self, state, ...)
        self.state = state
    end

    function BunkerSilo:raiseDirtyFlags(...)
        record("BunkerSilo.raiseDirtyFlags", self, ...)
    end

    -- vom Test aus aufrufbar, um die Originale vor dem Hook zu prüfen
    stubs.originals = {
        openSilo = BunkerSilo.openSilo,
        onChangedFillLevelCallback = BunkerSilo.onChangedFillLevelCallback,
        loadFromXMLFile = BunkerSilo.loadFromXMLFile,
        setState = BunkerSilo.setState,
    }
    stubs.onOriginalOpenSilo = nil

    _G.BunkerSilo = BunkerSilo
    _G.OpenEntireSilo = nil
end

-- Globals neu setzen und das Mod-Skript laden wie das Spiel (extraSourceFiles)
function stubs.loadMod()
    stubs.install()
    dofile(stubs.SCRIPT_PATH)
    return _G.OpenEntireSilo
end

-- Fake-Silo, standardmäßig Server, frisch geöffnet (Zustand DRAIN, nur vorne offen).
-- Eckpunkte der Silofläche wie bunkerSiloArea im Spiel (Start, Breite, Höhe).
function stubs.newSilo(overrides)
    local silo = {
        isServer = true,
        state = _G.BunkerSilo.STATE_DRAIN,
        isOpenedAtFront = true,
        isOpenedAtBack = false,
        bunkerSiloDirtyFlag = 4,
        inputFillType = stubs.FILLTYPE_INPUT,
        fermentingFillType = stubs.FILLTYPE_FERMENTING,
        outputFillType = stubs.FILLTYPE_OUTPUT,
        bunkerSiloArea = { sx = 1, sz = 2, wx = 3, wz = 4, hx = 5, hz = 6 },
    }
    for key, value in pairs(overrides or {}) do
        silo[key] = value
    end
    return setmetatable(silo, stubs.BunkerSilo_mt)
end

return stubs
