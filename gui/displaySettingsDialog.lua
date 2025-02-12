DisplaySettingsDialog = {}
local DisplaySettingsDialog_mt = Class(DisplaySettingsDialog, YesNoDialog);

function DisplaySettingsDialog.register()
    local displaySettingsDialog = DisplaySettingsDialog.new();
    local path = Utils.getFilename("gui/DisplaySettingsDialog.xml", BigDisplaySpecialization.modDir);
    g_gui:loadGui(path, "DisplaySettingsDialog", displaySettingsDialog);
    DisplaySettingsDialog.INSTANCE = displaySettingsDialog;
end

function DisplaySettingsDialog.show(placable)
    if DisplaySettingsDialog.INSTANCE ~= nil then
        local dialog = DisplaySettingsDialog.INSTANCE;
        dialog.placable = placable;
        dialog:setTitle(g_i18n:getText("DisplaySettings_Title"))
        g_gui:showDialog("DisplaySettingsDialog")
    end
end


function DisplaySettingsDialog.new(target, custom_mt)
    local self = YesNoDialog.new(target, custom_mt or DisplaySettingsDialog_mt)
    self.selectedFillType = 1
    self.selectedPackage = 1
    self.selectedAmount = 0
    return self
end

-- @param guiName name of the gui
function DisplaySettingsDialog.createFromExistingGui(gui, guiName)
    DisplaySettingsDialog.register()
    local callback = gui.callbackFunc
    local target = gui.target
    local title = gui.dialogTitle
    local fillTypesSelection = gui.fillTypesSelection
    DisplaySettingsDialog.show(callback, target, title, fillTypesSelection)
end


---Auswahl verarbeiten
function DisplaySettingsDialog:onClickOk()

    local textSize = (self.textSizeElement:getState() + 7) / 100;
    local displayType = self.valueDisplayTypeElement:getState() - 1;

    local spec = self.placable;
    spec:setSettings(textSize, displayType);

    self:close()
end


---Abbrechen
function DisplaySettingsDialog:onClickBack()
    self:close()
end


---Dialog-Titel einstellen
-- @param string title
function DisplaySettingsDialog:setTitle(title)
    DisplaySettingsDialog:superClass().setTitle(self, title)
    self.dialogTitle = title
end

---Buttens anlegen
function DisplaySettingsDialog:onCreateButten()

end

function DisplaySettingsDialog:onOpen()
    local textSizeOptions = {}
    for i = 8, 15, 1 do
        local text = string.format("%d", i)

        table.insert(textSizeOptions, text)
    end

    local spec = self.placable.spec_bigDisplay;
    local currentSize = math.round(spec.bigDisplays[1].textSize * 100) - 7;

    self.textSizeElement:setTexts(textSizeOptions)
    self.textSizeElement:setState(currentSize, true)

    local valueDisplayTypeOptions = {}
    table.insert(valueDisplayTypeOptions, g_i18n:getText("setting_Value_0"));
    table.insert(valueDisplayTypeOptions, g_i18n:getText("setting_Value_1"));
    table.insert(valueDisplayTypeOptions, g_i18n:getText("setting_Value_2"));

    self.valueDisplayTypeElement:setTexts(valueDisplayTypeOptions)
    self.valueDisplayTypeElement:setState(spec.bigDisplays[1].displayType + 1, true)
end