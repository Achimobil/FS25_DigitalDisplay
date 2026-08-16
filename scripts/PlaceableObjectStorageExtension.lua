---Extends PlaceableObjectStorage with fill-level-changed listener support
PlaceableObjectStorageExtension = {}

---Notifies all registered fill-level-changed listeners whenever the object storage's visual areas are updated
function PlaceableObjectStorageExtension:updateObjectStorageVisualAreas()
    if self.fillLevelChangedListeners == nil then self.fillLevelChangedListeners = {} end;

    for _, func in ipairs(self.fillLevelChangedListeners) do
        func(nil, nil);
    end
end

PlaceableObjectStorage.updateObjectStorageVisualAreas = Utils.appendedFunction(PlaceableObjectStorage.updateObjectStorageVisualAreas, PlaceableObjectStorageExtension.updateObjectStorageVisualAreas)

---Registers the fill-level-changed listener functions on the given placeable type
---@param placeableType table the placeable type to register the functions on
function PlaceableObjectStorageExtension.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "addFillLevelChangedListeners", PlaceableObjectStorage.addFillLevelChangedListeners)
    SpecializationUtil.registerFunction(placeableType, "removeFillLevelChangedListeners", PlaceableObjectStorage.removeFillLevelChangedListeners)
end
PlaceableObjectStorage.registerFunctions = Utils.appendedFunction(PlaceableObjectStorage.registerFunctions, PlaceableObjectStorageExtension.registerFunctions)

---Adds a callback that is invoked whenever this object storage's fill level changes
---@param fillLevelChangedCallback function callback invoked with (fillType, delta) on change
function PlaceableObjectStorage:addFillLevelChangedListeners(fillLevelChangedCallback)
    if self.fillLevelChangedListeners == nil then self.fillLevelChangedListeners = {} end;
    table.addElement(self.fillLevelChangedListeners, fillLevelChangedCallback);
end
---Removes a previously registered fill-level-changed callback
---@param fillLevelChangedCallback function the callback to remove
function PlaceableObjectStorage:removeFillLevelChangedListeners(fillLevelChangedCallback)
    if self.fillLevelChangedListeners == nil then self.fillLevelChangedListeners = {} end;
    table.removeElement(self.fillLevelChangedListeners, fillLevelChangedCallback);
end
