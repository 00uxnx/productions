local G = getgenv()
local cloneref = cloneref or function(o) return o end

if G.UH then
    pcall(function() G.UH:Unload() end)
end

local UH = {}
G.UH = UH

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

local GetGui = gethui or function() return cloneref(game:GetService("CoreGui")) end
local CoreGui = GetGui()

local InstanceNew = Instance.new
local UDim2New = UDim2.new
local Color3RGB = Color3.fromRGB
local TableInsert = table.insert
local TableRemove = table.remove
local TweenInfoNew = TweenInfo.new

UH.Flags = {}
UH.Connections = {}
UH.Elements = {}
UH.SelectionMode = "Normal"
UH.MenuKeybind = Enum.KeyCode.M
UH.SelectedIndex = 1
UH.CurrentPage = nil
UH.ActiveButtons = {}

local Theme = {
    Background = Color3RGB(0, 0, 0),
    Transparency = 0.35,
    Outline = Color3RGB(180, 180, 180),
    Text = Color3RGB(255, 255, 255),
    Accent = Color3RGB(0, 120, 255),
    Panel = Color3RGB(30, 30, 30),
    Font = Enum.Font.SourceSans,
    TextSize = 14
}

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

local function CreateWindow(title)
    local ScreenGui = Create("ScreenGui", {
        Parent = CoreGui,
        Name = "UnnamedHook",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Theme.Transparency,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Outline,
        Position = UDim2New(0, 50, 0, 50),
        Size = UDim2New(0, 500, 0, 400),
        Visible = true,
        Active = true
    })

    local Header = Create("TextLabel", {
        Parent = Main,
        Name = "Header",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 10, 0, 10),
        Size = UDim2New(0, 200, 0, 30),
        Font = Theme.Font,
        TextSize = 24,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title or "UNNAMED HOOK"
    })

    local LeftPanel = Create("Frame", {
        Parent = Main,
        Name = "LeftPanel",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 10, 0, 50),
        Size = UDim2New(0, 250, 0, 310)
    })

    local LeftLayout = Create("UIListLayout", {
        Parent = LeftPanel,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })

    local RightPanel = Create("Frame", {
        Parent = Main,
        Name = "RightPanel",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 265, 0, 50),
        Size = UDim2New(0, 225, 0, 310)
    })

    local RightLayout = Create("UIListLayout", {
        Parent = RightPanel,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    local Footer = Create("TextLabel", {
        Parent = Main,
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 10, 1, -30),
        Size = UDim2New(1, -20, 0, 20),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Outline,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Select [Enter] | Back [Backspace] | Toggle [M]"
    })

    local dragging, dragInput, dragStart, startPos
    AddConnection(Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))
    AddConnection(Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2New(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    local Window = {
        Gui = ScreenGui,
        Main = Main,
        LeftPanel = LeftPanel,
        RightPanel = RightPanel,
        Pages = {},
        Submenus = {},
        CurrentPage = nil,
        CurrentSubmenu = nil
    }

    function Window:AddCategory(name, hasSubmenu)
        local btn = Create("TextButton", {
            Parent = self.LeftPanel,
            Name = name,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2New(1, 0, 0, 24),
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = hasSubmenu and (name .. " >") or name,
            AutoButtonColor = false
        })

        local page = { Button = btn, Name = name, Elements = {}, Submenus = {}, IsSubmenu = false }
        TableInsert(self.Pages, page)
        UH.CurrentPage = UH.CurrentPage or page

        local function selectThis()
            Window:SelectPage(name)
        end

        AddConnection(btn.MouseButton1Click:Connect(selectThis))
        return page
    end

    function Window:AddSubmenu(parentPage, name)
        local btn = Create("TextButton", {
            Parent = self.LeftPanel,
            Name = name,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2New(1, 0, 0, 24),
            Font = Theme.Font,
            TextSize = Theme.TextSize,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "  " .. name,
            Visible = false,
            AutoButtonColor = false
        })

        local sub = { Button = btn, Name = name, Elements = {}, Parent = parentPage, IsSubmenu = true }
        TableInsert(parentPage.Submenus, sub)
        TableInsert(self.Submenus, sub)
        
        AddConnection(btn.MouseButton1Click:Connect(function()
            Window:SelectSubmenu(parentPage, name)
        end))
        return sub
    end

    function Window:SelectPage(name)
        for _, page in next, self.Pages do
            if page.Name == name then
                self.CurrentPage = page
                page.Button.TextColor3 = Theme.Accent
                for _, sub in next, page.Submenus do
                    sub.Button.Visible = true
                end
                if #page.Submenus > 0 then
                    self:SelectSubmenu(page, page.Submenus[1].Name)
                else
                    self:RefreshUI(page)
                end
            else
                page.Button.TextColor3 = Theme.Text
                for _, sub in next, page.Submenus do
                    sub.Button.Visible = false
                end
            end
        end
        UH.SelectedIndex = 1
        self:UpdateSelection()
    end

    function Window:SelectSubmenu(parentPage, name)
        self.CurrentSubmenu = nil
        for _, sub in next, parentPage.Submenus do
            if sub.Name == name then
                self.CurrentSubmenu = sub
                sub.Button.TextColor3 = Theme.Accent
                self:RefreshUI(sub)
            else
                sub.Button.TextColor3 = Theme.Text
            end
        end
        UH.SelectedIndex = 1
        self:UpdateSelection()
    end

    function Window:RefreshUI(container)
        for _, item in next, self.LeftPanel:GetChildren() do
            if item:IsA("TextButton") and not item:FindFirstAncestor("LeftPanel") then
                item:Destroy()
            end
        end
        for _, item in next, self.RightPanel:GetChildren() do
            if not item:IsA("UIListLayout") then
                item:Destroy()
            end
        end
        UH.ActiveButtons = {}
        for _, element in next, container.Elements do
            TableInsert(UH.ActiveButtons, element)
        end
        self:UpdateSelection()
    end

    function Window:UpdateSelection()
        for i, element in next, UH.ActiveButtons do
            if element.Button then
                if i == UH.SelectedIndex then
                    element.Button.BackgroundTransparency = 0
                    element.Button.BackgroundColor3 = Theme.Accent
                    element.Button.TextColor3 = Theme.Text
                else
                    element.Button.BackgroundTransparency = 1
                    element.Button.TextColor3 = Theme.Text
                end
            end
        end
    end

    function Window:AddInfoPanel(title)
        local panel = Create("Frame", {
            Parent = self.RightPanel,
            BackgroundTransparency = 1,
            Size = UDim2New(1, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.Y
        })
        local header = Create("TextLabel", {
            Parent = panel,
            BackgroundColor3 = Theme.Panel,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 1,
            BorderColor3 = Theme.Outline,
            Size = UDim2New(1, 0, 0, 22),
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
            PaddingTop = UDim.new(0, 24)
        })
        return panel
    end

    function Window:AddInfoItem(panel, label, value)
        local row = Create("Frame", {
            Parent = panel,
            BackgroundTransparency = 1,
            Size = UDim2New(1, 0, 0, 18)
        })
        Create("TextLabel", {
            Parent = row,
            BackgroundTransparency = 1,
            Size = UDim2New(0.5, 0, 1, 0),
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = label
        })
        local valLabel = Create("TextLabel", {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2New(0.5, 0, 0, 0),
            Size = UDim2New(0.5, 0, 1, 0),
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = tostring(value)
        })
        return valLabel
    end

    return Window
end

local function RegisterElement(container, element, flag, default, callback)
    element.Value = default
    element.Callback = callback
    element.Button = Create("TextButton", {
        Parent = container.Button.Parent,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 24),
        Font = Theme.Font,
        TextSize = Theme.TextSize,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = element.Text,
        AutoButtonColor = false
    })
    if flag then
        UH.Flags[flag] = element
    end
    TableInsert(container.Elements, element)
    return element
end

function UH:AddToggle(page, flag, text, default, callback)
    local element = {}
    element.Type = "Toggle"
    element.Text = string.format("[%s] %s", default and "X" or " ", text)
    
    local function toggle()
        element.Value = not element.Value
        element.Button.Text = string.format("[%s] %s", element.Value and "X" or " ", text)
        if element.Callback then
            task.spawn(element.Callback, element.Value)
        end
    end

    RegisterElement(page, element, flag, default, callback)
    AddConnection(element.Button.MouseButton1Click:Connect(toggle))
    element.Activate = toggle
    return element
end

function UH:AddSlider(page, flag, text, min, max, default, callback)
    local element = {}
    element.Type = "Slider"
    element.Min = min
    element.Max = max
    element.Text = string.format("%s: %s", text, tostring(default))

    local function update(val)
        element.Value = math.clamp(val, element.Min, element.Max)
        element.Button.Text = string.format("%s: %s", text, tostring(element.Value))
        if element.Callback then
            task.spawn(element.Callback, element.Value)
        end
    end

    RegisterElement(page, element, flag, default, callback)
    element.Activate = function()
        update(element.Value + 1)
    end
    element.Left = function()
        update(element.Value - 1)
    end
    element.Right = function()
        update(element.Value + 1)
    end
    return element
end

function UH:AddButton(page, text, callback)
    local element = {}
    element.Type = "Button"
    element.Text = text
    RegisterElement(page, element, nil, nil, callback)
    element.Activate = function()
        if element.Callback then
            task.spawn(element.Callback)
        end
    end
    AddConnection(element.Button.MouseButton1Click:Connect(element.Activate))
    return element
end

function UH:AddDropdown(page, flag, text, options, default, callback)
    local element = {}
    element.Type = "Dropdown"
    element.Options = options
    element.Text = string.format("%s: %s", text, tostring(default))
    
    local function selectOption(opt)
        element.Value = opt
        element.Button.Text = string.format("%s: %s", text, tostring(opt))
        if element.Callback then
            task.spawn(element.Callback, opt)
        end
    end

    RegisterElement(page, element, flag, default, callback)
    element.Activate = function()
        local nextIndex = 1
        for i, v in next, element.Options do
            if v == element.Value then
                nextIndex = i + 1
                break
            end
        end
        if nextIndex > #element.Options then nextIndex = 1 end
        selectOption(element.Options[nextIndex])
    end
    element.Left = element.Activate
    element.Right = element.Activate
    return element
end

local Window = CreateWindow("UNNAMED HOOK")
UH.Window = Window

AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == UH.MenuKeybind then
        Window.Main.Visible = not Window.Main.Visible
    end
    if not Window.Main.Visible then return end
    if UH.SelectionMode ~= "Normal" then return end

    if input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
        UH.SelectedIndex = UH.SelectedIndex + 1
        if UH.SelectedIndex > #UH.ActiveButtons then UH.SelectedIndex = 1 end
        Window:UpdateSelection()
    elseif input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
        UH.SelectedIndex = UH.SelectedIndex - 1
        if UH.SelectedIndex < 1 then UH.SelectedIndex = #UH.ActiveButtons end
        Window:UpdateSelection()
    elseif input.KeyCode == Enum.KeyCode.Return then
        local element = UH.ActiveButtons[UH.SelectedIndex]
        if element and element.Activate then element.Activate() end
    elseif input.KeyCode == Enum.KeyCode.Left then
        local element = UH.ActiveButtons[UH.SelectedIndex]
        if element and element.Left then element.Left() end
    elseif input.KeyCode == Enum.KeyCode.Right then
        local element = UH.ActiveButtons[UH.SelectedIndex]
        if element and element.Right then element.Right() end
    end
end))

function UH:Unload()
    for _, conn in next, self.Connections do
        pcall(function() conn:Disconnect() end)
    end
    if self.Window and self.Window.Gui then
        self.Window.Gui:Destroy()
    end
    G.UH = nil
end

return UH
