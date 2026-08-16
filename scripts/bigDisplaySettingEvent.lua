--[[
Copyright (C) Achimobil

Send change setting event
]]

BigDisplaySettingEvent = {};
local BigDisplaySettingEvent_mt = Class(BigDisplaySettingEvent, Event);
InitEventClass(BigDisplaySettingEvent, "BigDisplaySettingEvent");

---Creates an empty event instance for stream reading
---@return table self the new event instance
function BigDisplaySettingEvent.emptyNew()
    local self = Event.new(BigDisplaySettingEvent_mt);
    return self;
end

---Creates a new event carrying the display settings to broadcast
---@param placeable table the display placeable the settings apply to
---@param textSize number the new text size
---@param displayType integer the new display type
---@return table self the new event instance
function BigDisplaySettingEvent.new(placeable, textSize, displayType)
    local self = BigDisplaySettingEvent.emptyNew();
    self.placeable = placeable;
    self.textSize = textSize;
    self.displayType = displayType;
    return self;
end

---Writes the display settings to the network stream
---@param streamId integer network stream identification
---@param connection table connection information
function BigDisplaySettingEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable);
    streamWriteFloat32(streamId, self.textSize);
    streamWriteInt8(streamId, self.displayType);
end

---Reads the display settings from the network stream and applies them
---@param streamId integer network stream identification
---@param connection table connection information
function BigDisplaySettingEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId);
    self.textSize = streamReadFloat32(streamId);
    self.displayType = streamReadInt8(streamId);

    self:run(connection)
end

---Applies the transported display settings and rebroadcasts the event on the server
---@param connection table connection information
function BigDisplaySettingEvent:run(connection)
    if self.placeable ~= nil then

        self.placeable:setSettings(self.textSize, self.displayType, true);

        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false)
        end
    end
end

---Sends the display settings event to the server or broadcasts it to all clients
---@param placeable table the display placeable the settings apply to
---@param textSize number the new text size
---@param displayType integer the new display type
---@param noEventSend? boolean if true, the event is not sent
function BigDisplaySettingEvent.sendEvent(placeable, textSize, displayType, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_currentMission:getIsServer() then
            g_server:broadcastEvent(BigDisplaySettingEvent.new(placeable, textSize, displayType), false)
        else
            g_client:getServerConnection():sendEvent(BigDisplaySettingEvent.new(placeable, textSize, displayType))
        end
    end
end
