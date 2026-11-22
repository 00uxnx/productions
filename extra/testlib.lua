local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library
Library.Options = {}
Library.Windows = {}
Library.ConfigStorage = {}
Library.ThemeCallbacks = {}
Library.Unloaded = false

local Player = Players.LocalPlayer
local Themes = {
    GTA = {
        Background = Color3.fromRGB(15, 17, 19),
        Panel = Color3.fromRGB(23, 26, 29),
        PanelLight = Color3.fromRGB(31, 35, 39),
        Row = Color3.fromRGB(27, 30, 33),
        RowSelected = Color3.fromRGB(48, 54, 57),
        Border = Color3.fromRGB(57, 63, 67),
        Text = Color3.fromRGB(239, 241, 239),
        Muted = Color3.fromRGB(151, 159, 161),
        Accent = Color3.fromRGB(112, 190, 105),
        AccentDark = Color3.fromRGB(63, 130, 67),
        Danger = Color3.fromRGB(211, 83, 76)
    },
    Midnight = {
        Background = Color3.fromRGB(13, 16, 24),
        Panel = Color3.fromRGB(20, 25, 37),
        PanelLight = Color3.fromRGB(29, 36, 52),
        Row = Color3.fromRGB(24, 30, 44),
        RowSelected = Color3.fromRGB(41, 53, 76),
        Border = Color3.fromRGB(57, 70, 96),
        Text = Color3.fromRGB(236, 241, 250),
        Muted = Color3.fromRGB(144, 157, 180),
        Accent = Color3.fromRGB(91, 161, 255),
        AccentDark = Color3.fromRGB(54, 112, 193),
        Danger = Color3.fromRGB(220, 83, 92)
    },
    Crimson = {
        Background = Color3.fromRGB(18, 14, 16),
        Panel = Color3.fromRGB(29, 21, 24),
        PanelLight = Color3.fromRGB(40, 29, 33),
        Row = Color3.fromRGB(33, 24, 28),
        RowSelected = Color3.fromRGB(57, 37, 43),
        Border = Color3.fromRGB(80, 53, 61),
        Text = Color3.fromRGB(247, 239, 241),
        Muted = Color3.fromRGB(169, 145, 151),
        Accent = Color3.fromRGB(226, 83, 100),
        AccentDark = Color3.fromRGB(154, 48, 63),
        Danger = Color3.fromRGB(255, 105, 105)
    }
}

Library.Theme = Themes.GTA
Library.ThemeName = "GTA"

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 4) }, object)
end

local function addStroke(object, color, transparency)
    return create("UIStroke", {
        Color = color or Library.Theme.Border,
        Transparency = transparency or 0,
        Thickness = 1
    }, object)
end

local function tween(object, properties, duration)
    local animation = TweenService:Create(object, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local function copyTable(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copyTable(item)
    end
    return result
end

local function makeFlag(text)
    local flag = tostring(text or "Option"):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if flag == "" then
        flag = "option"
    end
    return flag
end

local function getEnvironment()
    if type(getgenv) == "function" then
        local success, environment = pcall(getgenv)
        if success and type(environment) == "table" then
            return environment
        end
    end
    return _G
end

local function getGlobalFunction(name)
    local environment = getEnvironment()
    local candidate = environment and environment[name]
    if type(candidate) == "function" then
        return candidate
    end
    local fallback = _G and _G[name]
    if type(fallback) == "function" then
        return fallback
    end
    return nil
end

function Library:BindTheme(callback)
    table.insert(self.ThemeCallbacks, callback)
    callback(self.Theme)
end

function Library:SetTheme(theme)
    local selected = type(theme) == "string" and Themes[theme] or theme
    if type(selected) ~= "table" then
        return false
    end
    self.Theme = selected
    self.ThemeName = type(theme) == "string" and theme or "Custom"
    for _, callback in ipairs(self.ThemeCallbacks) do
        pcall(callback, selected)
    end
    return true
end

Library.ThemeManager = {}
function Library.ThemeManager:SetTheme(theme)
    return Library:SetTheme(theme)
end
function Library.ThemeManager:GetThemes()
    local names = {}
    for name in pairs(Themes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end
function Library.ThemeManager:GetTheme()
    return Library.ThemeName, Library.Theme
end
function Library.ThemeManager:AddTheme(name, theme)
    if type(name) ~= "string" or type(theme) ~= "table" then
        return false
    end
    Themes[name] = copyTable(theme)
    return true
end

local function encodeValue(value)
    if typeof(value) == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    end
    if typeof(value) == "EnumItem" then
        return { __type = "EnumItem", enum = tostring(value.EnumType), name = value.Name }
    end
    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do
            result[key] = encodeValue(item)
        end
        return result
    end
    return value
end

local function decodeValue(value)
    if type(value) ~= "table" then
        return value
    end
    if value.__type == "Color3" then
        return Color3.new(value.r or 1, value.g or 1, value.b or 1)
    end
    if value.__type == "EnumItem" then
        local enumName = tostring(value.enum or "Enum.KeyCode"):match("Enum%.(%w+)") or "KeyCode"
        local enumType = Enum[enumName]
        if enumType and value.name and enumType[value.name] then
            return enumType[value.name]
        end
        return Enum.KeyCode.Unknown
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = decodeValue(item)
    end
    return result
end

local function safeFileName(name)
    return tostring(name or "default"):gsub("[^%w_%-]", "_")
end

Library.ConfigManager = {}
Library.ConfigManager.Folder = "UnnamedHook"
Library.ConfigManager.ConfigFolder = "UnnamedHook/Configs"

function Library.ConfigManager:Save(name)
    name = safeFileName(name)
    local data = {
        Theme = Library.ThemeName,
        SelectionMode = Library.SelectionMode or "Normal",
        Values = {}
    }
    for flag, option in pairs(Library.Options) do
        if option and option.GetConfigValue then
            local success, value = pcall(option.GetConfigValue, option)
            if success then
                data.Values[flag] = encodeValue(value)
            end
        end
    end
    local encoded = HttpService:JSONEncode(data)
    Library.ConfigStorage[name] = encoded
    local makefolderFunction = getGlobalFunction("makefolder")
    local isfolderFunction = getGlobalFunction("isfolder")
    local writefileFunction = getGlobalFunction("writefile")
    if writefileFunction then
        pcall(function()
            if makefolderFunction and (not isfolderFunction or not isfolderFunction(self.Folder)) then
                makefolderFunction(self.Folder)
            end
            if makefolderFunction and (not isfolderFunction or not isfolderFunction(self.ConfigFolder)) then
                makefolderFunction(self.ConfigFolder)
            end
            writefileFunction(self.ConfigFolder .. "/" .. name .. ".json", encoded)
        end)
    end
    return true, encoded
end

function Library.ConfigManager:Load(name)
    name = safeFileName(name)
    local encoded = Library.ConfigStorage[name]
    local readfileFunction = getGlobalFunction("readfile")
    local isfileFunction = getGlobalFunction("isfile")
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if readfileFunction then
        local success, result = pcall(function()
            if isfileFunction and not isfileFunction(path) then
                return nil
            end
            return readfileFunction(path)
        end)
        if success and type(result) == "string" then
            encoded = result
        end
    end
    if type(encoded) ~= "string" then
        return false, "Config not found"
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(encoded)
    end)
    if not success or type(data) ~= "table" then
        return false, "Config could not be decoded"
    end
    if data.Theme then
        Library:SetTheme(data.Theme)
    end
    if data.SelectionMode then
        for _, window in ipairs(Library.Windows) do
            window:SetSelectionMode(data.SelectionMode)
        end
    end
    for flag, value in pairs(data.Values or {}) do
        local option = Library.Options[flag]
        if option and option.SetValue then
            pcall(option.SetValue, option, decodeValue(value), true)
        end
    end
    return true, "Config loaded"
end

function Library.ConfigManager:List()
    local results = {}
    for name in pairs(Library.ConfigStorage) do
        results[name] = true
    end
    local listfilesFunction = getGlobalFunction("listfiles")
    if listfilesFunction then
        local success, files = pcall(listfilesFunction, self.ConfigFolder)
        if success and type(files) == "table" then
            for _, path in ipairs(files) do
                local fileName = tostring(path):match("([^/\\]+)%.json$")
                if fileName then
                    results[fileName] = true
                end
            end
        end
    end
    local names = {}
    for name in pairs(results) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Library.ConfigManager:Delete(name)
    name = safeFileName(name)
    Library.ConfigStorage[name] = nil
    local deleteFunction = getGlobalFunction("delfile")
    local isfileFunction = getGlobalFunction("isfile")
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if deleteFunction then
        pcall(function()
            if not isfileFunction or isfileFunction(path) then
                deleteFunction(path)
            end
        end)
    end
    return true
end

local function addRow(section, labelText, selectable)
    local window = section.Window
    local theme = Library.Theme
    local row = create("Frame", {
        Name = "OptionRow",
        BackgroundColor3 = theme.Row,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 34)
    }, section.Container)
    addCorner(row, 3)
    local accent = create("Frame", {
        Name = "SelectionBar",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -8),
        Position = UDim2.new(0, 0, 0, 4),
        Visible = false
    }, row)
    addCorner(accent, 2)
    local hitbox = create("TextButton", {
        Name = "Hitbox",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2
    }, row)
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.58, -12, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(labelText),
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    }, row)
    local control = {
        Window = window,
        Section = section,
        Row = row,
        Hitbox = hitbox,
        Label = label,
        Accent = accent,
        Selectable = selectable ~= false,
        Focused = false
    }
    function control:SetFocused(state)
        self.Focused = state
        self.Accent.Visible = state and self.Window.SelectionMode == "Normal"
        tween(self.Row, {
            BackgroundColor3 = state and Library.Theme.RowSelected or Library.Theme.Row
        }, 0.1)
    end
    function control:SetLabel(value)
        self.Label.Text = tostring(value)
    end
    function control:GetConfigValue()
        return self.Value
    end
    function control:SetValue(value)
        self.Value = value
    end
    function control:Activate() end
    function control:Adjust() end
    if selectable then
        table.insert(section.Tab.Controls, control)
        if section.Window.CurrentTab == section.Tab and not section.Window.FocusedControl then
            section.Tab:FocusControl(1)
        end
    end
    hitbox.Activated:Connect(function()
        if selectable then
            section.Tab:FocusControl(control)
        end
        if control.Activate then
            control:Activate()
        end
    end)
    hitbox.MouseEnter:Connect(function()
        if window.SelectionMode == "Mouse" then
            control:SetFocused(true)
        end
    end)
    hitbox.MouseLeave:Connect(function()
        if window.SelectionMode == "Mouse" and window.FocusedControl ~= control then
            control:SetFocused(false)
        end
    end)
    Library:BindTheme(function(newTheme)
        row.BackgroundColor3 = newTheme.Row
        label.TextColor3 = newTheme.Text
        accent.BackgroundColor3 = newTheme.Accent
        if control.Focused then
            row.BackgroundColor3 = newTheme.RowSelected
        end
    end)
    return control
end

local Section = {}
Section.__index = Section

function Section:AddLabel(text)
    local control = addRow(self, text, false)
    control.Row.BackgroundTransparency = 1
    control.Label.Position = UDim2.fromOffset(8, 0)
    control.Label.Size = UDim2.new(1, -16, 1, 0)
    control.Label.TextColor3 = Library.Theme.Muted
    control.Hitbox.Visible = false
    Library:BindTheme(function(theme)
        control.Label.TextColor3 = theme.Muted
    end)
    return control
end

function Section:AddButton(label, callback)
    local control = addRow(self, label, true)
    control.ValueLabel = create("TextLabel", {
        Name = "ActionHint",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(24, 20),
        Font = Enum.Font.GothamBold,
        Text = ">",
        TextColor3 = Library.Theme.Muted,
        TextSize = 15,
        ZIndex = 3
    }, control.Row)
    function control:Activate()
        if callback then
            task.spawn(callback)
        end
    end
    Library:BindTheme(function(theme)
        control.ValueLabel.TextColor3 = theme.Muted
    end)
    return control
end

function Section:AddToggle(label, settings)
    if type(settings) == "function" then
        settings = { Callback = settings }
    elseif type(settings) == "boolean" then
        settings = { Default = settings }
    end
    settings = settings or {}
    local control = addRow(self, label, true)
    local flag = settings.Flag or makeFlag(label)
    local state = settings.Default == true
    local indicator = create("Frame", {
        Name = "ToggleIndicator",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(34, 17),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3
    }, control.Row)
    addCorner(indicator, 9)
    local dot = create("Frame", {
        Name = "ToggleDot",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(13, 13),
        BackgroundColor3 = Library.Theme.Muted,
        BorderSizePixel = 0,
        ZIndex = 4
    }, indicator)
    addCorner(dot, 8)
    function control:SetValue(value, silent)
        state = value == true
        self.Value = state
        tween(indicator, { BackgroundColor3 = state and Library.Theme.AccentDark or Library.Theme.PanelLight }, 0.12)
        tween(dot, { Position = state and UDim2.fromOffset(19, 2) or UDim2.fromOffset(2, 2), BackgroundColor3 = state and Color3.new(1, 1, 1) or Library.Theme.Muted }, 0.12)
        if not silent and settings.Callback then
            task.spawn(settings.Callback, state)
        end
    end
    function control:Activate()
        self:SetValue(not state)
    end
    function control:Adjust(direction)
        if direction ~= 0 then
            self:SetValue(not state)
        end
    end
    control:SetValue(state, true)
    Library.Options[flag] = control
    Library:BindTheme(function(theme)
        if not state then
            indicator.BackgroundColor3 = theme.PanelLight
            dot.BackgroundColor3 = theme.Muted
        else
            indicator.BackgroundColor3 = theme.AccentDark
            dot.BackgroundColor3 = Color3.new(1, 1, 1)
        end
    end)
    return control
end

function Section:AddSlider(label, settings)
    settings = settings or {}
    local minimum = tonumber(settings.Min) or 0
    local maximum = tonumber(settings.Max) or 100
    local step = math.abs(tonumber(settings.Step) or 1)
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    if step == 0 then
        step = 1
    end
    local decimals = tonumber(settings.Decimals)
    if decimals == nil then
        decimals = step < 1 and 2 or 0
    end
    local control = addRow(self, label, true)
    local valueLabel = create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 2),
        Size = UDim2.fromOffset(82, 15),
        Font = Enum.Font.GothamSemibold,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3
    }, control.Row)
    local track = create("Frame", {
        Name = "Track",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 8),
        Size = UDim2.fromOffset(122, 4),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3
    }, control.Row)
    addCorner(track, 3)
    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 4
    }, track)
    addCorner(fill, 3)
    local dragging = false
    local function formatValue(value)
        local formatted = string.format("%." .. tostring(decimals) .. "f", value)
        if decimals == 0 then
            formatted = tostring(math.floor(value + 0.5))
        end
        return formatted .. tostring(settings.Suffix or "")
    end
    local function setFromX(x)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minimum + (maximum - minimum) * ratio
        local snapped = minimum + math.floor(((raw - minimum) / step) + 0.5) * step
        control:SetValue(math.clamp(snapped, minimum, maximum))
    end
    function control:SetValue(value, silent)
        value = math.clamp(tonumber(value) or minimum, minimum, maximum)
        value = minimum + math.floor(((value - minimum) / step) + 0.5) * step
        value = math.clamp(value, minimum, maximum)
        self.Value = value
        local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valueLabel.Text = formatValue(value)
        if not silent and settings.Callback then
            task.spawn(settings.Callback, value)
        end
    end
    function control:Adjust(direction)
        self:SetValue((self.Value or minimum) + direction * step)
    end
    function control:Activate()
        local x = UserInputService:GetMouseLocation().X
        if x >= track.AbsolutePosition.X and x <= track.AbsolutePosition.X + track.AbsoluteSize.X then
            setFromX(x)
        end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    table.insert(control.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))
    table.insert(control.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    control:SetValue(settings.Default ~= nil and settings.Default or minimum, true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        track.BackgroundColor3 = theme.PanelLight
        fill.BackgroundColor3 = theme.Accent
        valueLabel.TextColor3 = theme.Text
    end)
    return control
end

function Section:AddInput(label, settings)
    if type(settings) == "function" then
        settings = { Callback = settings }
    end
    settings = settings or {}
    local control = addRow(self, label, true)
    local inputBox = create("TextBox", {
        Name = "Input",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(160, 24),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = tostring(settings.Placeholder or "Enter value"),
        PlaceholderColor3 = Library.Theme.Muted,
        Text = tostring(settings.Default or ""),
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, control.Row)
    addCorner(inputBox, 3)
    create("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, inputBox)
    function control:SetValue(value, silent)
        self.Value = tostring(value or "")
        inputBox.Text = self.Value
        if not silent and settings.Callback then
            task.spawn(settings.Callback, self.Value)
        end
    end
    function control:Activate()
        inputBox:CaptureFocus()
    end
    inputBox.FocusLost:Connect(function(enterPressed)
        control.Value = inputBox.Text
        if enterPressed and settings.Callback then
            task.spawn(settings.Callback, control.Value)
        elseif settings.Callback and settings.FireOnFocusLost then
            task.spawn(settings.Callback, control.Value)
        end
    end)
    function control:GetConfigValue()
        return inputBox.Text
    end
    control:SetValue(settings.Default or "", true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        inputBox.BackgroundColor3 = theme.PanelLight
        inputBox.TextColor3 = theme.Text
        inputBox.PlaceholderColor3 = theme.Muted
    end)
    return control
end

function Section:AddKeyPicker(label, settings)
    settings = settings or {}
    local control = addRow(self, label, true)
    local keyButton = create("TextButton", {
        Name = "KeyButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(92, 23),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Text = "None",
        ZIndex = 4
    }, control.Row)
    addCorner(keyButton, 3)
    function control:SetValue(value, silent)
        if type(value) == "string" then
            value = Enum.KeyCode[value] or Enum.KeyCode.Unknown
        end
        self.Value = value or Enum.KeyCode.Unknown
        keyButton.Text = self.Value == Enum.KeyCode.Unknown and "None" or self.Value.Name
        if not silent and settings.Callback then
            task.spawn(settings.Callback, self.Value)
        end
    end
    function control:Activate()
        self.Window.CapturingKey = self
        keyButton.Text = "Press key..."
    end
    function control:GetConfigValue()
        return self.Value
    end
    function control:SetCapturedKey(value)
        self:SetValue(value)
    end
    keyButton.Activated:Connect(function()
        control:Activate()
    end)
    control:SetValue(settings.Default or Enum.KeyCode.Unknown, true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    control.KeyCallback = settings.ChangedCallback or settings.OnKey
    Library:BindTheme(function(theme)
        keyButton.BackgroundColor3 = theme.PanelLight
        keyButton.TextColor3 = theme.Text
    end)
    return control
end

function Section:AddDropdown(label, settings)
    if type(settings) == "table" and settings[1] ~= nil then
        settings = { Options = settings }
    end
    settings = settings or {}
    local options = settings.Options or {}
    local multi = settings.Multi == true
    local control = addRow(self, label, true)
    local valueButton = create("TextButton", {
        Name = "DropdownValue",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(152, 23),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Text = "Select",
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 4
    }, control.Row)
    addCorner(valueButton, 3)
    local popup
    local popupItems = {}
    local selectedIndex = 1
    local function hasValue(list, value)
        for _, entry in ipairs(list) do
            if entry == value then
                return true
            end
        end
        return false
    end
    local function renderValue()
        if multi then
            valueButton.Text = #control.Value == 0 and "Select" or table.concat(control.Value, ", ")
        else
            valueButton.Text = control.Value == nil and "Select" or tostring(control.Value)
        end
    end
    local function closePopup()
        if popup then
            popup:Destroy()
            popup = nil
        end
        control.Window.CurrentDropdown = nil
    end
    local function choose(value)
        if multi then
            local result = copyTable(control.Value or {})
            local found = false
            for index, entry in ipairs(result) do
                if entry == value then
                    table.remove(result, index)
                    found = true
                    break
                end
            end
            if not found then
                table.insert(result, value)
            end
            control:SetValue(result)
        else
            control:SetValue(value)
            closePopup()
        end
    end
    local function rebuildPopup()
        if popup then
            popup:Destroy()
        end
        if multi then
            selectedIndex = math.clamp(selectedIndex, 1, math.max(#options, 1))
        else
            selectedIndex = table.find(options, control.Value) or 1
        end
        popupItems = {}
        local height = math.min(#options, 7) * 27 + 8
        local absolute = control.Row.AbsolutePosition
        popup = create("Frame", {
            Name = "DropdownPopup",
            Position = UDim2.fromOffset(absolute.X + control.Row.AbsoluteSize.X - 180, absolute.Y + control.Row.AbsoluteSize.Y + 3),
            Size = UDim2.fromOffset(174, math.max(height, 36)),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0,
            ZIndex = 50
        }, control.Window.Gui)
        addCorner(popup, 4)
        addStroke(popup)
        local list = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.new(1, -8, 1, -8),
            CanvasSize = UDim2.new(0, 0, 0, #options * 27),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            ZIndex = 51
        }, popup)
        create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        for index, option in ipairs(options) do
            local selected = multi and hasValue(control.Value or {}, option) or (not multi and control.Value == option)
            local item = create("TextButton", {
                Name = "Choice",
                LayoutOrder = index,
                Size = UDim2.new(1, -2, 0, 25),
                BackgroundColor3 = selected and Library.Theme.RowSelected or Library.Theme.Row,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                Text = tostring(option),
                TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 52
            }, list)
            addCorner(item, 2)
            create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, item)
            item.Activated:Connect(function()
                choose(option)
            end)
            popupItems[index] = item
        end
        control.Window.CurrentDropdown = control
    end
    function control:SetValue(value, silent)
        if multi then
            if type(value) ~= "table" then
                value = value == nil and {} or { value }
            end
            self.Value = copyTable(value)
        else
            self.Value = value
        end
        renderValue()
        if not silent and settings.Callback then
            task.spawn(settings.Callback, self.Value)
        end
        if popup then
            rebuildPopup()
        end
    end
    function control:Activate()
        if popup then
            closePopup()
        else
            rebuildPopup()
        end
    end
    function control:Adjust(direction)
        if #options == 0 or direction == 0 then
            return
        end
        if multi then
            selectedIndex = math.clamp(selectedIndex + direction, 1, #options)
            choose(options[selectedIndex])
        else
            local index = table.find(options, self.Value) or 0
            index = ((index - 1 + direction) % #options) + 1
            self:SetValue(options[index])
        end
    end
    function control:HandlePopupKey(keyCode)
        if not popup then
            return false
        end
        if keyCode == Enum.KeyCode.Escape then
            closePopup()
        elseif keyCode == Enum.KeyCode.Up then
            selectedIndex = math.max(1, selectedIndex - 1)
        elseif keyCode == Enum.KeyCode.Down then
            selectedIndex = math.min(#options, selectedIndex + 1)
        elseif keyCode == Enum.KeyCode.Return or keyCode == Enum.KeyCode.KeypadEnter then
            if options[selectedIndex] ~= nil then
                choose(options[selectedIndex])
            end
        end
        for index, item in ipairs(popupItems) do
            local selected = index == selectedIndex
            item.BackgroundColor3 = selected and Library.Theme.RowSelected or Library.Theme.Row
            item.TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text
        end
        return true
    end
    control.ClosePopup = closePopup
    valueButton.Activated:Connect(function()
        control:Activate()
    end)
    local default = settings.Default
    if multi then
        default = type(default) == "table" and default or {}
    elseif default == nil and settings.AllowNull == true then
        default = nil
    elseif default == nil then
        default = options[1]
    end
    control:SetValue(default, true)
    if settings.Default ~= nil and not multi then
        selectedIndex = table.find(options, settings.Default) or 1
    end
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        valueButton.BackgroundColor3 = theme.PanelLight
        valueButton.TextColor3 = theme.Text
        if popup then
            popup.BackgroundColor3 = theme.Panel
        end
    end)
    return control
end

function Section:AddColorPicker(label, settings)
    settings = settings or {}
    local control = addRow(self, label, true)
    local swatch = create("TextButton", {
        Name = "ColorSwatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(42, 20),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4
    }, control.Row)
    addCorner(swatch, 3)
    local popup
    local hue = 0.32
    local saturation = 0.45
    local brightness = 0.9
    local function updateColor(silent)
        local color = Color3.fromHSV(hue, saturation, brightness)
        control:SetValue(color, silent)
    end
    local function setSV(position)
        if not popup then
            return
        end
        local area = popup:FindFirstChild("SVArea")
        if not area then
            return
        end
        saturation = math.clamp((position.X - area.AbsolutePosition.X) / math.max(area.AbsoluteSize.X, 1), 0, 1)
        brightness = 1 - math.clamp((position.Y - area.AbsolutePosition.Y) / math.max(area.AbsoluteSize.Y, 1), 0, 1)
        updateColor()
    end
    local function setHue(position)
        if not popup then
            return
        end
        local bar = popup:FindFirstChild("HueBar")
        if not bar then
            return
        end
        hue = math.clamp((position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local color = Color3.fromHSV(hue, saturation, brightness)
        local area = popup:FindFirstChild("SVArea")
        if area then
            area.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        end
        control:SetValue(color)
    end
    local function closePopup()
        if control.PopupConnection then
            control.PopupConnection:Disconnect()
            control.PopupConnection = nil
        end
        if popup then
            popup:Destroy()
            popup = nil
        end
        control.Window.ColorPickerOpen = nil
    end
    local function openPopup()
        closePopup()
        local absolute = control.Row.AbsolutePosition
        popup = create("Frame", {
            Name = "ColorPickerPopup",
            Position = UDim2.fromOffset(absolute.X + control.Row.AbsoluteSize.X - 206, absolute.Y + control.Row.AbsoluteSize.Y + 4),
            Size = UDim2.fromOffset(196, 190),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0,
            ZIndex = 60
        }, control.Window.Gui)
        addCorner(popup, 4)
        addStroke(popup)
        local sv = create("Frame", {
            Name = "SVArea",
            Position = UDim2.fromOffset(9, 9),
            Size = UDim2.fromOffset(178, 112),
            BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 61
        }, popup)
        addCorner(sv, 3)
        local white = create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 62
        }, sv)
        local whiteGradient = create("UIGradient", {
            Rotation = 0,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.95) })
        }, white)
        local black = create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 63
        }, sv)
        create("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        }, black)
        local marker = create("Frame", {
            Name = "Marker",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(saturation, 1 - brightness),
            Size = UDim2.fromOffset(9, 9),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 65
        }, sv)
        addCorner(marker, 8)
        addStroke(marker, Color3.new(0, 0, 0), 0.1)
        local hueBar = create("Frame", {
            Name = "HueBar",
            Position = UDim2.fromOffset(9, 129),
            Size = UDim2.fromOffset(178, 13),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 61
        }, popup)
        addCorner(hueBar, 3)
        create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
        }, hueBar)
        local hexBox = create("TextBox", {
            Name = "HexInput",
            Position = UDim2.fromOffset(9, 151),
            Size = UDim2.fromOffset(178, 27),
            BackgroundColor3 = Library.Theme.PanelLight,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextColor3 = Library.Theme.Text,
            TextSize = 11,
            Text = "#" .. control.Value:ToHex(),
            ZIndex = 62
        }, popup)
        addCorner(hexBox, 3)
        sv.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setSV(input.Position)
            end
        end)
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setHue(input.Position)
            end
        end)
        local moveConnection
        moveConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    local mouse = UserInputService:GetMouseLocation()
                    if sv and mouse.X >= sv.AbsolutePosition.X and mouse.X <= sv.AbsolutePosition.X + sv.AbsoluteSize.X and mouse.Y >= sv.AbsolutePosition.Y and mouse.Y <= sv.AbsolutePosition.Y + sv.AbsoluteSize.Y then
                        setSV(mouse)
                        marker.Position = UDim2.fromScale(saturation, 1 - brightness)
                    elseif hueBar and mouse.X >= hueBar.AbsolutePosition.X and mouse.X <= hueBar.AbsolutePosition.X + hueBar.AbsoluteSize.X and mouse.Y >= hueBar.AbsolutePosition.Y - 5 and mouse.Y <= hueBar.AbsolutePosition.Y + hueBar.AbsoluteSize.Y + 5 then
                        setHue(mouse)
                    end
                end
            end
        end)
        control.PopupConnection = moveConnection
        table.insert(control.Window.Connections, moveConnection)
        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("#", "")
            if #hex == 6 then
                local success, color = pcall(Color3.fromHex, hex)
                if success then
                    control:SetValue(color)
                end
            end
            hexBox.Text = "#" .. control.Value:ToHex()
        end)
        control.PopupRefresh = function()
            if popup and sv and marker and hexBox then
                sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                marker.Position = UDim2.fromScale(saturation, 1 - brightness)
                hexBox.Text = "#" .. control.Value:ToHex()
            end
        end
        control.Window.ColorPickerOpen = control
    end
    function control:SetValue(value, silent)
        if typeof(value) ~= "Color3" then
            value = Library.Theme.Accent
        end
        self.Value = value
        hue, saturation, brightness = value:ToHSV()
        swatch.BackgroundColor3 = value
        if not silent and settings.Callback then
            task.spawn(settings.Callback, value)
        end
        if self.PopupRefresh then
            self.PopupRefresh()
        end
    end
    function control:Activate()
        if popup then
            closePopup()
        else
            openPopup()
        end
    end
    function control:GetConfigValue()
        return self.Value
    end
    control.ClosePopup = closePopup
    swatch.Activated:Connect(function()
        control:Activate()
    end)
    control:SetValue(settings.Default or Library.Theme.Accent, true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        if popup then
            popup.BackgroundColor3 = theme.Panel
        end
    end)
    return control
end

local Tab = {}
Tab.__index = Tab
function Tab:AddSection(name)
    local sectionFrame = create("Frame", {
        Name = "Section",
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 36)
    }, self.Content)
    addCorner(sectionFrame, 4)
    addStroke(sectionFrame)
    local heading = create("TextLabel", {
        Name = "Heading",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = tostring(name),
        TextColor3 = Library.Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }, sectionFrame)
    local container = create("Frame", {
        Name = "Options",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(5, 30),
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, sectionFrame)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, container)
    local section = setmetatable({ Window = self.Window, Tab = self, Frame = sectionFrame, Container = container, Layout = layout }, Section)
    local function updateSize()
        sectionFrame.Size = UDim2.new(1, -8, 0, 36 + container.AbsoluteSize.Y)
    end
    container.ChildAdded:Connect(updateSize)
    container.ChildRemoved:Connect(updateSize)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    Library:BindTheme(function(theme)
        sectionFrame.BackgroundColor3 = theme.Panel
        heading.TextColor3 = theme.Accent
        local stroke = sectionFrame:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.Border
        end
    end)
    return section
end

function Tab:FocusControl(controlOrIndex)
    local previous = self.FocusedControl
    if previous and previous.SetFocused then
        previous:SetFocused(false)
    end
    local index
    if type(controlOrIndex) == "number" then
        index = controlOrIndex
    else
        index = table.find(self.Controls, controlOrIndex)
    end
    if not index or #self.Controls == 0 then
        self.SelectedIndex = 0
        self.FocusedControl = nil
        self.Window.FocusedControl = nil
        return
    end
    index = math.clamp(index, 1, #self.Controls)
    self.SelectedIndex = index
    self.FocusedControl = self.Controls[index]
    self.Window.FocusedControl = self.FocusedControl
    self.FocusedControl:SetFocused(true)
    local row = self.FocusedControl.Row
    local page = self.Content
    local top = row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
    local bottom = top + row.AbsoluteSize.Y
    local current = page.CanvasPosition.Y
    if top < current then
        page.CanvasPosition = Vector2.new(0, top)
    elseif bottom > current + page.AbsoluteSize.Y then
        page.CanvasPosition = Vector2.new(0, bottom - page.AbsoluteSize.Y)
    end
end

function Tab:MoveSelection(direction)
    if #self.Controls == 0 then
        return
    end
    local nextIndex = (self.SelectedIndex or 1) + direction
    if nextIndex < 1 then
        nextIndex = #self.Controls
    elseif nextIndex > #self.Controls then
        nextIndex = 1
    end
    self:FocusControl(nextIndex)
end

local Window = {}
Window.__index = Window

function Library:CreateWindow(settings)
    settings = settings or {}
    local guiParent = Player:WaitForChild("PlayerGui")
    local gui = create("ScreenGui", {
        Name = "UnnamedHookUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000
    }, guiParent)
    local window = setmetatable({
        Gui = gui,
        Tabs = {},
        Items = {},
        SelectionMode = "Normal",
        Open = true,
        ToggleKey = settings.ToggleKey or Enum.KeyCode.RightShift,
        FocusedControl = nil,
        CapturingKey = nil,
        CurrentDropdown = nil,
        ColorPickerOpen = nil,
        Connections = {},
        Title = settings.Title or "Unnamed Hook",
        SelectionMode = settings.SelectionMode == "Mouse" and "Mouse" or "Normal"
    }, Window)
    table.insert(Library.Windows, window)
    Library.SelectionMode = window.SelectionMode

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = settings.Size or UDim2.fromOffset(690, 448),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, gui)
    window.Main = main
    addCorner(main, 6)
    addStroke(main, Library.Theme.Border)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        Active = true
    }, main)
    addCorner(topbar, 6)
    local topbarCover = create("Frame", {
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8)
    }, topbar)
    local logo = create("TextLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.fromOffset(34, 43),
        Font = Enum.Font.GothamBlack,
        Text = "UH",
        TextColor3 = Library.Theme.Accent,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left
    }, topbar)
    local title = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(55, 0),
        Size = UDim2.new(0.6, -55, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = tostring(window.Title):upper(),
        TextColor3 = Library.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, topbar)
    local topHint = create("TextLabel", {
        Name = "TopHint",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.fromOffset(180, 43),
        Font = Enum.Font.Gotham,
        Text = "UNNAMED HOOK  /  CLIENT",
        TextColor3 = Library.Theme.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right
    }, topbar)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 43),
        Size = UDim2.new(0, 158, 1, -43),
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0
    }, main)
    local sidebarLine = create("Frame", {
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Library.Theme.Border,
        BorderSizePixel = 0
    }, sidebar)
    local tabList = create("Frame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 12),
        Size = UDim2.new(1, -16, 1, -52)
    }, sidebar)
    create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    local sidebarFooter = create("TextLabel", {
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 1, -32),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "UH  •  BUILD 01",
        TextColor3 = Library.Theme.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    }, sidebar)

    local pageHolder = create("Frame", {
        Name = "PageHolder",
        Position = UDim2.fromOffset(158, 43),
        Size = UDim2.new(1, -158, 1, -75),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, main)
    local pageTitle = create("TextLabel", {
        Name = "PageTitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 6),
        Size = UDim2.new(1, -32, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = "SELECT A CATEGORY",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pageHolder)
    local pageSubtitle = create("TextLabel", {
        Name = "PageSubtitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 32),
        Size = UDim2.new(1, -32, 0, 18),
        Font = Enum.Font.Gotham,
        Text = "Choose an option using the selection keys",
        TextColor3 = Library.Theme.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pageHolder)
    local pages = create("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 56),
        Size = UDim2.new(1, -24, 1, -63)
    }, pageHolder)
    local footer = create("Frame", {
        Name = "NavigationFooter",
        Position = UDim2.new(0, 158, 1, -32),
        Size = UDim2.new(1, -158, 0, 32),
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0
    }, main)
    local footerText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "↑  ↓  SELECT     ←  →  ADJUST     ENTER  CONFIRM     RIGHT SHIFT  HIDE",
        TextColor3 = Library.Theme.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    }, footer)

    window.PageTitle = pageTitle
    window.PageSubtitle = pageSubtitle
    window.FooterText = footerText
    window.TabList = tabList
    window.Pages = pages

    function window:AddTab(name, icon)
        local tabButton = create("TextButton", {
            Name = "Tab_" .. tostring(name),
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold,
            Text = "",
            ZIndex = 2
        }, self.TabList)
        addCorner(tabButton, 3)
        local marker = create("Frame", {
            Name = "Marker",
            Position = UDim2.fromOffset(0, 5),
            Size = UDim2.new(0, 3, 1, -10),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 3
        }, tabButton)
        addCorner(marker, 2)
        local tabName = create("TextLabel", {
            Name = "TabName",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -18, 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = (icon and tostring(icon) .. "   " or "") .. tostring(name):upper(),
            TextColor3 = Library.Theme.Muted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3
        }, tabButton)
        local content = create("ScrollingFrame", {
            Name = "Content_" .. tostring(name),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            Visible = false
        }, self.Pages)
        local layout = create("UIListLayout", {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, content)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
        local tab = setmetatable({ Window = self, Name = tostring(name), Button = tabButton, Marker = marker, TabName = tabName, Content = content, Controls = {}, SelectedIndex = 1 }, Tab)
        table.insert(self.Tabs, tab)
        tabButton.Activated:Connect(function()
            self:SelectTab(tab)
        end)
        Library:BindTheme(function(theme)
            tabButton.BackgroundColor3 = self.CurrentTab == tab and theme.RowSelected or theme.Panel
            tabName.TextColor3 = self.CurrentTab == tab and theme.Text or theme.Muted
            marker.BackgroundColor3 = theme.Accent
            content.ScrollBarImageColor3 = theme.Accent
        end)
        if #self.Tabs == 1 then
            self:SelectTab(tab)
        end
        return tab
    end

    function window:SelectTab(tabOrName)
        local tab = tabOrName
        if type(tabOrName) == "string" then
            for _, item in ipairs(self.Tabs) do
                if item.Name == tabOrName then
                    tab = item
                    break
                end
            end
        end
        if type(tabOrName) == "number" then
            tab = self.Tabs[tabOrName]
        end
        if not tab then
            return false
        end
        if self.CurrentTab and self.CurrentTab.FocusedControl then
            self.CurrentTab.FocusedControl:SetFocused(false)
        end
        self.CurrentTab = tab
        for _, item in ipairs(self.Tabs) do
            local active = item == tab
            item.Content.Visible = active
            item.Marker.Visible = active
            item.Button.BackgroundColor3 = active and Library.Theme.RowSelected or Library.Theme.Panel
            item.TabName.TextColor3 = active and Library.Theme.Text or Library.Theme.Muted
        end
        self.PageTitle.Text = tab.Name:upper()
        self.PageSubtitle.Text = "Use the arrow keys to navigate and enter to confirm"
        if #tab.Controls > 0 then
            tab:FocusControl(math.clamp(tab.SelectedIndex or 1, 1, #tab.Controls))
        else
            self.FocusedControl = nil
        end
        return true
    end

    function window:SetSelectionMode(mode)
        mode = tostring(mode or "Normal")
        if mode:lower() == "mouse" then
            self.SelectionMode = "Mouse"
        else
            self.SelectionMode = "Normal"
        end
        Library.SelectionMode = self.SelectionMode
        self.FooterText.Text = self.SelectionMode == "Normal" and "↑  ↓  SELECT     ←  →  ADJUST     ENTER  CONFIRM     RIGHT SHIFT  HIDE" or "MOUSE  SELECT     CLICK  OPTIONS     RIGHT SHIFT  HIDE"
        for _, tab in ipairs(self.Tabs) do
            for _, control in ipairs(tab.Controls) do
                control.Accent.Visible = control.Focused and self.SelectionMode == "Normal"
            end
        end
    end

    function window:SetOpen(state)
        self.Open = state == true
        main.Visible = self.Open
        if not self.Open then
            if self.CurrentDropdown and self.CurrentDropdown.ClosePopup then
                self.CurrentDropdown:ClosePopup()
            end
            if self.ColorPickerOpen and self.ColorPickerOpen.ClosePopup then
                self.ColorPickerOpen:ClosePopup()
            end
            self.CapturingKey = nil
        end
    end

    function window:Toggle()
        self:SetOpen(not self.Open)
    end

    function window:CreateWatermark(text)
        if self.Watermark then
            self.Watermark:Destroy()
        end
        local watermark = create("Frame", {
            Name = "UH_Watermark",
            Position = UDim2.fromOffset(14, 14),
            Size = UDim2.fromOffset(220, 28),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0
        }, self.Gui)
        addCorner(watermark, 4)
        addStroke(watermark)
        local accent = create("Frame", {
            Size = UDim2.new(0, 3, 1, -8),
            Position = UDim2.fromOffset(0, 4),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0
        }, watermark)
        addCorner(accent, 2)
        local watermarkText = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 0),
            Size = UDim2.new(1, -18, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = tostring(text or "UNNAMED HOOK"),
            TextColor3 = Library.Theme.Text,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        }, watermark)
        self.Watermark = watermark
        Library:BindTheme(function(theme)
            watermark.BackgroundColor3 = theme.Panel
            accent.BackgroundColor3 = theme.Accent
            watermarkText.TextColor3 = theme.Text
            local stroke = watermark:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = theme.Border
            end
        end)
        return watermark
    end

    function window:Notify(message, duration)
        local notification = create("Frame", {
            Name = "Notification",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(260, 54),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0
        }, self.Gui)
        addCorner(notification, 4)
        addStroke(notification)
        local bar = create("Frame", {
            Size = UDim2.new(0, 3, 1, -10),
            Position = UDim2.fromOffset(0, 5),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0
        }, notification)
        addCorner(bar, 2)
        local textLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -22, 1, 0),
            Font = Enum.Font.Gotham,
            Text = tostring(message),
            TextColor3 = Library.Theme.Text,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left
        }, notification)
        notification.Position = UDim2.new(1, 280, 1, -18)
        tween(notification, { Position = UDim2.new(1, -18, 1, -18) }, 0.2)
        task.delay(duration or 3, function()
            if notification.Parent then
                tween(notification, { Position = UDim2.new(1, 280, 1, -18), BackgroundTransparency = 1 }, 0.2)
                task.delay(0.22, function()
                    if notification then
                        notification:Destroy()
                    end
                end)
            end
        end)
    end

    local function onInputBegan(input, processed)
        if window.CapturingKey and input.KeyCode ~= Enum.KeyCode.Unknown then
            local capture = window.CapturingKey
            window.CapturingKey = nil
            local key = input.KeyCode
            if key == Enum.KeyCode.Escape then
                key = Enum.KeyCode.Unknown
            end
            capture:SetCapturedKey(key)
            return
        end
        if input.KeyCode == window.ToggleKey then
            window:Toggle()
            return
        end
        if not window.Open or processed then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if window.CurrentDropdown and window.CurrentDropdown.HandlePopupKey then
            local handled = window.CurrentDropdown:HandlePopupKey(input.KeyCode)
            if handled then
                return
            end
        end
        if window.ColorPickerOpen and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace) then
            window.ColorPickerOpen:ClosePopup()
            return
        end
        if window.SelectionMode == "Normal" and window.CurrentTab then
            local tab = window.CurrentTab
            local key = input.KeyCode
            if key == Enum.KeyCode.Up or key == Enum.KeyCode.W then
                tab:MoveSelection(-1)
            elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.S then
                tab:MoveSelection(1)
            elseif key == Enum.KeyCode.Left or key == Enum.KeyCode.A then
                if window.FocusedControl and window.FocusedControl.Adjust then
                    window.FocusedControl:Adjust(-1)
                end
            elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.D then
                if window.FocusedControl and window.FocusedControl.Adjust then
                    window.FocusedControl:Adjust(1)
                end
            elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.Space then
                if window.FocusedControl and window.FocusedControl.Activate then
                    window.FocusedControl:Activate()
                end
            elseif key == Enum.KeyCode.Tab then
                local index = table.find(window.Tabs, window.CurrentTab) or 1
                index = index % #window.Tabs + 1
                window:SelectTab(index)
            end
        end
    end

    local dragging = false
    local dragStart
    local startPosition
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)
    table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    table.insert(window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    table.insert(window.Connections, UserInputService.InputBegan:Connect(onInputBegan))
    table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not window.Open or window.CapturingKey then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        for _, tab in ipairs(window.Tabs) do
            for _, control in ipairs(tab.Controls) do
                if control.Value and typeof(control.Value) == "EnumItem" and control.Value.EnumType == Enum.KeyCode and control.Value == input.KeyCode and control.KeyCallback then
                    task.spawn(control.KeyCallback, input.KeyCode)
                end
            end
        end
    end))

    table.insert(window.Connections, gui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            for _, connection in ipairs(window.Connections) do
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end
    end))

    Library:BindTheme(function(theme)
        main.BackgroundColor3 = theme.Background
        topbar.BackgroundColor3 = theme.Panel
        topbarCover.BackgroundColor3 = theme.Panel
        logo.TextColor3 = theme.Accent
        title.TextColor3 = theme.Text
        topHint.TextColor3 = theme.Muted
        sidebar.BackgroundColor3 = theme.Panel
        sidebarLine.BackgroundColor3 = theme.Border
        sidebarFooter.TextColor3 = theme.Muted
        pageTitle.TextColor3 = theme.Text
        pageSubtitle.TextColor3 = theme.Muted
        footer.BackgroundColor3 = theme.Panel
        footerText.TextColor3 = theme.Muted
        local stroke = main:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.Border
        end
    end)

    window:SetSelectionMode(window.SelectionMode)
    if settings.Watermark ~= false then
        window:CreateWatermark(settings.WatermarkText or "UNNAMED HOOK  •  UH")
    end
    return window
end

function Library:SetWatermark(text)
    local window = self.Windows[#self.Windows]
    if window then
        return window:CreateWatermark(text)
    end
    return nil
end

function Library:Unload()
    self.Unloaded = true
    for _, window in ipairs(self.Windows) do
        for _, connection in ipairs(window.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        if window.Gui then
            window.Gui:Destroy()
        end
    end
    self.Windows = {}
    self.Options = {}
    self.ThemeCallbacks = {}
end

Library.Themes = Themes
return Library
