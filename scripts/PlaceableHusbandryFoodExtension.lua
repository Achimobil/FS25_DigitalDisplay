-- einfpgen der fehlenden aufrufe von onHusbandryFillLevelChanged in die PlaceableHusbandryFood methoden

PlaceableHusbandryFoodExtension = {};

function PlaceableHusbandryFoodExtension:addFood(superFunc, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
    local result = superFunc(self, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes);

    SpecializationUtil.raiseEvent(self, "onHusbandryFillLevelChanged", fillTypeIndex, deltaFillLevel);

    return result;
end

PlaceableHusbandryFood.addFood = Utils.overwrittenFunction(PlaceableHusbandryFood.addFood, PlaceableHusbandryFoodExtension.addFood)


function PlaceableHusbandryFoodExtension:removeFood(superFunc, absDeltaFillLevel, fillTypeIndex)
    local result = superFunc(self, absDeltaFillLevel, fillTypeIndex);

    SpecializationUtil.raiseEvent(self, "onHusbandryFillLevelChanged", fillTypeIndex, absDeltaFillLevel);

    return result;
end

PlaceableHusbandryFood.removeFood = Utils.overwrittenFunction(PlaceableHusbandryFood.removeFood, PlaceableHusbandryFoodExtension.removeFood)