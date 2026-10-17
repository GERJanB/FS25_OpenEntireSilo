-- Konfiguration für luacheck, Aufruf im Repo-Wurzelordner: luacheck scripts tests
-- FS25 nutzt Lua 5.1 (LuaJIT)
std = "lua51"
max_line_length = 120

-- Spiel-APIs, die überall nur gelesen werden
read_globals = {
    "g_currentModName",
    "g_currentModDirectory",
    "addModEventListener",
    "Logging",
    "Utils",
    "DensityMapHeightUtil",
}

local writable = { read_only = false }

files["scripts"] = {
    globals = { "OpenEntireSilo" },
    read_globals = {
        -- der Mod darf nur die Funktionen ersetzen, an die er seine Hooks hängt
        BunkerSilo = {
            other_fields = true,
            fields = {
                openSilo = writable,
                onChangedFillLevelCallback = writable,
                loadFromXMLFile = writable,
                setState = writable,
                oesHooksInstalled = writable,
            },
        },
    },
    -- Callbacks wie loadMap/deleteMap haben eine feste Signatur, self bleibt dort oft ungenutzt
    self = false,
}

files["tests"] = {
    std = "+busted",
    -- die Stubs setzen die Globals nur über _G.X, direkte Zuweisungen fallen so auf
    read_globals = { "BunkerSilo", "OpenEntireSilo" },
}
