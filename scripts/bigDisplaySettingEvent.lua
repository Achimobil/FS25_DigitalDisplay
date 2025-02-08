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

function BigDisplaySettingEvent:writeStream(streamId, connection)
    BigDisplaySpecialization.DebugText("BigDisplaySettingEvent:writeStream");
    NetworkUtil.writeNodeObject(streamId, self.placeable);
    streamWriteFloat32(streamId, self.textSize);
end

function BigDisplaySettingEvent:readStream(streamId, connection)
    BigDisplaySpecialization.DebugText("BigDisplaySettingEvent:readStream");
    self.placeable = NetworkUtil.readNodeObject(streamId);
    self.textSize = streamReadFloat32(streamId);

    self:run(connection)
end

function BigDisplaySettingEvent:run(connection)
    BigDisplaySpecialization.DebugText("BigDisplaySettingEvent:run");
    if self.placeable ~= nil then

        self.placeable:setTextSize(self.textSize, true);

        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false)
        end
    end
end

function BigDisplaySettingEvent.sendEvent(placeable, textSize, noEventSend)
    BigDisplaySpecialization.DebugText("BigDisplaySettingEvent:sendEvent(%s, %s, %s)", placeable, textSize, noEventSend);
    BigDisplaySpecialization.DebugText("g_currentMission:getIsServer() = %s", g_currentMission:getIsServer());
    if noEventSend == nil or noEventSend == false then
        if g_currentMission:getIsServer() then
            g_server:broadcastEvent(BigDisplaySettingEvent.new(placeable, textSize), false)
        else
            g_client:getServerConnection():sendEvent(BigDisplaySettingEvent.new(placeable, textSize))
        end
    end
end