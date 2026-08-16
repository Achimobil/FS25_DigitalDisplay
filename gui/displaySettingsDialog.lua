---Dialog for changing a display's text size and display type
DisplaySettingsDialog = {}
local DisplaySettingsDialog_mt = Class(DisplaySettingsDialog, YesNoDialog);

---Registers the dialog's gui XML with the gui system
function DisplaySettingsDialog.register()
    local displaySettingsDialog = DisplaySettingsDialog.new();
    local path = Utils.getFilename("gui/DisplaySettingsDialog.xml", BigDisplaySpecialization.modDir);
    ---@diagnostic disable-next-line: param-type-mismatch
    g_gui:loadGui(path, "DisplaySettingsDialog", displaySettingsDialog);
    DisplaySettingsDialog.INSTANCE = displaySettingsDialog;
end

---Opens the dialog for the given display placeable
---@param placable table the display placeable to change settings for
function DisplaySettingsDialog.show(placable)
    if DisplaySettingsDialog.INSTANCE ~= nil then
        local dialog = DisplaySettingsDialog.INSTANCE;
        dialog.placable = placable;
        dialog:setTitle(g_i18n:getText("DisplaySettings_Title"))
        g_gui:showDialog("DisplaySettingsDialog")
    end
end


---Creates a new display settings dialog instance
---@param target table|nil dialog target, passed through to YesNoDialog.new
---@param custom_mt table|nil custom metatable, passed through to YesNoDialog.new
---@return table self the new dialog instance
function DisplaySettingsDialog.new(target, custom_mt)
    local self = YesNoDialog.new(target, custom_mt or DisplaySettingsDialog_mt)
    self.selectedFillType = 1
    self.selectedPackage = 1
    self.selectedAmount = 0
    return self
end

---Recreates the dialog from an existing gui instance (nur relevant für den GIANTS-Debug-Konsolenbefehl "GUI neu laden" während des Testens)
---@param gui table the existing dialog instance being replaced
---@param guiName string name of the gui
function DisplaySettingsDialog.createFromExistingGui(gui, guiName)
    DisplaySettingsDialog.register()
    DisplaySettingsDialog.show(gui.placable)
end


---Auswahl verarbeiten
function DisplaySettingsDialog:onClickOk()

    local textSize = (self.textSizeElement:getState() + 7) / 100;
    local displayType = self.valueDisplayTypeElement:getState() - 1;

    local spec = self.placable;
    if spec ~= nil then
        spec:setSettings(textSize, displayType);
    else
        Logging.info("Could not find placable to set settings")
    end

    self:close()
end


---Abbrechen
function DisplaySettingsDialog:onClickBack()
    self:close()
end

---Dialog-Titel einstellen
---@param title string the dialog title text to display
function DisplaySettingsDialog:setTitle(title)
    DisplaySettingsDialog:superClass().setTitle(self, title)
    self.dialogTitle = title
end

---Fills the dialog's dropdown elements with the current display settings when it is opened
function DisplaySettingsDialog:onOpen()
    DisplaySettingsDialog:superClass().onOpen(self)
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
