---Activatable that opens the display settings dialog when triggered
BigDisplaySpecializationActivatable = {}
local BigDisplaySpecializationActivatable_mt = Class(BigDisplaySpecializationActivatable)

---Creates a new activatable for the given display placeable
---@param placeable table the display placeable this activatable belongs to
---@return table self the new activatable instance
function BigDisplaySpecializationActivatable.new(placeable)
    local self = setmetatable({}, BigDisplaySpecializationActivatable_mt);
    self.placeable = placeable;
    self.activateText = g_i18n:getText("action_openDisplaySettings");
    return self;
end

---Whether this activatable can currently be triggered
---@return boolean isActivatable always true
function BigDisplaySpecializationActivatable:getIsActivatable()
    return true;
end

---Opens the display settings dialog for this placeable
function BigDisplaySpecializationActivatable:run()
    -- jetzt Dialog mit einstellungen öffenen, aber zum testen einfach nur die textgröße erhöhen

    DisplaySettingsDialog.show(self.placeable);
end

---Gets the distance between the player trigger and the given coordinates
---@param x number world x coordinate
---@param y number world y coordinate
---@param z number world z coordinate
---@return number distance distance to the player trigger, or math.huge if no trigger exists
function BigDisplaySpecializationActivatable:getDistance(x, y, z)
    if self.placeable.spec_bigDisplay.playerTrigger ~= nil then
        local tx, ty, tz = getWorldTranslation(self.placeable.spec_bigDisplay.playerTrigger)
        return MathUtil.vector3Length(x-tx, y-ty, z-tz)
    end

    return math.huge
end
