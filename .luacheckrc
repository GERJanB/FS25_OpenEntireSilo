-- Konfiguration für luacheck, Aufruf im Repo-Wurzelordner: luacheck scripts tests
-- FS25 nutzt Lua 5.1 (LuaJIT)
std = "lua51"
max_line_length = 120

-- Spiel-APIs, die das Mod-Skript nur liest
read_globals = {
    "g_currentModName",
    "g_currentModDirectory",
    "addModEventListener",
    "Logging",
    "Utils",
    "DensityMapHeightUtil",
}

files["scripts"] = {
    globals = {
        "OpenEntireSilo",
        -- der Mod hängt seine Hooks an die Spielklasse
        "BunkerSilo",
    },
}

files["tests"] = {
    std = "+busted",
    -- die Stubs setzen die Spiel-Globals selbst, das Mod-Skript setzt OpenEntireSilo
    globals = {
        "g_currentModName",
        "g_currentModDirectory",
        "addModEventListener",
        "Logging",
        "Utils",
        "DensityMapHeightUtil",
        "BunkerSilo",
        "OpenEntireSilo",
    },
}

-- Callbacks wie loadMap/deleteMap haben eine feste Signatur, self bleibt dort oft ungenutzt
self = false
