--[[
Copyright (C) Achimobil

Important:
It is not allowed to copy in own Mods.
No changes are to be made to this script without permission from Achimobil.

Darf nicht in eigene Mods kopiert werden.
An diesem Skript dürfen ohne Genehmigung von Achimobil keine Änderungen vorgenommen werden.

No change Log because not allowed to use in other mods.
]]

---Placeable specialization that shows the fill levels of the nearest storage, production point or husbandry on digital displays
BigDisplaySpecialization = {
    Name = "BigDisplaySpecialization",
    displays = {},
    Debug = false
};

BigDisplaySpecialization.modName = g_currentModName;
BigDisplaySpecialization.modDir = g_currentModDirectory;

source(BigDisplaySpecialization.modDir.."gui/displaySettingsDialog.lua");
source(BigDisplaySpecialization.modDir.."scripts/PlaceableHusbandryFoodExtension.lua");
source(BigDisplaySpecialization.modDir.."scripts/PlaceableObjectStorageExtension.lua");
source(BigDisplaySpecialization.modDir.."scripts/bigDisplaySpecializationActivatable.lua");
source(BigDisplaySpecialization.modDir.."scripts/bigDisplaySettingEvent.lua");

---Print the text to the log as info. Example: BigDisplaySpecialization.info("Alter: %s", age)
---@param infoMessage string the text to print formated
---@param ... any format parameter
function BigDisplaySpecialization.info(infoMessage, ...)
    if BigDisplaySpecialization.Debug then
        BigDisplaySpecialization.DebugText("Info:" .. infoMessage, ...)
    else
        Logging.info(BigDisplaySpecialization.modName .. " - " .. infoMessage, ...);
    end
end

---Print the text to the log as dev info. Example: BigDisplaySpecialization.devInfo("Alter: %s", age)
---@param infoMessage string the text to print formated
---@param ... any format parameter
function BigDisplaySpecialization.devInfo(infoMessage, ...)
    if infoMessage == nil then infoMessage = "nil" end
    if BigDisplaySpecialization.Debug then
        BigDisplaySpecialization.DebugText("DevInfo:" .. infoMessage, ...)
    else
        Logging.devInfo(BigDisplaySpecialization.modName .. " - " .. infoMessage, ...)
    end
end

---Print the given Table to the log
---@param text string Text before the table
---@param myTable table The table to print
---@param maxDepth number|nil depth of print, default 2
function BigDisplaySpecialization.DebugTable(text, myTable, maxDepth)
    if not BigDisplaySpecialization.Debug then return end
    if myTable == nil then
        print("BigDisplaySpecialization Debug: " .. text .. " is nil");
    else
        print("BigDisplaySpecialization Debug: " .. text)
        DebugUtil.printTableRecursively(myTable,"_",0, maxDepth or 2);
    end
end

---Print the text to the log. Example: BigDisplaySpecialization.DebugText("Alter: %s", age)
---@param text string the text to print formated
---@param ... any format parameter
function BigDisplaySpecialization.DebugText(text, ...)
    if not BigDisplaySpecialization.Debug then return end
    print("BigDisplaySpecialization Debug: " .. string.format(text, ...));
end

BigDisplaySpecialization.info("init %s", BigDisplaySpecialization.Name);

---Checks if all prerequisite specializations are loaded
---@param specializations table specializations already loaded on the placeable type
---@return boolean hasPrerequisite true if all prerequisite specializations are loaded
function BigDisplaySpecialization.prerequisitesPresent(specializations)
    return true;
end

---Registers the event listeners for this specialization
---@param placeableType table the placeable type to register the listeners on
function BigDisplaySpecialization.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", BigDisplaySpecialization);
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", BigDisplaySpecialization);
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", BigDisplaySpecialization);
    SpecializationUtil.registerEventListener(placeableType, "onDelete", BigDisplaySpecialization)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", BigDisplaySpecialization)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", BigDisplaySpecialization)
end

---Registers the functions for this specialization
---@param placeableType table the placeable type to register the functions on
function BigDisplaySpecialization.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateDisplays", BigDisplaySpecialization.updateDisplays);
    SpecializationUtil.registerFunction(placeableType, "updateDisplayData", BigDisplaySpecialization.updateDisplayData);
    SpecializationUtil.registerFunction(placeableType, "reconnectToStorage", BigDisplaySpecialization.reconnectToStorage);
    SpecializationUtil.registerFunction(placeableType, "onStationDeleted", BigDisplaySpecialization.onStationDeleted);
    SpecializationUtil.registerFunction(placeableType, "triggerCallback", BigDisplaySpecialization.triggerCallback)
    SpecializationUtil.registerFunction(placeableType, "setSettings", BigDisplaySpecialization.setSettings)
end

---Registers the overwritten functions for this specialization
---@param placeableType table the placeable type to register the overwritten functions on
function BigDisplaySpecialization.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", BigDisplaySpecialization.updateInfo)
end

---Registers the XML schema paths used by this specialization
---@param schema XMLSchema the xml schema to register paths on
---@param basePath string base xml path prefix for this specialization
function BigDisplaySpecialization.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("BigDisplay");

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bigDisplays.bigDisplay(?)#upperLeftNode", "Upper left node of the screen Area");
    schema:register(XMLValueType.FLOAT, basePath .. ".bigDisplays.bigDisplay(?)#height", "height of the screen Area");
    schema:register(XMLValueType.FLOAT, basePath .. ".bigDisplays.bigDisplay(?)#width", "width of the screen Area");
    schema:register(XMLValueType.FLOAT, basePath .. ".bigDisplays.bigDisplay(?)#size", "Display text size");
    schema:register(XMLValueType.COLOR, basePath .. ".bigDisplays.bigDisplay(?)#color", "Display text color");
    schema:register(XMLValueType.COLOR, basePath .. ".bigDisplays.bigDisplay(?)#colorHybrid", "Display text color");
    schema:register(XMLValueType.COLOR, basePath .. ".bigDisplays.bigDisplay(?)#colorInput", "Display text color");
    schema:register(XMLValueType.BOOL, basePath .. ".bigDisplays.bigDisplay(?)#emptyFilltypes", "Display empty Filltypes", false)
    schema:register(XMLValueType.INT, basePath .. ".bigDisplays.bigDisplay(?)#columns", "Number of columns the display is splittet to", 1)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".bigDisplays#playerTrigger", "Player trigger node")

    schema:setXMLSpecializationType();
end

---Init the specialisation. Should be called only once
function BigDisplaySpecialization.initSpecialization()
    local schemaSavegame = Placeable.xmlSchemaSavegame;
    schemaSavegame:register(XMLValueType.FLOAT, "placeables.placeable(?).FS25_DigitalDisplay.BigDisplay.display(?)#textSize", "Display text size", 0.11);
    schemaSavegame:register(XMLValueType.INT, "placeables.placeable(?).FS25_DigitalDisplay.BigDisplay.display(?)#displayType", "Type of display the value. later 0 = only total, 1 = total and capacity, 2 = total and percentage", 0);

    DisplaySettingsDialog.register()
end

---Get save attributes and nodes
---@param xmlFile table xml file to write to
---@param key string base xml key for this element
---@param usedModNames table mod names already used in the savegame
function BigDisplaySpecialization:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_bigDisplay;
    local index = 0;
    for _, bigDisplay in pairs(spec.bigDisplays) do
        local sizeKey = string.format("%s.display(%d)#textSize", key, index);
        xmlFile:setValue(sizeKey, bigDisplay.textSize);
        local displayTypeKey = string.format("%s.display(%d)#displayType", key, index);
        xmlFile:setValue(displayTypeKey, bigDisplay.displayType or 0);
    end
end

---Loading from attributes and nodes
---@param xmlFile table xml file to read from
---@param key string base xml key for this element
---@return boolean success always true
function BigDisplaySpecialization:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_bigDisplay;

    xmlFile:iterate(key .. ".display", function(index, displayKey)
        local size = xmlFile:getValue(displayKey.."#textSize", 0.11) or 0.11;
        local displayType = xmlFile:getValue(displayKey.."#displayType", 0) or 0;

        if spec.bigDisplays[index] ~= nil then
            if size ~= 0 then
                spec.bigDisplays[index].textSize = size;
            BigDisplaySpecialization:CreateDisplayLines(spec.bigDisplays[index]);
            end
            spec.bigDisplays[index].displayType = displayType;
        end
    end)

    return true;
end

---Called on loading
---@param savegame? table savegame data, nil when placed fresh
function BigDisplaySpecialization:onLoad(savegame)
    self.spec_bigDisplay = {};
    local spec = self.spec_bigDisplay;
    local xmlFile = self.xmlFile;

    spec.bigDisplays = {};
    spec.changedColors = {}
    spec.updateDisplaysRunning = false;
    spec.updateDisplaysRequested = false;
    spec.updateDisplaysDtSinceLastTime = 9999;

    ---@diagnostic disable-next-line: need-check-nil
    spec.playerTrigger = xmlFile:getValue("placeable.bigDisplays#playerTrigger", nil, self.components, self.i3dMappings)

    if spec.playerTrigger ~= nil then
        BigDisplaySpecialization.DebugText("playerTrigger found");
        addTrigger(spec.playerTrigger, "triggerCallback", self);
        spec.isTriggerActive = true;
        spec.activatable = BigDisplaySpecializationActivatable.new(self);
    else
        BigDisplaySpecialization.DebugText("playerTrigger not found");
    end

    local i = 0;
    while true do
        local bigDisplayKey = string.format("placeable.bigDisplays.bigDisplay(%d)", i);

        ---@diagnostic disable-next-line: need-check-nil
        if not xmlFile:hasProperty(bigDisplayKey) then
            break;
        end

        ---@diagnostic disable-next-line: need-check-nil
        local upperLeftNode = xmlFile:getValue(bigDisplayKey .. "#upperLeftNode", nil, self.components, self.i3dMappings);
        ---@diagnostic disable-next-line: need-check-nil
        local height = xmlFile:getValue(bigDisplayKey .. "#height", 1);
        ---@diagnostic disable-next-line: need-check-nil
        local width = xmlFile:getValue(bigDisplayKey .. "#width", 1);

        -- display general stuff
        ---@diagnostic disable-next-line: need-check-nil
        local size = xmlFile:getValue(bigDisplayKey .. "#size", 0.11);
        ---@diagnostic disable-next-line: need-check-nil
        local emptyFilltypes = xmlFile:getValue(bigDisplayKey .. "#emptyFilltypes", false)
        ---@diagnostic disable-next-line: need-check-nil
        local columns = xmlFile:getValue(bigDisplayKey .. "#columns", 1)

        local bigDisplay = {};
        bigDisplay.color = {
            0.0,
            0.9,
            0.0,
            1
        };
        bigDisplay.colorHybrid = {
            0.5,
            0.7,
            0.0,
            1
        };
        bigDisplay.colorInput = {
            0.0,
            0.7,
            0.3,
            1
        };
        bigDisplay.textSize = size;
        bigDisplay.displayType = 0;
        bigDisplay.currentPage = 1;
        bigDisplay.lastPageTime = 0;
        bigDisplay.nodeId = upperLeftNode;
        bigDisplay.textDrawDistance = 30;
        bigDisplay.emptyFilltypes = emptyFilltypes;
        bigDisplay.columns = columns;
        bigDisplay.width = width;
        bigDisplay.height = height;
        bigDisplay.displayLines = {};

        BigDisplaySpecialization:CreateDisplayLines(bigDisplay);

        table.insert(spec.bigDisplays, bigDisplay);

        i = i + 1;
    end

    ---Marks the display data as needing a refresh when this station's fill level changes
    ---@param fillType integer fill type index that changed
    ---@param delta number amount the fill level changed by
    function spec.fillLevelChangedCallback(fillType, delta) ---@diagnostic disable-line: unused-local
        if spec.updateDisplaysRequested == false then
            BigDisplaySpecialization.devInfo("fillLevelChangedCallback")
        end
        spec.updateDisplaysRequested = true;
    end

    ---Marks the display data as needing a refresh when a connected husbandry's fill level changes
    ---@param fillType integer fill type index that changed
    ---@param delta number amount the fill level changed by
    function spec.onHusbandryFillLevelChanged(fillType, delta) ---@diagnostic disable-line: unused-local
        if spec.updateDisplaysRequested == false then
            BigDisplaySpecialization.devInfo("onHusbandryFillLevelChanged")
        end
        spec.updateDisplaysRequested = true;
    end
end

---Creates the display line layout for the given display
---@param bigDisplay table the display to compute the line layout for
function BigDisplaySpecialization:CreateDisplayLines(bigDisplay)

    local newDisplayLines = {};
    -- breite pro Spalte berechnen
    local columnWidth = (bigDisplay.width - (0.05 * (bigDisplay.columns - 1))) / bigDisplay.columns;

    -- schleife pro spalte
    for currentColumn = 1, bigDisplay.columns do

        -- linker startpunkt für die Schrift
        local leftStart = 0.03 + ((columnWidth + 0.05) * (currentColumn - 1))
        local rightStart = bigDisplay.width - ((columnWidth + 0.05) * (bigDisplay.columns - currentColumn)) - 0.02

        -- Mögliche zeilen anhand der Größe erstellen
        local lineHeight = bigDisplay.textSize;
        -- local x, y, z = getWorldTranslation(upperLeftNode)
        local rx, ry, rz = getWorldRotation(bigDisplay.nodeId)
        for currentY = -bigDisplay.textSize, -bigDisplay.height-(bigDisplay.textSize/2), -lineHeight do

            local displayLine = {};
            displayLine.text = {};
            displayLine.value = {};
            displayLine.width = rightStart - leftStart;

            local x,y,z = localToWorld(bigDisplay.nodeId, leftStart, currentY, 0);
            displayLine.text.x = x;
            displayLine.text.y = y;
            displayLine.text.z = z;

            local x2,y2,z2 = localToWorld(bigDisplay.nodeId, rightStart, currentY, 0);
            displayLine.value.x = x2;
            displayLine.value.y = y2;
            displayLine.value.z = z2;

            displayLine.rx = rx;
            displayLine.ry = ry;
            displayLine.rz = rz;

            table.insert(newDisplayLines, displayLine);
        end
    end

    bigDisplay.displayLines = newDisplayLines;
end

---Trigger callback
---@param triggerId integer id of trigger
---@param otherId integer id of object that entered/left the trigger
---@param onEnter boolean called on enter
---@param onLeave boolean called on leave
---@param onStay boolean called on stay
function BigDisplaySpecialization:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)

    if onEnter or onLeave then
        if g_localPlayer and g_localPlayer.rootNode == otherId then
            local spec = self.spec_bigDisplay
            if onEnter and spec.isTriggerActive then
                -- automatically perform action without manual activation on mobile
                if Platform.gameplay.autoActivateTrigger and spec.activatable:getIsActivatable() then
                    spec.activatable:run()
                    return
                end

                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            end
            if onLeave then
                g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            end
        end
    end
end

---Called by base class when placement is finalizing
---@param savegame? table savegame data, nil when placed fresh
function BigDisplaySpecialization:onFinalizePlacement(savegame)
    local spec = self.spec_bigDisplay;
    if spec.loadingStationToUse == nil then
        return;
    end
end

---Called by base class when placement finalizing is done
---@param savegame? table savegame data, nil when placed fresh
function BigDisplaySpecialization:onPostFinalizePlacement(savegame)
    table.insert(BigDisplaySpecialization.displays, self);
    self:reconnectToStorage();
end

---Reconnect to the next storage in range
---@param savegame? table savegame data, nil when called outside loading
function BigDisplaySpecialization:reconnectToStorage(savegame)

    local spec = self.spec_bigDisplay;

    if spec.loadingStationToUse ~= nil then
        local storages = spec.loadingStationToUse.sourceStorages or spec.loadingStationToUse.targetStorages;
        if storages ~= nil then
            for _, sourceStorage in pairs(storages) do
                sourceStorage:removeFillLevelChangedListeners(spec.fillLevelChangedCallback);
            end
        end
        if spec.loadingStationToUse.owningPlaceable ~= nil and spec.loadingStationToUse.owningPlaceable.spec_husbandryFood ~= nil then
            -- some husbanries the stations are not usable, this is a fallback to the eventlisteners directly
            table.removeElement(spec.loadingStationToUse.owningPlaceable.eventListeners.onHusbandryFillLevelChanged, spec)
        end
        spec.loadingStationToUse:removeDeleteListener(self, "onStationDeleted")
        spec.loadingStationToUse = nil;
    end

    if not self.isClient then
        return;
    end

    -- find the storage closest to me
    local currentLoadingStation = nil;
    local currentDistance = math.huge;
    local usedProduction = nil;
    for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do

        -- wenn tierstall, dann ignorieren
        local ignore = false;

        -- loadingStation oder unloadingStation aus der liste die jeweils erste benutzen
        local loadingStation = nil;

        for _, loadingSt in pairs (storage.loadingStations) do
            if loadingStation == nil then
                loadingStation = loadingSt;
            end
        end

        if loadingStation == nil then
            for _, unloadingSt in pairs (storage.unloadingStations) do
                if loadingStation == nil then
                    loadingStation = unloadingSt;
                end
            end
        end

        if loadingStation ~= nil then
            local x, y, z = getWorldTranslation(self.rootNode);
            local distance = BigDisplaySpecialization:getDistance(loadingStation, x, y, z);
            if distance < currentDistance and not ignore then
                currentDistance = distance;
                currentLoadingStation = loadingStation;
            end
        end
    end

    -- auch produktionen durchsuchen nach dem richtigen storage, die stehen nicht im storage system
    local farmId = self:getOwnerFarmId();
    for _, productionPoint in ipairs(g_currentMission.productionChainManager:getProductionPointsForFarmId(farmId)) do

        local loadingStation = productionPoint.loadingStation;
        if loadingStation == nil then
            loadingStation = productionPoint.unloadingStation;
        end
        if loadingStation ~= nil then
            local x, y, z = getWorldTranslation(self.rootNode);
            local distance = BigDisplaySpecialization:getDistance(loadingStation, x, y, z);
            if distance < currentDistance then
                currentDistance = distance;
                currentLoadingStation = loadingStation;
                usedProduction = productionPoint;
            end
        end
    end

    -- jetzt auch mal die Tierställe durchsuchen. Doppelt bei denen, die einen storage haben
    for _, husbandryPlacable in ipairs(g_currentMission.husbandrySystem.placeables) do

        local loadingStation = husbandryPlacable.spec_husbandry.loadingStation;
        if loadingStation == nil then
            loadingStation = husbandryPlacable.spec_husbandry.unloadingStation;
        else
        end

        if loadingStation ~= nil then
            local x, y, z = getWorldTranslation(self.rootNode);
            local distance = BigDisplaySpecialization:getDistance(loadingStation, x, y, z);
            if distance < currentDistance then
                currentDistance = distance;
                currentLoadingStation = loadingStation;
            end
        end
    end

    -- scan placables for object storages
    for _, placable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placable.spec_objectStorage ~= nil then
            local x, y, z = getWorldTranslation(self.rootNode);
            local distance = BigDisplaySpecialization:getDistance(placable, x, y, z);
            if distance < currentDistance then
                currentDistance = distance;
                currentLoadingStation = placable;
            end
        end
    end

    if currentLoadingStation == nil then
        BigDisplaySpecialization.info("no Loading Station found");
        return;
    end

    spec.loadingStationToUse = currentLoadingStation;
    spec.updateDisplaysRequested = true;
    self:updateDisplayData("reconnectToStorage");

    -- farben festlegen. Input, output oder beides?
    if usedProduction ~= nil then
        for inputFillTypeIndex in pairs(usedProduction.inputFillTypeIds) do
            if spec.changedColors[inputFillTypeIndex] == nil then
                spec.changedColors[inputFillTypeIndex] = {isInput = false, isOutput = false};
            end
            spec.changedColors[inputFillTypeIndex].isInput = true;
        end
        for outputFillTypeIndex in pairs(usedProduction.outputFillTypeIds) do
            if spec.changedColors[outputFillTypeIndex] == nil then
                spec.changedColors[outputFillTypeIndex] = {isInput = false, isOutput = false};
            end
            spec.changedColors[outputFillTypeIndex].isOutput = true;
        end
        for _, changedColor in pairs(spec.changedColors) do
            if changedColor.isInput then
                if changedColor.isOutput then
                    changedColor.color = spec.bigDisplays[1].colorHybrid;
                else
                    changedColor.color = spec.bigDisplays[1].colorInput;
                end
            else
                changedColor.color = spec.bigDisplays[1].color;
            end
        end
    end

    -- Futter bei Tierställen hinzufügen einfärben
    if spec.loadingStationToUse.owningPlaceable ~= nil and spec.loadingStationToUse.owningPlaceable.spec_husbandryFood ~= nil then
        for fillType, _ in pairs(spec.loadingStationToUse.owningPlaceable.spec_husbandryFood.fillLevels) do
            if spec.changedColors[fillType] == nil then
                spec.changedColors[fillType] = {isInput = false, isOutput = false};
            end
            spec.changedColors[fillType].color = spec.bigDisplays[1].colorInput;
        end
    end

    -- Stroh bei Tierställen hinzufügen einfärben
    if spec.loadingStationToUse.owningPlaceable ~= nil and spec.loadingStationToUse.owningPlaceable.spec_husbandryStraw ~= nil then
        local fillType = spec.loadingStationToUse.owningPlaceable.spec_husbandryStraw.inputFillType;

        if spec.changedColors[fillType] == nil then
            spec.changedColors[fillType] = {isInput = false, isOutput = false};
        end
        spec.changedColors[fillType].color = spec.bigDisplays[1].colorInput;
    end

    -- Stroh bei Tierställen hinzufügen einfärben
    if spec.loadingStationToUse.owningPlaceable ~= nil and spec.loadingStationToUse.owningPlaceable.spec_husbandryStraw ~= nil then
        local fillType = spec.loadingStationToUse.owningPlaceable.spec_husbandryStraw.inputFillType;

        if spec.changedColors[fillType] == nil then
            spec.changedColors[fillType] = {isInput = false, isOutput = false};
        end
        spec.changedColors[fillType].color = spec.bigDisplays[1].colorInput;
    end

    -- Wasser bei Tierställen hinzufügen einfärben
    if spec.loadingStationToUse.owningPlaceable ~= nil and spec.loadingStationToUse.owningPlaceable.spec_husbandryWater ~= nil then
        local fillType = spec.loadingStationToUse.owningPlaceable.spec_husbandryWater.fillType;

        if spec.changedColors[fillType] == nil then
            spec.changedColors[fillType] = {isInput = false, isOutput = false};
        end
        spec.changedColors[fillType].color = spec.bigDisplays[1].colorInput;
    end

    -- Auswahl welches storage connected wird
--     BigDisplaySpecialization.DebugTable("spec.loadingStationToUse.owningPlaceable", spec.loadingStationToUse.owningPlaceable)
    local storages = spec.loadingStationToUse.sourceStorages or spec.loadingStationToUse.targetStorages;
    if storages ~= nil and next(storages) then
        for _, sourceStorage in pairs(storages) do
            sourceStorage:addFillLevelChangedListeners(spec.fillLevelChangedCallback);
        end
    elseif spec.loadingStationToUse.owningPlaceable ~= nil and spec.loadingStationToUse.owningPlaceable.spec_husbandryFood ~= nil then
        -- some husbanries the stations are not usable, this is a fallback to the eventlisteners directly
        table.addElement(spec.loadingStationToUse.owningPlaceable.eventListeners.onHusbandryFillLevelChanged, spec)
        BigDisplaySpecialization.devInfo("onHusbandryFillLevelChanged used for %s", spec.loadingStationToUse:getName());
    elseif spec.loadingStationToUse.addFillLevelChangedListeners ~= nil then
        spec.loadingStationToUse:addFillLevelChangedListeners(spec.fillLevelChangedCallback);
    else
        BigDisplaySpecialization.info("no storage to add listener found");
    end

    spec.loadingStationToUse:addDeleteListener(self, "onStationDeleted")

    BigDisplaySpecialization.devInfo("Connected to %s", spec.loadingStationToUse:getName());
end

---Called when the currently registered station is deleted, to reconnect to another one
---@param station table the station that was deleted
function BigDisplaySpecialization:onStationDeleted(station)

    if g_currentMission.isExitingGame == true then
        BigDisplaySpecialization.info("Exiting game, prevent reconnect on station delete");
        return;
    end

    self:reconnectToStorage();
end

--- Called when Placeable is deleted and game closed
function BigDisplaySpecialization:onDelete()
    table.removeElement(BigDisplaySpecialization.displays, self);

    local spec = self.spec_bigDisplay

    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    spec.activatable = nil

    if spec.playerTrigger ~= nil then
        removeTrigger(spec.playerTrigger)
    end
end

---Gets the distance between the target object and the given coordinates
---@param loadingStation table the target object to measure the distance to
---@param x number world x coordinate
---@param y number world y coordinate
---@param z number world z coordinate
---@return number distance distance to the target, or math.huge if the target has no valid position
function BigDisplaySpecialization:getDistance(loadingStation, x, y, z)
    if loadingStation ~= nil then
        local tx, ty, tz = getWorldTranslation(loadingStation.rootNode)

        if tx == nil or ty == nil or tz == nil then
            -- fehlerhafte loadingstations deren position nicht ermitteln kann, ignorieren wir hier
            return math.huge
        end

        local distance = MathUtil.vector3Length(x - tx, y - ty, z - tz)
        BigDisplaySpecialization.devInfo("Distance check for %s, distance %s, station %s-%s-%s, display %s-%s-%s", loadingStation:getName(), distance,tx, ty, tz, x, y, z);
        return distance;
    end

    return math.huge
end

---Updates the data which the display shows
---@param debugInfoText string text used in the debug prints to identify the caller
function BigDisplaySpecialization:updateDisplayData(debugInfoText)
    local spec = self.spec_bigDisplay;
    if spec == nil or spec.loadingStationToUse == nil then
        return;
    end

--     BigDisplaySpecialization.devInfo("updateDisplayData for %s from %s, %s, %s", spec.loadingStationToUse:getName(), debugInfoText, spec.updateDisplaysRunning, spec.updateDisplaysDtSinceLastTime)

    -- only one time read at a time for more performance
    if spec.updateDisplaysRunning then
        return
--     else
--         if spec.updateDisplaysRequested == false and spec.updateDisplaysDtSinceLastTime >= 500 then
--             spec.updateDisplaysRequested = true;
--             return;
--         end
    end
    spec.updateDisplaysRunning = true;

    BigDisplaySpecialization.devInfo("updateDisplayData for %s from %s", spec.loadingStationToUse:getName(), debugInfoText)

    local farmId = self:getOwnerFarmId();

    -- wenn der User eine FarmId hat, dann diese benutzen, damit bei silos das ausgelesen wird, was der user farm gehört
    if g_localPlayer ~= nil and g_localPlayer.farmId ~= nil then
        farmId = g_localPlayer.farmId;
    end

    for _, bigDisplay in pairs(spec.bigDisplays) do
        -- in jede line schreiben, was angezeigt werden soll
        -- hier eventuell filtern anhand von xml einstellungen?
        -- möglich per filltype liste festzulegen was in welcher reihenfolge angezeigt wird, sinnvoll?
        -- sortieren per XML einstellung?
        bigDisplay.lineInfos = {};
        for fillTypeId, fillLevelItem in pairs(BigDisplaySpecialization:getAllFillLevels(spec.loadingStationToUse, farmId)) do
            local lineInfo = {};

            -- fermenting special case
            local fermenting = false;
            if fillLevelItem.isFermenting ~= nil then
                fermenting = fillLevelItem.isFermenting;
            end

            lineInfo.fillTypeId = fillTypeId;
            local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeId);
            lineInfo.title = fillTypeDesc.title;
            if fermenting then
                lineInfo.title = lineInfo.title .. "(" .. g_i18n:getText("info_fermenting") .. ")";
            end

            local displayType = bigDisplay.displayType;  -- setting later 0 = only total, 1 = total and capacity, 2 = total and percentage

            local myFillLevel = Utils.getNoNil(fillLevelItem.total, 0);

            if displayType == 1 and fillLevelItem.capacity ~= nil then
                lineInfo.fillLevel = BigDisplaySpecialization:formatCapacity(myFillLevel, fillLevelItem.capacity, 0, fillTypeDesc.unitShort);
            elseif displayType == 2 and fillLevelItem.capacity ~= nil and fillLevelItem.capacity ~= 0 then
                lineInfo.fillLevel = string.format("%s (%s%%)", BigDisplaySpecialization:formatVolume(myFillLevel, 0, fillTypeDesc.unitShort), g_i18n:formatNumber((myFillLevel / fillLevelItem.capacity)*100, 0));
            else
                lineInfo.fillLevel = BigDisplaySpecialization:formatVolume(myFillLevel, 0, fillTypeDesc.unitShort);
            end

            if bigDisplay.emptyFilltypes then
                table.insert(bigDisplay.lineInfos, lineInfo);
            else
                -- erst mal nur anzeigen wo auch was da ist?
                if(myFillLevel >= 1) then
                    table.insert(bigDisplay.lineInfos, lineInfo);
                end
            end
        end

        table.sort(bigDisplay.lineInfos, BigDisplaySpecialization.compLineInfos)

        -- Titel-Kürzung nur einmal pro Datenaktualisierung berechnen statt jeden Frame im Renderloop
        local columnWidth = bigDisplay.displayLines[1] ~= nil and bigDisplay.displayLines[1].width or nil;
        if columnWidth ~= nil then
            for _, lineInfo in ipairs(bigDisplay.lineInfos) do
                lineInfo.renderTitle = BigDisplaySpecialization:calcRenderTitle(bigDisplay.textSize, columnWidth, lineInfo.title, lineInfo.fillLevel);
            end
        end
    end

    spec.updateDisplaysRunning = false;
    spec.updateDisplaysRequested = false;
    spec.updateDisplaysDtSinceLastTime = 0;
end

---Calculates the title text to render for a display line, truncated with an ellipsis if it does not fit next to the fill level text
---@param textSize number display text size
---@param columnWidth number width available for title and fill level text together
---@param title string filltype title
---@param fillLevel string already formatted fill level text
---@return string renderTitle the (possibly truncated) title to render
function BigDisplaySpecialization:calcRenderTitle(textSize, columnWidth, title, fillLevel)
    local fillLevelWidth = getText3DWidth(textSize, fillLevel);
    local titleWidth = getText3DWidth(textSize, title);
    local maxWidth = columnWidth - fillLevelWidth;

    local renderTitle = title;
    if titleWidth > maxWidth then
        local numChars = getTextLength(textSize, renderTitle, 1);
        local maxChars = math.floor(numChars / titleWidth * maxWidth) - 1;
        renderTitle = utf8Substr(renderTitle, 0, maxChars) .. "…";
    end

    return renderTitle;
end

---format a volume
---@param liters number amount to format
---@param precision integer how many decimals
---@param unit string|false|nil which unit should be used (false = no unit, nil = default)
---@return string the formated value
function BigDisplaySpecialization:formatVolume(liters, precision, unit)
    unit = unit ~= "" and (unit == false and "" or unit) or nil

    return g_i18n:formatVolume(liters, precision, unit)
end

---format a volume with capacity
---@param liters number amount to format
---@param capacity number capacity to format
---@param precision integer how many decimals
---@param unit string|false|nil which unit should be used
---@return string the formated value
function BigDisplaySpecialization:formatCapacity(liters, capacity, precision, unit)
    return self:formatVolume(liters, precision, false) .. " / " .. self:formatVolume(capacity, precision, unit);
end

---Gets all fill levels of the given station accessible by the given farm
---@param station table the station (or object storage) to read fill levels from
---@param farmId integer id of the farm the fill levels must be accessible to
---@return table fillLevels fill levels per fill type index
function BigDisplaySpecialization:getAllFillLevels(station, farmId)
    local fillLevels = {}

    local storages = station.sourceStorages or station.targetStorages;
    if storages ~= nil then
        for _, sourceStorage in pairs(storages) do
            if station:hasFarmAccessToStorage(farmId, sourceStorage) then
                for fillType, fillLevel in pairs(sourceStorage:getFillLevels()) do
                    if fillLevels[fillType] == nil then
                        fillLevels[fillType] = {};
                    end

                    fillLevels[fillType].total = Utils.getNoNil(fillLevels[fillType].total, 0) + fillLevel

                    if sourceStorage.capacities ~= nil and sourceStorage.capacities[fillType] ~= nil then
                        fillLevels[fillType].capacity = Utils.getNoNil(fillLevels[fillType].capacity, 0) + sourceStorage.capacities[fillType]
                    end
                end
            end
        end
    end

    -- Futter bei Tierställen hinzufügen
    if station.owningPlaceable ~= nil and station.owningPlaceable.spec_husbandryFood ~= nil then
        for fillType, fillLevel in pairs(station.owningPlaceable.spec_husbandryFood.fillLevels) do
            if fillLevels[fillType] == nil then
                fillLevels[fillType] = {};
            end
            fillLevels[fillType].total = Utils.getNoNil(fillLevels[fillType].total, 0) + fillLevel;

            -- capacity not possible, because I show every single filltype and the capacity is a total value
        end
    end

    -- inhalt von Robotern einfügen
    if station.owningPlaceable ~= nil and station.owningPlaceable.spec_husbandryFeedingRobot ~= nil then
        for fillType, _ in pairs(station.owningPlaceable.spec_husbandryFeedingRobot.feedingRobot.fillTypeToUnloadingSpot) do
            local fillLevel = station.owningPlaceable.spec_husbandryFeedingRobot.feedingRobot:getFillLevel(fillType);
            if fillLevels[fillType] == nil then
                fillLevels[fillType] = {};
            end
            fillLevels[fillType].total = Utils.getNoNil(fillLevels[fillType].total, 0) + fillLevel

            -- capacity not possible, because I show every single filltype and the capacity is a total value
        end
    end

    -- inhalt von object storages einfügen
    if station.spec_objectStorage ~= nil then
        for _, objectInfo in pairs(station.spec_objectStorage.objectInfos) do
            local fillType = nil;
            local fillLevel = nil;

            -- when only on item in objects but numObjects contains multiple the filllevel needs do be multiplied
            local serverClientDifferenceMultiplier = 1;
            if objectInfo.numObjects ~= 1 and #objectInfo.objects == 1 then
                serverClientDifferenceMultiplier = objectInfo.numObjects;
            end

            for _, object in pairs(objectInfo.objects) do
                local isFermenting = false;

                if object.palletAttributes ~= nil then
                    fillType = object.palletAttributes.fillType;
                    fillLevel = object.palletAttributes.fillLevel * serverClientDifferenceMultiplier;
                elseif object.baleAttributes ~= nil then
                    fillType = object.baleAttributes.fillType;
                    fillLevel = object.baleAttributes.fillLevel * serverClientDifferenceMultiplier;
                elseif object.baleObject ~= nil then
                    isFermenting = true;
                    fillType = object.baleObject.fillType;
                    fillLevel = object.baleObject.fillLevel * serverClientDifferenceMultiplier;
                end

                if fillType ~= nil and fillLevel ~= nil then
                    if fillLevels[fillType] == nil then
                        fillLevels[fillType] = {};
                    end
                    fillLevels[fillType].total = Utils.getNoNil(fillLevels[fillType].total, 0) + fillLevel;
                    fillLevels[fillType].isFermenting = isFermenting;
                else
                    BigDisplaySpecialization.DebugTable("not used storedObject", object);
                end
            end
        end
    end

    return fillLevels
end

---Compares the given line infos by title, for sorting
---@param w1 table first line info
---@param w2 table second line info
---@return boolean isLess true if w1's title sorts before w2's title
function BigDisplaySpecialization.compLineInfos(w1,w2)
    return w1.title < w2.title;
end

---Updates the displays, refreshing the data first if it has grown stale
---@param dt number time since last call in ms
function BigDisplaySpecialization:updateDisplays(dt)
    local spec = self.spec_bigDisplay;
    if spec == nil or spec.loadingStationToUse == nil then
        return;
    end

    if not self.isClient then
        return;
    end

    -- position des spielers
    local x, z = 0, 0;
    if g_currentMission.hud.controlledVehicle ~= nil then
        x, _, z = getWorldTranslation(g_currentMission.hud.controlledVehicle.rootNode);
    elseif g_localPlayer.rootNode ~= nil then
        x, _, z = getWorldTranslation(g_localPlayer.rootNode);
    end

    -- entfernung zum display ermitteln damit es nicht immer gerendert und nicht aktualisiert wird, wenn der Spieler es nicht sieht
    -- display position nur ein mal ermitteln
    if spec.bigDisplays[1].worldTranslation == nil then
        spec.bigDisplays[1].worldTranslation = {getWorldTranslation(spec.bigDisplays[1].nodeId)};
    end
    local currentDistance = MathUtil.vector2Length(x - spec.bigDisplays[1].worldTranslation[1], z - spec.bigDisplays[1].worldTranslation[3]);
    if currentDistance > spec.bigDisplays[1].textDrawDistance then
        return;
    end

    spec.updateDisplaysDtSinceLastTime = spec.updateDisplaysDtSinceLastTime + dt;
    if spec.updateDisplaysRequested and spec.updateDisplaysDtSinceLastTime >= 1000 then
        self:updateDisplayData("updateDisplays");
    end

    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)

    for _, bigDisplay in pairs(spec.bigDisplays) do

        local countOfDisplayLines = #bigDisplay.displayLines;

        if countOfDisplayLines ~= 0 then
            -- paging
            local pageOffset = 0;
            bigDisplay.lastPageTime = bigDisplay.lastPageTime + dt;
            local pages = math.ceil(#bigDisplay.lineInfos / #bigDisplay.displayLines);
            if bigDisplay.lastPageTime >= 5000 then
                if bigDisplay.currentPage >= pages then
                    bigDisplay.currentPage = 1;
                else
                    bigDisplay.currentPage = bigDisplay.currentPage + 1;
                end
                bigDisplay.lastPageTime = 0;
            end

            pageOffset = (bigDisplay.currentPage - 1) * #bigDisplay.displayLines;
            for index, displayLine in pairs(bigDisplay.displayLines) do
                local lineIndex = index + pageOffset;
                if bigDisplay.lineInfos[lineIndex] ~= nil then
                    local lineInfo = bigDisplay.lineInfos[lineIndex];

                    local color = spec.bigDisplays[1].color;
                    if spec.changedColors[lineInfo.fillTypeId] ~= nil then
                        color = spec.changedColors[lineInfo.fillTypeId].color;
                    end

                    setTextColor(color[1], color[2], color[3], color[4])

                    local newTitle = lineInfo.renderTitle or lineInfo.title;

                    setTextAlignment(RenderText.ALIGN_LEFT)
                    renderText3D(displayLine.text.x, displayLine.text.y, displayLine.text.z, displayLine.rx, displayLine.ry, displayLine.rz, spec.bigDisplays[1].textSize, newTitle)
                    setTextAlignment(RenderText.ALIGN_RIGHT)
                    renderText3D(displayLine.value.x, displayLine.value.y, displayLine.value.z, displayLine.rx, displayLine.ry, displayLine.rz, spec.bigDisplays[1].textSize, lineInfo.fillLevel)
                end
            end
        end
    end
end

---Update
---@param dt number time since last call in ms
function BigDisplaySpecialization:update(dt)
    -- update faken, muss auch entfernt werden beim löschen, wenn es so klappt
    for _, display in pairs(BigDisplaySpecialization.displays) do
        display:updateDisplays(dt);
    end
end

---Update info for Info trigger
---@param superFunc function the original updateInfo implementation, discarded here since this override reimplements it instead of chaining to it
---@param infoTable table info-table to append entries to
function BigDisplaySpecialization:updateInfo(superFunc, infoTable)
    local spec = self.spec_bigDisplay;

    local owningFarm = g_farmManager:getFarmById(self:getOwnerFarmId());

    table.insert(infoTable, {
        title = g_i18n:getText("fieldInfo_ownedBy"),
        text = owningFarm.name
    })

    if (spec.loadingStationToUse ~= nil) then
        table.insert(infoTable, {
            title = g_i18n:getText("bigDisplay_connected_with"),
            text = spec.loadingStationToUse:getName();
        })
    end
end

---Change text size and display type of all displays in this placeable and send the new settings to the server
---@param textSize number the size of the text
---@param displayType integer the display type (0 = total, 1 = total and capacity, 2 = total and percentage)
---@param noEventSend? boolean if false or nil, the change is sent as a network event
function BigDisplaySpecialization:setSettings(textSize, displayType, noEventSend)
    local spec = self.spec_bigDisplay;

    for _, bigDisplay in pairs(spec.bigDisplays) do
        bigDisplay.textSize = textSize;
        bigDisplay.displayType = displayType;
        BigDisplaySpecialization:CreateDisplayLines(bigDisplay);
        spec.updateDisplaysRequested = true;
    end

    if noEventSend == nil or noEventSend == false then
        BigDisplaySettingEvent.sendEvent(self, textSize, displayType);
    end
end

---Send information to new connected players
---@param streamId integer network stream identification
---@param connection table connection information
function BigDisplaySpecialization:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_bigDisplay;
        streamWriteFloat32(streamId, spec.bigDisplays[1].textSize);
        streamWriteFloat32(streamId, spec.bigDisplays[1].displayType);
    end
end

---new connected players get information here
---@param streamId integer network stream identification
---@param connection table connection information
function BigDisplaySpecialization:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local textSize = streamReadFloat32(streamId);
        local displayType = streamReadFloat32(streamId);
        self:setSettings(textSize, displayType, true);
    end
end

addModEventListener(BigDisplaySpecialization)

---Append to onStartMission to make sure all displays are connected on start playing
function BigDisplaySpecialization:onStartMission()
    -- update faken, muss auch entfernt werden beim löschen, wenn es so klappt
    for _, display in pairs(BigDisplaySpecialization.displays) do
        display:reconnectToStorage();
    end
end
Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, BigDisplaySpecialization.onStartMission)
