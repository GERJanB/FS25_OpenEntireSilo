local stubs = require("tests.helpers.fs25_stubs")

-- Erwartete Eckpunkte von stubs.newSilo() in der Reihenfolge des Spiels
local AREA = { 1, 2, 3, 4, 5, 6 }

local function areaArgs(...)
    local args = {}
    for _, value in ipairs(AREA) do
        table.insert(args, value)
    end
    for _, value in ipairs({ ... }) do
        table.insert(args, value)
    end
    return args
end

describe("OpenEntireSilo", function()
    local OpenEntireSilo

    before_each(function()
        OpenEntireSilo = stubs.loadMod()
    end)

    describe("beim Laden der Datei", function()
        it("merkt sich Mod-Name und -Ordner und meldet sich als Mod Event Listener an", function()
            assert.are.equal(stubs.MOD_NAME, OpenEntireSilo.MOD_NAME)
            assert.are.equal(stubs.MOD_DIRECTORY, OpenEntireSilo.MOD_DIRECTORY)
            assert.are.same({ OpenEntireSilo }, stubs.modEventListeners)
        end)

        it("hängt die Hooks an BunkerSilo", function()
            for name, original in pairs(stubs.originals) do
                assert.are_not.equal(original, BunkerSilo[name], name)
            end
            assert.is_true(BunkerSilo.oesHooksInstalled)
        end)

        it("umschließt die Funktionen bei erneutem Laden nicht doppelt", function()
            local hooked = {}
            for name in pairs(stubs.originals) do
                hooked[name] = BunkerSilo[name]
            end

            dofile(stubs.SCRIPT_PATH)

            for name in pairs(stubs.originals) do
                assert.are.equal(hooked[name], BunkerSilo[name], name)
            end
        end)
    end)

    describe("BunkerSilo:openSilo", function()
        local silo

        before_each(function()
            -- wie im Spiel: das Original öffnet das gegärte Silo vorne
            silo = stubs.newSilo({ state = BunkerSilo.STATE_FERMENTED, isOpenedAtFront = false })
            stubs.onOriginalOpenSilo = function(self)
                self.state = BunkerSilo.STATE_DRAIN
                self.isOpenedAtFront = true
            end
        end)

        it("ruft zuerst das Original mit denselben Argumenten auf", function()
            silo:openSilo(10, 20, 30)

            local first = stubs.calls[1]
            assert.are.equal("BunkerSilo.openSilo", first.name)
            assert.are.equal(4, first.n)
            assert.are.equal(silo, first.args[1])
            assert.are.same({ 10, 20, 30 }, { first.args[2], first.args[3], first.args[4] })
        end)

        it("wandelt gärenden Inhalt und Häckselgut auf der ganzen Fläche in Silage um", function()
            silo:openSilo(10, 20, 30)

            local changes = stubs.callsTo("DensityMapHeightUtil.changeFillTypeAtArea")
            assert.are.equal(2, #changes)
            assert.are.same(areaArgs(stubs.FILLTYPE_FERMENTING, stubs.FILLTYPE_OUTPUT), changes[1].args)
            assert.are.same(areaArgs(stubs.FILLTYPE_INPUT, stubs.FILLTYPE_OUTPUT), changes[2].args)
        end)

        it("markiert beide Seiten als offen und synchronisiert per Dirty-Flag", function()
            silo:openSilo(10, 20, 30)

            assert.is_true(silo.isOpenedAtFront)
            assert.is_true(silo.isOpenedAtBack)
            assert.is_true(silo.oesFullyOpened)

            local dirty = stubs.callsTo("BunkerSilo.raiseDirtyFlags")
            assert.are.equal(1, #dirty)
            assert.are.same({ silo, silo.bunkerSiloDirtyFlag }, dirty[1].args)
        end)

        it("tut auf dem Client nichts außer dem Original", function()
            silo.isServer = false

            silo:openSilo(10, 20, 30)

            assert.are.equal(1, #stubs.calls)
            assert.are.equal("BunkerSilo.openSilo", stubs.calls[1].name)
            assert.is_false(silo.isOpenedAtBack)
            assert.is_nil(silo.oesFullyOpened)
        end)

        it("tut nichts, wenn das Silo danach nicht im Zustand DRAIN ist", function()
            stubs.onOriginalOpenSilo = nil -- z. B. noch nicht fertig gegärt

            silo:openSilo(10, 20, 30)

            assert.are.equal(1, #stubs.calls)
            assert.is_false(silo.isOpenedAtBack)
            assert.is_nil(silo.oesFullyOpened)
        end)

        it("wandelt ein schon an beiden Seiten offenes Silo nicht erneut um", function()
            silo = stubs.newSilo({ isOpenedAtFront = true, isOpenedAtBack = true })

            silo:openSilo(10, 20, 30)

            assert.are.equal(1, #stubs.calls)
            assert.are.equal("BunkerSilo.openSilo", stubs.calls[1].name)
        end)

        it("öffnet ein nur hinten offenes Silo trotzdem komplett", function()
            silo = stubs.newSilo({ isOpenedAtFront = false, isOpenedAtBack = true })

            silo:openSilo(10, 20, 30)

            assert.are.equal(2, #stubs.callsTo("DensityMapHeightUtil.changeFillTypeAtArea"))
            assert.is_true(silo.isOpenedAtFront)
            assert.is_true(silo.oesFullyOpened)
        end)
    end)

    describe("BunkerSilo.onChangedFillLevelCallback", function()
        it("überspringt das Original bei einem komplett geöffneten Silo", function()
            local silo = stubs.newSilo({ oesFullyOpened = true })

            BunkerSilo.onChangedFillLevelCallback(silo, "vehicle", -100, stubs.FILLTYPE_OUTPUT, 1, 2, 3)

            assert.are.equal(0, #stubs.calls)
        end)

        it("reicht sonst alle Argumente unverändert an das Original durch", function()
            local silo = stubs.newSilo()

            BunkerSilo.onChangedFillLevelCallback(silo, "vehicle", -100, stubs.FILLTYPE_OUTPUT, 1, 2, 3)

            local calls = stubs.callsTo("BunkerSilo.onChangedFillLevelCallback")
            assert.are.equal(1, #calls)
            assert.are.equal(7, calls[1].n)
            assert.are.same({ silo, "vehicle", -100, stubs.FILLTYPE_OUTPUT, 1, 2, 3 }, calls[1].args)
        end)
    end)

    describe("BunkerSilo:loadFromXMLFile", function()
        local function load(silo)
            return silo:loadFromXMLFile("xmlFile", "key")
        end

        it("ruft das Original auf und gibt dessen Ergebnis zurück", function()
            local silo = stubs.newSilo()
            stubs.loadFromXMLFileResult = false

            assert.is_false(load(silo))

            local calls = stubs.callsTo("BunkerSilo.loadFromXMLFile")
            assert.are.equal(1, #calls)
            assert.are.same({ silo, "xmlFile", "key" }, calls[1].args)
        end)

        it("gilt als komplett geöffnet, wenn beide Seiten offen sind und nichts mehr gärt", function()
            local silo = stubs.newSilo({ isOpenedAtBack = true })
            stubs.fermentingFillLevel = 0

            load(silo)

            assert.is_true(silo.oesFullyOpened)
            local queries = stubs.callsTo("DensityMapHeightUtil.getFillLevelAtArea")
            assert.are.equal(1, #queries)
            assert.are.same({ stubs.FILLTYPE_FERMENTING, 1, 2, 3, 4, 5, 6 }, queries[1].args)
        end)

        it("gilt nicht als komplett geöffnet, solange noch etwas gärt", function()
            local silo = stubs.newSilo({ isOpenedAtBack = true })
            stubs.fermentingFillLevel = 500

            load(silo)

            assert.is_falsy(silo.oesFullyOpened)
        end)

        it("gilt nicht als komplett geöffnet, wenn nur eine Seite offen ist", function()
            local silo = stubs.newSilo()

            load(silo)

            assert.is_falsy(silo.oesFullyOpened)
        end)

        it("gilt nicht als komplett geöffnet außerhalb von DRAIN", function()
            local silo = stubs.newSilo({ state = BunkerSilo.STATE_FILL, isOpenedAtBack = true })

            load(silo)

            assert.is_falsy(silo.oesFullyOpened)
        end)
    end)

    describe("BunkerSilo:setState", function()
        it("ruft das Original mit denselben Argumenten auf", function()
            local silo = stubs.newSilo()

            silo:setState(BunkerSilo.STATE_FILL, true)

            local calls = stubs.callsTo("BunkerSilo.setState")
            assert.are.equal(1, #calls)
            assert.are.same({ silo, BunkerSilo.STATE_FILL, true }, calls[1].args)
        end)

        it("setzt das Merkfeld zurück, sobald das Silo DRAIN verlässt", function()
            local silo = stubs.newSilo({ oesFullyOpened = true })

            silo:setState(BunkerSilo.STATE_FILL, false)

            assert.is_false(silo.oesFullyOpened)
        end)

        it("lässt das Merkfeld stehen, solange das Silo in DRAIN bleibt", function()
            local silo = stubs.newSilo({ oesFullyOpened = true })

            silo:setState(BunkerSilo.STATE_DRAIN, false)

            assert.is_true(silo.oesFullyOpened)
        end)
    end)
end)
