--[[
Copyright (C) Achimobil

Important:
It is not allowed to copy in own Mods.
No changes are to be made to this script without permission from Achimobil.

Darf nicht in eigene Mods kopiert werden.
An diesem Skript dürfen ohne Genehmigung von Achimobil keine Änderungen vorgenommen werden.

No change Log because not allowed to use in other mods.
]]

BigDisplaySpecialization = {
    Name = "BigDisplaySpecialization",
    displays = {},
    Debug = true
}

BigDisplaySpecialization.modName = g_currentModName;
BigDisplaySpecialization.modDir = g_currentModDirectory;

source(BigDisplaySpecialization.modDir.."gui/displaySettingsDialog.lua");
source(BigDisplaySpecialization.modDir.."scripts/PlaceableObjectStorageExtension.lua");
source(BigDisplaySpecialization.modDir.."scripts/bigDisplaySpecializationActivatable.lua");
source(BigDisplaySpecialization.modDir.."scripts/bigDisplaySettingEvent.lua");

---Print the text to the log as info. Example: BigDisplaySpecialization.info("Alter: %s", age)
-- @param string infoMessage the text to print formated
-- @param any ... format parameter
function BigDisplaySpecialization.info(infoMessage, ...)
    if BigDisplaySpecialization.Debug then
        BigDisplaySpecialization.DebugText("Info:" .. infoMessage, ...)
    else
        Logging.info(BigDisplaySpecialization.modName .. " - " .. infoMessage, ...);
    end
end

---Print the text to the log as dev info. Example: BigDisplaySpecialization.devInfo("Alter: %s", age)
-- @param string infoMessage the text to print formated
-- @param any ... format parameter
function BigDisplaySpecialization.devInfo(infoMessage, ...)
    if infoMessage == nil then infoMessage = "nil" end
    if BigDisplaySpecialization.Debug then
        BigDisplaySpecialization.DebugText("DevInfo:" .. infoMessage, ...)
    else
        Logging.devInfo(BigDisplaySpecialization.modName .. " - " .. infoMessage, ...)
    end
end

--- Print the given Table to the log
-- @param string text parameter Text before the table
-- @param table myTable The table to print
-- @param number maxDepth depth of print, default 2
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
-- @param string text the text to print formated
-- @param any ... format parameter
function BigDisplaySpecialization.DebugText(text, ...)
    if not BigDisplaySpecialization.Debug then return end
    print("BigDisplaySpecialization Debug: " .. string.format(text, ...));
end

BigDisplaySpecialization.info("init %s", BigDisplaySpecialization.Name);

---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function BigDisplaySpecialization.prerequisitesPresent(specializations)
    return true;
end

--- register the event listeners for this spec
-- @param any placeableType
function BigDisplaySpecialization.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", BigDisplaySpecialization);
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", BigDisplaySpecialization);
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", BigDisplaySpecialization);
    SpecializationUtil.registerEventListener(placeableType, "onDelete", BigDisplaySpecialization)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", BigDisplaySpecialization)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", BigDisplaySpecialization)
end

--- register the functions for this spec
-- @param any placeableType
function BigDisplaySpecialization.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateDisplays", BigDisplaySpecialization.updateDisplays);
    SpecializationUtil.registerFunction(placeableType, "updateDisplayData", BigDisplaySpecialization.updateDisplayData);
    SpecializationUtil.registerFunction(placeableType, "reconnectToStorage", BigDisplaySpecialization.reconnectToStorage);
    SpecializationUtil.registerFunction(placeableType, "onStationDeleted", BigDisplaySpecialization.onStationDeleted);
    SpecializationUtil.registerFunction(placeableType, "triggerCallback", BigDisplaySpecialization.triggerCallback)
    SpecializationUtil.registerFunction(placeableType, "setSettings", BigDisplaySpecialization.setSettings)
end

--- register the overwritten functions for this spec
-- @param any placeableType
function BigDisplaySpecialization.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", BigDisplaySpecialization.updateInfo)
end

---
-- @param XMLSchema schema
-- @param string basePath
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
-- @param table xmlFile
-- @param string key
-- @param table usedModNames
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
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function BigDisplaySpecialization:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_bigDisplay;

    xmlFile:iterate(key .. ".display", function(index, displayKey)
        local size = xmlFile:getValue(displayKey.."#textSize", 0)
        local displayType = xmlFile:getValue(displayKey.."#displayType", 0)

        if spec.bigDisplays[index] ~= nil then
            if size ~= 0 then
                spec.bigDisplays[index].textSize = size;
            BigDisplaySpecialization:CreateDisplayLines(spec.bigDisplays[index]);
            end
            spec.bigDisplays[index].displayType = displayType;
        end
        return
    end)

    return true;
end

---Called on loading
-- @param table savegame savegame
function BigDisplaySpecialization:onLoad(savegame)
    self.spec_bigDisplay = {};
    local spec = self.spec_bigDisplay;
    local xmlFile = self.xmlFile;

    spec.bigDisplays = {};
    spec.changedColors = {}
    spec.updateDisplaysRunning = false;
    spec.updateDisplaysRequested = false;
    spec.updateDisplaysDtSinceLastTime = 9999;

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

        if not xmlFile:hasProperty(bigDisplayKey) then
            break;
        end

        local upperLeftNode = self.xmlFile:getValue(bigDisplayKey .. "#upperLeftNode", nil, self.components, self.i3dMappings);
        local height = self.xmlFile:getValue(bigDisplayKey .. "#height", 1);
        local width = self.xmlFile:getValue(bigDisplayKey .. "#width", 1);

        -- display general stuff
        local size = self.xmlFile:getValue(bigDisplayKey .. "#size", 0.11);
        local emptyFilltypes = xmlFile:getValue(bigDisplayKey .. "#emptyFilltypes", false)
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

    function spec.fillLevelChangedCallback(fillType, delta)
        self:updateDisplayData();
    end
end

--- create the lines for the given display
-- @param BigDisplay bigDisplay
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
-- @param integer triggerId id of trigger
-- @param integer otherId id of object that calls callback
-- @param boolean onEnter called on enter
-- @param boolean onLeave called on leave
-- @param boolean onStay called on stay
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

--- called by base class when placement is finialzing
-- @param table savegame savegame
function BigDisplaySpecialization:onFinalizePlacement(savegame)
    local spec = self.spec_bigDisplay;
    if spec.loadingStationToUse == nil then
        return;
    end
end

--- called by base class when placement finialzing is done
-- @param table savegame savegame
function BigDisplaySpecialization:onPostFinalizePlacement(savegame)
    table.insert(BigDisplaySpecialization.displays, self);
    self:reconnectToStorage();
end

---Reconnect to the next storage in range
-- @param table savegame savegame
function BigDisplaySpecialization:reconnectToStorage(savegame)

    local spec = self.spec_bigDisplay;

    if spec.loadingStationToUse ~= nil then
        local storages = spec.loadingStationToUse.sourceStorages or spec.loadingStationToUse.targetStorages;
        if storages ~= nil then
            for _, sourceStorage in pairs(storages) do
                sourceStorage:removeFillLevelChangedListeners(spec.fillLevelChangedCallback);
            end
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

        for j, loadingSt in pairs (storage.loadingStations) do
            if loadingStation == nil then
                loadingStation = loadingSt;
            end
        end

        if loadingStation == nil then
            for j, unloadingSt in pairs (storage.unloadingStations) do
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
    for index, productionPoint in ipairs(g_currentMission.productionChainManager:getProductionPointsForFarmId(farmId)) do

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
    for index, husbandryPlacable in ipairs(g_currentMission.husbandrySystem.placeables) do

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
    for index, placable in ipairs(g_currentMission.placeableSystem.placeables) do
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
    self:updateDisplayData();

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
        for fillTypeIndex, changedColor in pairs(spec.changedColors) do
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
        for fillType, fillLevel in pairs(spec.loadingStationToUse.owningPlaceable.spec_husbandryFood.fillLevels) do
            if spec.changedColors[fillType] == nil then
                spec.changedColors[fillType] = {isInput = false, isOutput = false};
            end
            spec.changedColors[fillType].color = spec.bigDisplays[1].colorInput;
        end
    end

    -- Auswahl welches storage connected wird
    local storages = spec.loadingStationToUse.sourceStorages or spec.loadingStationToUse.targetStorages;
    if storages ~= nil then
        for _, sourceStorage in pairs(storages) do
            sourceStorage:addFillLevelChangedListeners(spec.fillLevelChangedCallback);
        end
    elseif spec.loadingStationToUse.addFillLevelChangedListeners ~= nil then
        spec.loadingStationToUse:addFillLevelChangedListeners(spec.fillLevelChangedCallback);
    else
        BigDisplaySpecialization.info("no storage to add listener found");
        local storeSpec = spec.loadingStationToUse.spec_objectStorage;
        BigDisplaySpecialization.DebugTable("storeSpec", storeSpec);
    end

    spec.loadingStationToUse:addDeleteListener(self, "onStationDeleted")

    BigDisplaySpecialization.devInfo("Connected to %s", spec.loadingStationToUse:getName());
end

--- Called when current registered station is deleted to reconnect to another one
-- @param SellingStation station
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

---Get the distance between the target object and the given coordinates
-- @param Placeable loadingStation
-- @param float x
-- @param float y
-- @param float z
-- @return float distance
function BigDisplaySpecialization:getDistance(loadingStation, x, y, z)
    if loadingStation ~= nil then
        local tx, ty, tz = getWorldTranslation(loadingStation.rootNode)

        if tx == nil or ty == nil or tz == nil then
            -- fehlerhafte loadingstations deren position nicht ermitteln kann, ignorieren wir hier
            return math.huge
        end

        local distance = MathUtil.vector3Length(x - tx, y - ty, z - tz)
        -- BigDisplaySpecialization.devInfo("Distance check for %s, distance %s, station %s-%s-%s, display %s-%s-%s", loadingStation:getName(), distance,tx, ty, tz, x, y, z);
        return distance;
    end

    return math.huge
end

---Update the Data which the Display shows
function BigDisplaySpecialization:updateDisplayData()
    local spec = self.spec_bigDisplay;
    if spec == nil or spec.loadingStationToUse == nil then
        return;
    end

    -- only one time read at a time for more performance
    if spec.updateDisplaysRunning then
        return
    else
        if spec.updateDisplaysDtSinceLastTime <= 500 then
            spec.updateDisplaysRequested = true;
            return;
        end
    end
    spec.updateDisplaysRunning = true;

    BigDisplaySpecialization.devInfo("updateDisplayData")

    local farmId = self:getOwnerFarmId();

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
    end

    spec.updateDisplaysRunning = false;
    spec.updateDisplaysRequested = false;
    spec.updateDisplaysDtSinceLastTime = 0;
end

---format a volume
-- @param float liters amount to format
-- @param integer precision how many decimals
-- @param string unit which unit should be used, default 2
-- @return string the formated value
function BigDisplaySpecialization:formatVolume(liters, precision, unit)
    unit = unit ~= "" and (unit == false and "" or unit) or nil

    return g_i18n:formatVolume(liters, precision, unit)
end

---format a volume with capacity
-- @param float liters amount to format
-- @param float capacity capacity to format
-- @param integer precision how many decimals
-- @param string unit which unit should be used
-- @return string the formated value
function BigDisplaySpecialization:formatCapacity(liters, capacity, precision, unit)
    return self:formatVolume(liters, precision, false) .. " / " .. self:formatVolume(capacity, precision, unit);
end

--- Get all fill levels of the given station accessable by farmId
-- @param table station
-- @param integer farmId
-- @return table fillLevels
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
--         BigDisplaySpecialization.DebugTable("station.spec_objectStorage.objectInfos", station.spec_objectStorage.objectInfos, 4);
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

---Compare the given obects by title
-- @param table w1
-- @param table w2
-- @return boolean CompareResult
function BigDisplaySpecialization.compLineInfos(w1,w2)
    return w1.title < w2.title;
end

---Update the displays. Update the data if old
-- @param float dt time since last call in ms
function BigDisplaySpecialization:updateDisplays(dt)
    local spec = self.spec_bigDisplay;
    if spec == nil or spec.loadingStationToUse == nil then
        return;
    end

    if not self.isClient then
        return;
    end

    spec.updateDisplaysDtSinceLastTime = spec.updateDisplaysDtSinceLastTime + dt;
    if spec.updateDisplaysRequested then
        self:updateDisplayData();
    end

    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)

    for _, bigDisplay in pairs(spec.bigDisplays) do

        -- entfernung zum display ermitteln damit es nicht immer gerendert wird
        -- display position nur ein mal ermitteln
        if bigDisplay.worldTranslation == nil then
            bigDisplay.worldTranslation = {getWorldTranslation(bigDisplay.nodeId)};
        end

        -- position des spielers
        local x, z = 0, 0;
        if g_currentMission.hud.controlledVehicle ~= nil then
            x, _, z = getWorldTranslation(g_currentMission.hud.controlledVehicle.rootNode);
        elseif g_localPlayer.rootNode ~= nil then
            x, _, z = getWorldTranslation(g_localPlayer.rootNode);
        end

        local currentDistance = MathUtil.vector2Length(x - bigDisplay.worldTranslation[1], z - bigDisplay.worldTranslation[3]);
        local countOfDisplayLines = #bigDisplay.displayLines;

        if currentDistance < bigDisplay.textDrawDistance and countOfDisplayLines ~= 0 then
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

                    local fillLevelWidth = getText3DWidth(spec.bigDisplays[1].textSize, lineInfo.fillLevel);
                    local titleWidth = getText3DWidth(spec.bigDisplays[1].textSize, lineInfo.title);
                    local maxWidth = displayLine.width - fillLevelWidth;

                    local newTitle = lineInfo.title
                    if titleWidth > maxWidth then
                        local numChars = getTextLength(spec.bigDisplays[1].textSize, newTitle, 1);
                        local maxChars = math.floor(numChars / titleWidth * maxWidth) - 1;
                        newTitle = utf8Substr(newTitle, 0, maxChars) .. "…";

                    end

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
-- @param float dt time since last call in ms
function BigDisplaySpecialization:update(dt)
    -- update faken, muss auch entfernt werden beim löschen, wenn es so klappt
    for _, display in pairs(BigDisplaySpecialization.displays) do
        display:updateDisplays(dt);
    end
end

---Update info for Info trigger
-- @param function superFunc
-- @param table infoTable
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

---Change Text size of all displays in this placable and send new size to server
-- @param float textSize the size of the text
-- @param integer displayType the size of the text
-- @param boolean noEventSend if false will send the event
function BigDisplaySpecialization:setSettings(textSize, displayType, noEventSend)
    local spec = self.spec_bigDisplay;

    for _, bigDisplay in pairs(spec.bigDisplays) do
        bigDisplay.textSize = textSize;
        bigDisplay.displayType = displayType;
        BigDisplaySpecialization:CreateDisplayLines(bigDisplay);
        self:updateDisplayData();
    end

    if noEventSend == nil or noEventSend == false then
        BigDisplaySettingEvent.sendEvent(self, textSize, displayType);
    end
end

---Send information to new connected players
-- @param integer streamId network stream identification
-- @param table connection connection information
function BigDisplaySpecialization:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_bigDisplay;
        streamWriteFloat32(streamId, spec.bigDisplays[1].textSize);
        streamWriteFloat32(streamId, spec.bigDisplays[1].displayType);
    end
end

---new connected players get information here
-- @param integer streamId network stream identification
-- @param table connection connection information
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
