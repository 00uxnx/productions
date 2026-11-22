local G = getgenv()
local cloneref = cloneref or function(o) return o end
if G.UH then pcall(function() G.UH:Unload() end) end

local UH = {}
G.UH = UH

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local SoundService = cloneref(game:GetService("SoundService"))
local LocalPlayer = Players.LocalPlayer

local InstanceNew = Instance.new
local UDim2New = UDim2.new
local Color3RGB = Color3.fromRGB
local TableInsert = table.insert
local MathClamp = math.clamp
local MathFloor = math.floor
local ToString = tostring

local GetGui = gethui or function() return cloneref(game:GetService("CoreGui")) end
local CoreGui = GetGui()

UH.Flags = {}
UH.Connections = {}
UH.SelectionMode = "Normal"
UH.MenuKeybind = Enum.KeyCode.M
UH.SelectedIndex = 1
UH.ActiveElements = {}
UH.IsOpen = true
UH.WaitingForKey = nil
UH.Controls = nil

local Theme = {
    Background = Color3RGB(15, 15, 15),
    Transparency = 0.3,
    Outline = Color3RGB(200, 200, 200),
    Text = Color3RGB(255, 255, 255),
    TextDim = Color3RGB(150, 150, 150),
    Accent = Color3RGB(0, 120, 255),
    Panel = Color3RGB(25, 25, 25),
    Font = Enum.Font.Code,
    TextSize = 14
}

local SelectSound = InstanceNew("Sound")
SelectSound.SoundId = "rbxassetid://6895079853"
SelectSound.Volume = 0.4
SelectSound.Parent = SoundService

local function PlaySound()
    if SelectSound then
        SelectSound:Play()
    end
end

local function Create(class, props)
    local obj = InstanceNew(class)
    for k, v in next, props do
        obj[k] = v
    end
    return obj
end

local function AddConnection(conn)
    TableInsert(UH.Connections, conn)
    return conn
end

local function ToggleControls(enable)
    if not UH.Controls then
        pcall(function()
            UH.Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
        end)
    end
    if UH.Controls then
        if enable then
            UH.Controls:Enable()
        else
            UH.Controls:Disable()
        end
    end
end

local ScreenGui = Create("ScreenGui", {
    Parent = CoreGui,
    Name = "UnnamedHook",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local Watermark = Create("Frame", {
    Parent = ScreenGui,
    Name = "Watermark",
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = Theme.Transparency,
    BorderSizePixel = 1,
    BorderColor3 = Theme.Outline,
    Position = UDim2New(0, 20, 0, 20),
    Size = UDim2New(0, 200, 0, 24)
})

local WatermarkText = Create("TextLabel", {
    Parent = Watermark,
    BackgroundTransparency = 1,
    Size = UDim2New(1, 0, 1, 0),
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.Text,
    Text = "UH | FPS: 60 | Ping: 0ms"
})

local Main = Create("Frame", {
    Parent = ScreenGui,
    Name = "Main",
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = Theme.Transparency,
    BorderSizePixel = 1,
    BorderColor3 = Theme.Outline,
    Position = UDim2New(0, 50, 0, 100),
    Size = UDim2New(0, 550, 0, 400),
    Visible = true,
    Active = true
})

local Header = Create("Frame", {
    Parent = Main,
    Name = "Header",
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel = 1,
    BorderColor3 = Theme.Outline,
    Size = UDim2New(1, 0, 0, 24)
})

local HeaderText = Create("TextLabel", {
    Parent = Header,
    BackgroundTransparency = 1,
    Position = UDim2New(0, 5, 0, 0),
    Size = UDim2New(1, -10, 1, 0),
    Font = Theme.Font,
    TextSize = 16,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "UNNAMED HOOK"
})

local LeftPanel = Create("Frame", {
    Parent = Main,
    Name = "LeftPanel",
    BackgroundTransparency = 1,
    Position = UDim2New(0, 5, 0, 30),
    Size = UDim2New(0, 260, 0, 340)
})

local LeftLayout = Create("UIListLayout", {
    Parent = LeftPanel,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2)
})

local RightPanel = Create("Frame", {
    Parent = Main,
    Name = "RightPanel",
    BackgroundColor3 = Theme.Panel,
    BackgroundTransparency = Theme.Transparency,
    BorderSizePixel = 1,
    BorderColor3 = Theme.Outline,
    Position = UDim2New(0, 270, 0, 30),
    Size = UDim2New(0, 275, 0, 340)
})

local RightLayout = Create("UIListLayout", {
    Parent = RightPanel,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2)
})

local Footer = Create("TextLabel", {
    Parent = Main,
    Name = "Footer",
    BackgroundTransparency = 1,
    Position = UDim2New(0, 5, 1, -25),
    Size = UDim2New(1, -10, 0, 20),
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.TextDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Select: [Enter] | Back: [Backspace] | Toggle: [M]"
})

local dragging, dragInput, dragStart, startPos
AddConnection(Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end))
AddConnection(Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))
AddConnection(UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2New(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

local Pages = {}
local CurrentPage = nil
local CurrentSubmenu = nil

local function ClearUI()
    for _, v in next, LeftPanel:GetChildren() do
        if v:IsA("TextButton") then v:Destroy() end
    end
    UH.ActiveElements = {}
    UH.SelectedIndex = 1
end

local function UpdateSelection()
    for i, el in next, UH.ActiveElements do
        if el.Frame then
            if i == UH.SelectedIndex then
                el.Frame.BackgroundTransparency = 0
                el.Frame.BackgroundColor3 = Theme.Accent
            else
                el.Frame.BackgroundTransparency = 1
                el.Frame.BackgroundColor3 = Theme.Background
            end
        end
    end
end

local function CreateElement(text, activate, left, right)
    local btn = Create("TextButton", {
        Parent = LeftPanel,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 24),
        Font = Theme.Font,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        AutoButtonColor = false
    })
    local el = { Frame = btn, Activate = activate, Left = left, Right = right }
    TableInsert(UH.ActiveElements, el)
    AddConnection(btn.MouseButton1Click:Connect(function()
        for i, v in next, UH.ActiveElements do
            if v == el then
                UH.SelectedIndex = i
                UpdateSelection()
                PlaySound()
                if el.Activate then el.Activate() end
            end
        end
    end))
    return el
end

local function GetElementText(item)
    if item.Type == "Toggle" then
        return string.format("[%s] %s", item.Value and "X" or " ", item.Label)
    elseif item.Type == "Slider" then
        return string.format("%s: < %s >", item.Label, ToString(item.Value))
    elseif item.Type == "Dropdown" then
        return string.format("%s: < %s >", item.Label, ToString(item.Value))
    elseif item.Type == "Keypicker" then
        return string.format("%s: [ %s ]", item.Label, item.Value and item.Value.Name or "None")
    elseif item.Type == "Colorpicker" then
        local c = item.Value
        return string.format("%s: [ %d, %d, %d ]", item.Label, c.R * 255, c.G * 255, c.B * 255)
    end
    return item.Label or "Unknown"
end

local function BuildPage(pageData)
    ClearUI()
    CurrentSubmenu = nil
    HeaderText.Text = "UNNAMED HOOK // " .. string.upper(pageData.Name)
    for _, sub in next, pageData.Submenus do
        CreateElement(sub.Name .. " >", function()
            CurrentSubmenu = sub
            ClearUI()
            local backEl = CreateElement("< Back", function() BuildPage(pageData) end)
            for _, item in next, sub.Elements do
                local el = CreateElement(GetElementText(item), function()
                    if item.Type == "Toggle" then
                        item.Value = not item.Value
                        el.Frame.Text = GetElementText(item)
                        if item.Callback then task.spawn(item.Callback, item.Value) end
                    elseif item.Type == "Button" then
                        if item.Callback then task.spawn(item.Callback) end
                    elseif item.Type == "Keypicker" then
                        UH.WaitingForKey = item
                        el.Frame.Text = string.format("%s: [ Press Key ]", item.Label)
                    elseif item.Type == "Colorpicker" then
                        item.Value = Color3.fromHSV(math.random(), 1, 1)
                        el.Frame.Text = GetElementText(item)
                        if item.Callback then task.spawn(item.Callback, item.Value) end
                    end
                end, function()
                    if item.Type == "Slider" then
                        item.Value = MathClamp(item.Value - item.Step, item.Min, item.Max)
                        el.Frame.Text = GetElementText(item)
                        if item.Callback then task.spawn(item.Callback, item.Value) end
                    elseif item.Type == "Dropdown" then
                        local idx = table.find(item.Options, item.Value) or 1
                        idx = idx > 1 and idx - 1 or #item.Options
                        item.Value = item.Options[idx]
                        el.Frame.Text = GetElementText(item)
                        if item.Callback then task.spawn(item.Callback, item.Value) end
                    end
                end, function()
                    if item.Type == "Slider" then
                        item.Value = MathClamp(item.Value + item.Step, item.Min, item.Max)
                        el.Frame.Text = GetElementText(item)
                        if item.Callback then task.spawn(item.Callback, item.Value) end
                    elseif item.Type == "Dropdown" then
                        local idx = table.find(item.Options, item.Value) or 0
                        idx = idx < #item.Options and idx + 1 or 1
                        item.Value = item.Options[idx]
                        el.Frame.Text = GetElementText(item)
                        if item.Callback then task.spawn(item.Callback, item.Value) end
                    end
                end)
                item.Frame = el.Frame
            end
            UpdateSelection()
        end)
    end
    for _, item in next, pageData.Elements do
        local el = CreateElement(GetElementText(item), function()
            if item.Type == "Toggle" then
                item.Value = not item.Value
                el.Frame.Text = GetElementText(item)
                if item.Callback then task.spawn(item.Callback, item.Value) end
            elseif item.Type == "Button" then
                if item.Callback then task.spawn(item.Callback) end
            elseif item.Type == "Keypicker" then
                UH.WaitingForKey = item
                el.Frame.Text = string.format("%s: [ Press Key ]", item.Label)
            elseif item.Type == "Colorpicker" then
                item.Value = Color3.fromHSV(math.random(), 1, 1)
                el.Frame.Text = GetElementText(item)
                if item.Callback then task.spawn(item.Callback, item.Value) end
            end
        end, function()
            if item.Type == "Slider" then
                item.Value = MathClamp(item.Value - item.Step, item.Min, item.Max)
                el.Frame.Text = GetElementText(item)
                if item.Callback then task.spawn(item.Callback, item.Value) end
            elseif item.Type == "Dropdown" then
                local idx = table.find(item.Options, item.Value) or 1
                idx = idx > 1 and idx - 1 or #item.Options
                item.Value = item.Options[idx]
                el.Frame.Text = GetElementText(item)
                if item.Callback then task.spawn(item.Callback, item.Value) end
            end
        end, function()
            if item.Type == "Slider" then
                item.Value = MathClamp(item.Value + item.Step, item.Min, item.Max)
                el.Frame.Text = GetElementText(item)
                if item.Callback then task.spawn(item.Callback, item.Value) end
            elseif item.Type == "Dropdown" then
                local idx = table.find(item.Options, item.Value) or 0
                idx = idx < #item.Options and idx + 1 or 1
                item.Value = item.Options[idx]
                el.Frame.Text = GetElementText(item)
                if item.Callback then task.spawn(item.Callback, item.Value) end
            end
        end)
        item.Frame = el.Frame
    end
    UpdateSelection()
end

function UH:CreateWindow(title)
    HeaderText.Text = title or "UNNAMED HOOK"
    return self
end

function UH:AddCategory(name)
    if not Pages[name] then
        Pages[name] = { Name = name, Elements = {}, Submenus = {} }
    end
    return Pages[name]
end

function UH:AddSubmenu(category, name)
    if not category.Submenus[name] then
        category.Submenus[name] = { Name = name, Elements = {} }
    end
    return category.Submenus[name]
end

function UH:AddToggle(container, flag, label, default, callback)
    local item = { Type = "Toggle", Label = label, Value = default, Callback = callback }
    TableInsert(container.Elements, item)
    if flag then UH.Flags[flag] = item end
    return item
end

function UH:AddSlider(container, flag, label, min, max, default, callback, step)
    local item = { Type = "Slider", Label = label, Min = min, Max = max, Value = default, Callback = callback, Step = step or 1 }
    TableInsert(container.Elements, item)
    if flag then UH.Flags[flag] = item end
    return item
end

function UH:AddDropdown(container, flag, label, options, default, callback)
    local item = { Type = "Dropdown", Label = label, Options = options, Value = default, Callback = callback }
    TableInsert(container.Elements, item)
    if flag then UH.Flags[flag] = item end
    return item
end

function UH:AddKeypicker(container, flag, label, default, callback)
    local item = { Type = "Keypicker", Label = label, Value = default, Callback = callback }
    TableInsert(container.Elements, item)
    if flag then UH.Flags[flag] = item end
    return item
end

function UH:AddColorpicker(container, flag, label, default, callback)
    local item = { Type = "Colorpicker", Label = label, Value = default, Callback = callback }
    TableInsert(container.Elements, item)
    if flag then UH.Flags[flag] = item end
    return item
end

function UH:AddButton(container, label, callback)
    local item = { Type = "Button", Label = label, Callback = callback }
    TableInsert(container.Elements, item)
    return item
end

function UH:AddInfoPanel(title)
    local panel = Create("Frame", {
        Parent = RightPanel,
        BackgroundTransparency = 1,
        Size = UDim2New(1, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    Create("TextLabel", {
        Parent = panel,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Outline,
        Size = UDim2New(1, 0, 0, 20),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local layout = Create("UIListLayout", {
        Parent = panel,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    Create("UIPadding", {
        Parent = panel,
        PaddingTop = UDim.new(0, 22)
    })
    return panel
end

function UH:AddInfoItem(panel, label, value)
    local row = Create("Frame", {
        Parent = panel,
        BackgroundTransparency = 1,
        Size = UDim2New(1, 0, 0, 16)
    })
    Create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Size = UDim2New(0.6, 0, 1, 0),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label
    })
    local valLabel = Create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2New(0.6, 0, 0, 0),
        Size = UDim2New(0.4, 0, 1, 0),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(value)
    })
    return valLabel
end

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == UH.MenuKeybind then
        UH.IsOpen = not UH.IsOpen
        Main.Visible = UH.IsOpen
        Watermark.Visible = UH.IsOpen
        if UH.SelectionMode == "Normal" then
            ToggleControls(not UH.IsOpen)
        end
        return
    end
    
    if UH.WaitingForKey then
        UH.WaitingForKey.Value = input.KeyCode
        UH.WaitingForKey.Frame.Text = GetElementText(UH.WaitingForKey)
        if UH.WaitingForKey.Callback then
            task.spawn(UH.WaitingForKey.Callback, input.KeyCode)
        end
        UH.WaitingForKey = nil
        return
    end
    
    if not UH.IsOpen or UH.SelectionMode ~= "Normal" then return end
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
        UH.SelectedIndex = UH.SelectedIndex + 1
        if UH.SelectedIndex > #UH.ActiveElements then UH.SelectedIndex = 1 end
        UpdateSelection()
        PlaySound()
    elseif input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
        UH.SelectedIndex = UH.SelectedIndex - 1
        if UH.SelectedIndex < 1 then UH.SelectedIndex = #UH.ActiveElements end
        UpdateSelection()
        PlaySound()
    elseif input.KeyCode == Enum.KeyCode.Return then
        local el = UH.ActiveElements[UH.SelectedIndex]
        if el and el.Activate then el.Activate() end
    elseif input.KeyCode == Enum.KeyCode.Left then
        local el = UH.ActiveElements[UH.SelectedIndex]
        if el and el.Left then el.Left() end
    elseif input.KeyCode == Enum.KeyCode.Right then
        local el = UH.ActiveElements[UH.SelectedIndex]
        if el and el.Right then el.Right() end
    elseif input.KeyCode == Enum.KeyCode.Backspace then
        if CurrentSubmenu then
            BuildPage(Pages[CurrentPage])
        end
    end
end))

local fps = 0
local frames = 0
local lastTime = tick()
AddConnection(RunService.RenderStepped:Connect(function()
    frames = frames + 1
    if tick() - lastTime >= 1 then
        fps = frames
        frames = 0
        lastTime = tick()
    end
    local ping = MathFloor(LocalPlayer:GetNetworkPing() * 1000)
    WatermarkText.Text = string.format("UH | FPS: %d | Ping: %dms", fps, ping)
end))

function UH:SetSelectionMode(mode)
    self.SelectionMode = mode
    if mode == "Normal" and self.IsOpen then
        ToggleControls(false)
    else
        ToggleControls(true)
    end
end

function UH:Unload()
    ToggleControls(true)
    for _, conn in next, self.Connections do
        pcall(function() conn:Disconnect() end)
    end
    if SelectSound then SelectSound:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    G.UH = nil
end

local DefaultPage = UH:AddCategory("Main Menu")
BuildPage(DefaultPage)
CurrentPage = "Main Menu"

return UH
