BigDisplaySpecializationActivatable = {}
local BigDisplaySpecializationActivatable_mt = Class(BigDisplaySpecializationActivatable)

function BigDisplaySpecializationActivatable.new(placeable)
    local self = setmetatable({}, BigDisplaySpecializationActivatable_mt);
    self.placeable = placeable;
    self.activateText = g_i18n:getText("action_openMenu");
    return self;
end

function BigDisplaySpecializationActivatable:getIsActivatable()
    return true;
end

function BigDisplaySpecializationActivatable:run()
    -- jetzt Dialog mit einstellungen öffenen, aber zum testen einfach nur die textgröße erhöhen
    local spec = self.placeable.spec_bigDisplay;
    for _, bigDisplay in pairs(spec.bigDisplays) do
        bigDisplay.textSize = bigDisplay.textSize + 0.01;
        BigDisplaySpecialization:CreateDisplayLines(bigDisplay);
    end
end

function BigDisplaySpecializationActivatable:getDistance(x, y, z)
    if self.placeable.spec_bigDisplay.playerTrigger ~= nil then
        local tx, ty, tz = getWorldTranslation(self.placeable.spec_bigDisplay.playerTrigger)
        return MathUtil.vector3Length(x-tx, y-ty, z-tz)
    end

    return math.huge
end