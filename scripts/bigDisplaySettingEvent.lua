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

function BigDisplaySettingEvent.new(placeable, textSize)
    local self = BigDisplaySettingEvent.emptyNew();
    self.placeable = placeable;
    self.textSize = textSize;
    return self;
end

-- @param integer streamId network stream identification
-- @param table connection connection information
function BigDisplaySettingEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable);
    streamWriteFloat32(streamId, self.textSize);
end

-- @param integer streamId network stream identification
-- @param table connection connection information
function BigDisplaySettingEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId);
    self.textSize = streamReadFloat32(streamId);

    self:run(connection)
end

function BigDisplaySettingEvent:run(connection)
    if self.placeable ~= nil then

        self.placeable:setTextSize(self.textSize, true);

        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false)
        end
    end
end

function BigDisplaySettingEvent.sendEvent(placeable, textSize, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_currentMission:getIsServer() then
            g_server:broadcastEvent(BigDisplaySettingEvent.new(placeable, textSize), false)
        else
            g_client:getServerConnection():sendEvent(BigDisplaySettingEvent.new(placeable, textSize))
        end
    end
end