-- einfpgen der fehlenden aufrufe von onHusbandryFillLevelChanged in die PlaceableHusbandryFood methoden

PlaceableHusbandryFoodExtension = {};

---Overwritten addFood: also raises onHusbandryFillLevelChanged so displays react to the added food
---@param superFunc function the original PlaceableHusbandryFood.addFood implementation
---@param farmId integer id of the farm adding the food
---@param deltaFillLevel number amount of food added
---@param fillTypeIndex integer fill type index of the added food
---@param fillPositionData table|nil position data of the added fill, if any
---@param toolType integer|nil tool type used to add the food
---@param extraAttributes table|nil additional attributes passed through to the base implementation
---@return number result the result returned by the original addFood implementation
function PlaceableHusbandryFoodExtension:addFood(superFunc, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
    local result = superFunc(self, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes);

    SpecializationUtil.raiseEvent(self, "onHusbandryFillLevelChanged", fillTypeIndex, deltaFillLevel);

    return result;
end

PlaceableHusbandryFood.addFood = Utils.overwrittenFunction(PlaceableHusbandryFood.addFood, PlaceableHusbandryFoodExtension.addFood)


---Overwritten removeFood: also raises onHusbandryFillLevelChanged so displays react to the removed food
---@param superFunc function the original PlaceableHusbandryFood.removeFood implementation
---@param absDeltaFillLevel number absolute amount of food removed
---@param fillTypeIndex integer fill type index of the removed food
---@return number result the result returned by the original removeFood implementation
function PlaceableHusbandryFoodExtension:removeFood(superFunc, absDeltaFillLevel, fillTypeIndex)
    local result = superFunc(self, absDeltaFillLevel, fillTypeIndex);

    SpecializationUtil.raiseEvent(self, "onHusbandryFillLevelChanged", fillTypeIndex, absDeltaFillLevel);

    return result;
end

PlaceableHusbandryFood.removeFood = Utils.overwrittenFunction(PlaceableHusbandryFood.removeFood, PlaceableHusbandryFoodExtension.removeFood)
