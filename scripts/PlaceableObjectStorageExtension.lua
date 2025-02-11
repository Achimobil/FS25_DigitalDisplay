-- PlaceableObjectStorage um event erweitern
PlaceableObjectStorageExtension = {}
function PlaceableObjectStorageExtension:updateObjectStorageVisualAreas()
    if self.fillLevelChangedListeners == nil then self.fillLevelChangedListeners = {} end;

    for _, func in ipairs(self.fillLevelChangedListeners) do
        func(nil, nil);
    end
end

PlaceableObjectStorage.updateObjectStorageVisualAreas = Utils.appendedFunction(PlaceableObjectStorage.updateObjectStorageVisualAreas, PlaceableObjectStorageExtension.updateObjectStorageVisualAreas)

function PlaceableObjectStorageExtension.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "addFillLevelChangedListeners", PlaceableObjectStorage.addFillLevelChangedListeners)
    SpecializationUtil.registerFunction(placeableType, "removeFillLevelChangedListeners", PlaceableObjectStorage.removeFillLevelChangedListeners)
end
PlaceableObjectStorage.registerFunctions = Utils.appendedFunction(PlaceableObjectStorage.registerFunctions, PlaceableObjectStorageExtension.registerFunctions)

function PlaceableObjectStorage:addFillLevelChangedListeners(fillLevelChangedCallback)
    if self.fillLevelChangedListeners == nil then self.fillLevelChangedListeners = {} end;
    table.addElement(self.fillLevelChangedListeners, fillLevelChangedCallback);
end
function PlaceableObjectStorage:removeFillLevelChangedListeners(fillLevelChangedCallback)
    if self.fillLevelChangedListeners == nil then self.fillLevelChangedListeners = {} end;
    table.removeElement(self.fillLevelChangedListeners, fillLevelChangedCallback);
end