--[[
Copyright (C) Achimobil

Send change setting event
]]

BigDisplaySettingEvent = {};
local BigDisplaySettingEvent_mt = Class(BigDisplaySettingEvent, Event);
InitEventClass(BigDisplaySettingEvent, "BigDisplaySettingEvent");

function BigDisplaySettingEvent.emptyNew()
    local self = Event.new(BigDisplaySettingEvent_mt);
    return self;
end

function BigDisplaySettingEvent.new(placeable, textSize, displayType)
    local self = BigDisplaySettingEvent.emptyNew();
    self.placeable = placeable;
    self.textSize = textSize;
    self.displayType = displayType;
    return self;
end

-- @param integer streamId network stream identification
-- @param table connection connection information
function BigDisplaySettingEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable);
    streamWriteFloat32(streamId, self.textSize);
    streamWriteInt8(streamId, self.displayType);
end

-- @param integer streamId network stream identification
-- @param table connection connection information
function BigDisplaySettingEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId);
    self.textSize = streamReadFloat32(streamId);
    self.displayType = streamReadInt8(streamId);

    self:run(connection)
end

function BigDisplaySettingEvent:run(connection)
    if self.placeable ~= nil then

        self.placeable:setSettings(self.textSize, self.displayType, true);

        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false)
        end
    end
end

function BigDisplaySettingEvent.sendEvent(placeable, textSize, displayType, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_currentMission:getIsServer() then
            g_server:broadcastEvent(BigDisplaySettingEvent.new(placeable, textSize, displayType), false)
        else
            g_client:getServerConnection():sendEvent(BigDisplaySettingEvent.new(placeable, textSize, displayType))
        end
    end
end