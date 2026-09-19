--===============================================================================
--  SC999 FRAMEWORK CORE v2.0
--  Tab-Based iOS 27 Glassmorphism GUI · Modular Roblox Script Framework
--  Author: Biasaemail
--  GitHub: https://github.com/Biasaemail/SC999-Framework
--===============================================================================

-- PREVENT DOUBLE EXECUTION
if getgenv().SC999_FrameworkLoaded then
    warn("[SC999] Framework already loaded!")
    return getgenv().SC999_Framework
end

--===============================================================================
--  SERVICES
--===============================================================================

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService"),
    VirtualUser = game:GetService("VirtualUser"),
}

local player = Services.Players.LocalPlayer
repeat task.wait() until player

--===============================================================================
--  UTILITY FUNCTIONS
--===============================================================================

local Util = {}

function Util.Notify(title, msg, duration)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(msg),
            Duration = duration or 3
        })
    end)
end

function Util.DebugLog(moduleName, ...)
    local config = getgenv().SC999_Config or {}
    if config.DebugMode then
        print("[SC999] [" .. tostring(moduleName) .. "]", ...)
    end
end

function Util.GetHumanoid()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function Util.GetCharacter()
    return player.Character
end

function Util.WaitForCharacter(timeout)
    timeout = timeout or 10
    local start = tick()
    while not player.Character and tick() - start < timeout do
        task.wait()
    end
    return player.Character
end

function Util.Tween(instance, properties, duration, easingStyle, easingDir)
    duration = duration or 0.3
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDir = easingDir or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration, easingStyle, easingDir)
    local tween = Services.TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

function Util.Create(instanceType, props)
    local obj = Instance.new(instanceType)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

--===============================================================================
--  CONFIG MANAGER (writefile/readfile)
--===============================================================================

local ConfigManager = {}
ConfigManager.FileName = "SC999_Config.json"
ConfigManager.DefaultConfig = {
    DebugMode = false,
    Theme = "glassmorphism",
    GUIPosition = {0.5, -150, 0.5, -210},
    Modules = {},
}

function ConfigManager.Load()
    local success, content = pcall(function()
        return readfile(ConfigManager.FileName)
    end)
    if success and content then
        local ok, config = pcall(function()
            return Services.HttpService:JSONDecode(content)
        end)
        if ok and config then
            for k, v in pairs(ConfigManager.DefaultConfig) do
                if config[k] == nil then
                    config[k] = v
                end
            end
            getgenv().SC999_Config = config
            Util.DebugLog("Config", "Loaded from file")
            return config
        end
    end
    getgenv().SC999_Config = ConfigManager.DefaultConfig
    ConfigManager.Save(ConfigManager.DefaultConfig)
    return ConfigManager.DefaultConfig
end

function ConfigManager.Save(config)
    config = config or getgenv().SC999_Config
    local success, err = pcall(function()
        writefile(ConfigManager.FileName, Services.HttpService:JSONEncode(config))
    end)
    if success then
        Util.DebugLog("Config", "Saved to file")
    else
        warn("[SC999] Failed to save config:", err)
    end
end

function ConfigManager.GetModuleConfig(moduleName)
    local config = getgenv().SC999_Config or ConfigManager.Load()
    if not config.Modules then
        config.Modules = {}
    end
    if not config.Modules[moduleName] then
        config.Modules[moduleName] = {}
    end
    return config.Modules[moduleName]
end

function ConfigManager.SetModuleConfig(moduleName, moduleConfig)
    local config = getgenv().SC999_Config or ConfigManager.Load()
    if not config.Modules then config.Modules = {} end
    config.Modules[moduleName] = moduleConfig
    ConfigManager.Save(config)
end

--===============================================================================
--  MODULE BASE CLASS
--===============================================================================

local ModuleBase = {}
ModuleBase.__index = ModuleBase

function ModuleBase.new(name, metadata)
    local self = setmetatable({}, ModuleBase)
    self.Name = name
    self.Metadata = metadata or {}
    self.Enabled = false
    self.Connections = {}
    self.Objects = {}
    self.Config = ConfigManager.GetModuleConfig(name)
    self.IsDestroyed = false
    return self
end

function ModuleBase:Enable()
    if self.Enabled or self.IsDestroyed then return end
    self.Enabled = true
    if self.OnEnable then self:OnEnable() end
    Util.DebugLog(self.Name, "Enabled")
end

function ModuleBase:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    for name, conn in pairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
        self.Connections[name] = nil
    end
    if self.OnDisable then self:OnDisable() end
    Util.DebugLog(self.Name, "Disabled")
end

function ModuleBase:Destroy()
    self:Disable()
    self.IsDestroyed = true
    for _, obj in ipairs(self.Objects) do
        pcall(function() obj:Destroy() end)
    end
    self.Objects = {}
    if self.OnDestroy then self:OnDestroy() end
    Util.DebugLog(self.Name, "Destroyed")
end

function ModuleBase:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.Enabled
end

function ModuleBase:SetConfig(key, value)
    self.Config[key] = value
    ConfigManager.SetModuleConfig(self.Name, self.Config)
end

function ModuleBase:GetConfig(key, default)
    if self.Config[key] == nil then
        self.Config[key] = default
    end
    return self.Config[key]
end

function ModuleBase:AddConnection(name, connection)
    if self.Connections[name] then
        pcall(function() self.Connections[name]:Disconnect() end)
    end
    self.Connections[name] = connection
end

function ModuleBase:AddObject(obj)
    table.insert(self.Objects, obj)
end

--===============================================================================
--  MODULE REGISTRY
--===============================================================================

local ModuleRegistry = {}
ModuleRegistry.Modules = {}

function ModuleRegistry.Register(module)
    ModuleRegistry.Modules[module.Name] = module
    Util.DebugLog("Registry", "Registered module:", module.Name)
end

function ModuleRegistry.Get(name)
    return ModuleRegistry.Modules[name]
end

function ModuleRegistry.GetAll()
    return ModuleRegistry.Modules
end

function ModuleRegistry.EnableAll()
    for _, module in pairs(ModuleRegistry.Modules) do
        if module.Metadata and module.Metadata.AutoEnable then
            module:Enable()
        end
    end
end

--===============================================================================
--  iOS 27 GLASSMORPHISM GUI v2.0  ·  TAB-BASED NAVIGATION
--===============================================================================

local GlassGUI = {}

-- State
GlassGUI.ScreenGui = nil
GlassGUI.MainContainer = nil
GlassGUI.MainFrame = nil
GlassGUI.StatusLabel = nil
GlassGUI.TabPages = {}
GlassGUI.TabButtons = {}
GlassGUI.TabOrder = {}
GlassGUI.TabIndicator = nil
GlassGUI.TabContainer = nil
GlassGUI.ContentArea = nil
GlassGUI.ActiveTabName = nil
GlassGUI.ToggleButtons = {}
GlassGUI.IsMinimized = false
GlassGUI.IsDestroyed = false
GlassGUI.CreatedSections = {}

-- Theme: iOS 27 Dark Glassmorphism
GlassGUI.Theme = {
    Background        = Color3.fromRGB(18, 18, 20),
    GlassTransparency = 0.20,
    StrokeColor       = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.90,
    AccentGreen       = Color3.fromRGB(52, 199, 89),
    AccentBlue        = Color3.fromRGB(10, 132, 255),
    AccentPurple      = Color3.fromRGB(175, 82, 222),
    AccentOrange      = Color3.fromRGB(255, 149, 0),
    AccentRed         = Color3.fromRGB(255, 59, 48),
    TextPrimary       = Color3.fromRGB(255, 255, 255),
    TextSecondary     = Color3.fromRGB(174, 174, 178),
    ToggleOff         = Color3.fromRGB(56, 56, 58),
    ToggleOn          = Color3.fromRGB(52, 199, 89),
    InputBg           = Color3.fromRGB(36, 36, 38),
    CardBg            = Color3.fromRGB(28, 28, 30),
    TabActive         = Color3.fromRGB(10, 132, 255),
    TabInactive       = Color3.fromRGB(142, 142, 147),
    TabBarBg          = Color3.fromRGB(22, 22, 24),
    DividerColor      = Color3.fromRGB(58, 58, 60),
}

--==========================================================================
--  GlassGUI.CreateTab(name, layoutOrder)
--  Creates a tab button + its scrollable page. Returns the page frame.
--==========================================================================

function GlassGUI.CreateTab(name, layoutOrder)
    if not GlassGUI.TabContainer or not GlassGUI.ContentArea then return nil end

    -- Tab Button
    local tabBtn = Util.Create("TextButton", {
        Name = name .. "_Tab",
        Size = UDim2.new(0, 86, 0, 30),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = GlassGUI.Theme.TabInactive,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = false,
        LayoutOrder = layoutOrder or 0,
        Parent = GlassGUI.TabContainer,
    })

    -- Hover
    tabBtn.MouseEnter:Connect(function()
        if GlassGUI.ActiveTabName ~= name then
            Util.Tween(tabBtn, {TextColor3 = GlassGUI.Theme.TextPrimary}, 0.15)
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if GlassGUI.ActiveTabName ~= name then
            Util.Tween(tabBtn, {TextColor3 = GlassGUI.Theme.TabInactive}, 0.15)
        end
    end)

    -- Tab Page (ScrollingFrame)
    local page = Util.Create("ScrollingFrame", {
        Name = name .. "_Page",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = GlassGUI.Theme.AccentBlue,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = GlassGUI.ContentArea,
    })

    Util.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = page,
    })

    Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = page,
    })

    -- Click handler
    tabBtn.MouseButton1Click:Connect(function()
        GlassGUI.SwitchTab(name)
    end)

    GlassGUI.TabButtons[name] = tabBtn
    GlassGUI.TabPages[name] = page
    table.insert(GlassGUI.TabOrder, name)

    return page
end

--==========================================================================
--  GlassGUI.SwitchTab(name)
--  Smoothly switches the active tab with indicator animation.
--==========================================================================

function GlassGUI.SwitchTab(name)
    if GlassGUI.IsDestroyed then return end
    if GlassGUI.ActiveTabName == name then return end

    GlassGUI.ActiveTabName = name

    -- Update button text colors
    for tabName, btn in pairs(GlassGUI.TabButtons) do
        local isActive = (tabName == name)
        Util.Tween(btn, {
            TextColor3 = isActive and GlassGUI.Theme.TabActive or GlassGUI.Theme.TabInactive,
        }, 0.2)
    end

    -- Slide indicator to target button position
    local targetBtn = GlassGUI.TabButtons[name]
    if GlassGUI.TabIndicator and targetBtn then
        task.defer(function()
            local barX = GlassGUI.TabContainer.AbsolutePosition.X
            local btnX = targetBtn.AbsolutePosition.X
            local btnW = targetBtn.AbsoluteSize.X
            local relX = btnX - barX
            Util.Tween(GlassGUI.TabIndicator, {
                Position = UDim2.new(0, relX + 10, 1, -3),
                Size = UDim2.new(0, btnW - 20, 0, 3),
            }, 0.3, Enum.EasingStyle.Quart)
        end)
    end

    -- Switch pages
    for tabName, page in pairs(GlassGUI.TabPages) do
        if tabName == name then
            page.Visible = true
            page.CanvasPosition = Vector2.new(0, 0)
        else
            page.Visible = false
        end
    end
end

--==========================================================================
--  GlassGUI.Create()
--  Builds the entire GUI shell: glass frame, header, tabs, content area.
--==========================================================================

function GlassGUI.Create()
    if GlassGUI.IsDestroyed then return end

    -- Cleanup old GUI
    local oldGui = Services.CoreGui:FindFirstChild("SC999_Framework")
    if oldGui then oldGui:Destroy() end

    -- ScreenGui
    local ScreenGui = Util.Create("ScreenGui", {
        Name = "SC999_Framework",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = (gethui and gethui()) or Services.CoreGui,
    })

    -- Main Container (drag anchor, centered via AnchorPoint)
    local MainContainer = Util.Create("Frame", {
        Name = "MainContainer",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 300, 0, 420),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Active = true,
        Parent = ScreenGui,
    })

    -- Main Frame (Glass surface)
    local MainFrame = Util.Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = GlassGUI.Theme.Background,
        BackgroundTransparency = GlassGUI.Theme.GlassTransparency,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true,
        Parent = MainContainer,
    })

    -- Corner
    Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 22),
        Parent = MainFrame,
    })

    -- Glass Stroke
    Util.Create("UIStroke", {
        Color = GlassGUI.Theme.StrokeColor,
        Transparency = GlassGUI.Theme.StrokeTransparency,
        Thickness = 1,
        Parent = MainFrame,
    })

    -- Glass Gradient Overlay
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 240, 245)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 230)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.94),
            NumberSequenceKeypoint.new(0.5, 0.96),
            NumberSequenceKeypoint.new(1, 0.94),
        }),
        Rotation = 135,
        Parent = MainFrame,
    })

    --============================
    --  TOP BAR (Header)
    --============================

    local TopBar = Util.Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = MainFrame,
    })

    Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 0, 22),
        Position = UDim2.new(0, 18, 0, 8),
        BackgroundTransparency = 1,
        Text = "SC999 Hub",
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    Util.Create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -100, 0, 14),
        Position = UDim2.new(0, 18, 0, 28),
        BackgroundTransparency = 1,
        Text = "v2.0 · Glass Edition",
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextTransparency = 0.3,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    -- Minimize Button
    local MinBtn = Util.Create("TextButton", {
        Name = "MinBtn",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -68, 0, 9),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BackgroundTransparency = 0.3,
        Text = "—",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = TopBar,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = MinBtn})

    -- Close Button
    local CloseBtn = Util.Create("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -34, 0, 9),
        BackgroundColor3 = GlassGUI.Theme.AccentRed,
        BackgroundTransparency = 0.3,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = TopBar,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = CloseBtn})

    --============================
    --  HEADER DIVIDER
    --============================

    Util.Create("Frame", {
        Name = "HeaderDivider",
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 0, 48),
        BackgroundColor3 = GlassGUI.Theme.DividerColor,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    --============================
    --  TAB BAR
    --============================

    local TabBar = Util.Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, 49),
        BackgroundColor3 = GlassGUI.Theme.TabBarBg,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainFrame,
    })

    -- Tab button container
    local TabBtnContainer = Util.Create("Frame", {
        Name = "TabBtnContainer",
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Parent = TabBar,
    })

    Util.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = TabBtnContainer,
    })

    -- Tab Indicator (animated underline)
    local TabIndicator = Util.Create("Frame", {
        Name = "TabIndicator",
        Size = UDim2.new(0, 66, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BorderSizePixel = 0,
        Parent = TabBar,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = TabIndicator})

    --============================
    --  TAB DIVIDER
    --============================

    Util.Create("Frame", {
        Name = "TabDivider",
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 0, 87),
        BackgroundColor3 = GlassGUI.Theme.DividerColor,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    --============================
    --  CONTENT AREA
    --============================

    local ContentArea = Util.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -12, 0, 296),
        Position = UDim2.new(0, 6, 0, 90),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = MainFrame,
    })

    --============================
    --  STATUS BAR
    --============================

    local StatusBar = Util.Create("Frame", {
        Name = "StatusBar",
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 1, -34),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    local StatusLabel = Util.Create("TextLabel", {
        Name = "StatusText",
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Ready · 0 modules",
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = StatusBar,
    })

    --============================
    --  SAVE REFERENCES
    --============================

    GlassGUI.ScreenGui = ScreenGui
    GlassGUI.MainContainer = MainContainer
    GlassGUI.MainFrame = MainFrame
    GlassGUI.StatusLabel = StatusLabel
    GlassGUI.TabContainer = TabBtnContainer
    GlassGUI.TabIndicator = TabIndicator
    GlassGUI.ContentArea = ContentArea

    --============================
    --  DRAGGING
    --============================

    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainContainer.Position
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    Services.UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Util.Tween(MainContainer, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }, 0.06, Enum.EasingStyle.Sine)
        end
    end)

    Services.UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    --============================
    --  BUTTON INTERACTIONS
    --============================

    MinBtn.MouseButton1Click:Connect(function()
        GlassGUI.ToggleMinimize()
    end)
    MinBtn.MouseEnter:Connect(function()
        Util.Tween(MinBtn, {BackgroundTransparency = 0.1}, 0.12)
    end)
    MinBtn.MouseLeave:Connect(function()
        Util.Tween(MinBtn, {BackgroundTransparency = 0.3}, 0.12)
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        GlassGUI.Close()
    end)
    CloseBtn.MouseEnter:Connect(function()
        Util.Tween(CloseBtn, {BackgroundTransparency = 0.1}, 0.12)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Util.Tween(CloseBtn, {BackgroundTransparency = 0.3}, 0.12)
    end)

    --============================
    --  CREATE TABS
    --============================

    GlassGUI.CreateTab("Home", 1)
    GlassGUI.CreateTab("Player", 2)
    GlassGUI.CreateTab("Apps", 3)

    --============================
    --  ENTRANCE ANIMATION
    --============================

    MainContainer.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1

    Util.Tween(MainContainer, {
        Size = UDim2.new(0, 300, 0, 420),
    }, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    Util.Tween(MainFrame, {
        BackgroundTransparency = GlassGUI.Theme.GlassTransparency,
    }, 0.7)

    -- Switch to Home tab after layout calculates
    task.delay(0.15, function()
        GlassGUI.SwitchTab("Home")
    end)

    return GlassGUI
end

--==========================================================================
--  GlassGUI.ToggleMinimize()
--==========================================================================

function GlassGUI.ToggleMinimize()
    if GlassGUI.IsDestroyed then return end
    GlassGUI.IsMinimized = not GlassGUI.IsMinimized

    if GlassGUI.IsMinimized then
        Util.Tween(GlassGUI.MainContainer, {
            Size = UDim2.new(0, 300, 0, 48),
        }, 0.35, Enum.EasingStyle.Quart)
    else
        Util.Tween(GlassGUI.MainContainer, {
            Size = UDim2.new(0, 300, 0, 420),
        }, 0.35, Enum.EasingStyle.Quart)
    end
end

--==========================================================================
--  GlassGUI.Close()
--==========================================================================

function GlassGUI.Close()
    if GlassGUI.IsDestroyed then return end
    GlassGUI.IsDestroyed = true

    for _, module in pairs(ModuleRegistry.Modules) do
        pcall(function() module:Disable() end)
    end

    if GlassGUI.MainContainer then
        Util.Tween(GlassGUI.MainContainer, {
            Size = UDim2.new(0, 0, 0, 0),
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

        Util.Tween(GlassGUI.MainFrame, {
            BackgroundTransparency = 1,
        }, 0.25)

        task.wait(0.4)
        GlassGUI.ScreenGui:Destroy()
    end

    getgenv().SC999_FrameworkLoaded = false
    getgenv().SC999_Framework = nil
    ConfigManager.Save()
end

--==========================================================================
--  GlassGUI.UpdateStatus(text)
--==========================================================================

function GlassGUI.UpdateStatus(text)
    if GlassGUI.StatusLabel and not GlassGUI.IsDestroyed then
        GlassGUI.StatusLabel.Text = text
    end
end

--==========================================================================
--  GlassGUI.CreateSection(parent, title)
--==========================================================================

function GlassGUI.CreateSection(parent, title)
    if not parent or GlassGUI.IsDestroyed then return end

    local key = tostring(parent) .. "_" .. title
    if GlassGUI.CreatedSections[key] then return GlassGUI.CreatedSections[key] end

    local Section = Util.Create("Frame", {
        Name = "Section_" .. title,
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local Accent = Util.Create("Frame", {
        Size = UDim2.new(0, 3, 0, 12),
        Position = UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BorderSizePixel = 0,
        Parent = Section,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Accent})

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextTransparency = 0.35,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Section,
    })

    GlassGUI.CreatedSections[key] = Section
    return Section
end

--==========================================================================
--  GlassGUI.CreateToggle(parent, name, labelText, defaultState, callback)
--==========================================================================

function GlassGUI.CreateToggle(parent, name, labelText, defaultState, callback)
    if not parent or GlassGUI.IsDestroyed then return nil end

    local Container = Util.Create("Frame", {
        Name = name .. "_Toggle",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Parent = parent,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Container})

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })

    local ToggleBG = Util.Create("TextButton", {
        Size = UDim2.new(0, 46, 0, 26),
        Position = UDim2.new(1, -56, 0.5, -13),
        BackgroundColor3 = defaultState and GlassGUI.Theme.ToggleOn or GlassGUI.Theme.ToggleOff,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = Container,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleBG})

    local Knob = Util.Create("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = defaultState and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = ToggleBG,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Knob})

    local state = defaultState or false

    local function animateToggle(newState)
        Util.Tween(ToggleBG, {
            BackgroundColor3 = newState and GlassGUI.Theme.ToggleOn or GlassGUI.Theme.ToggleOff,
        }, 0.25)
        Util.Tween(Knob, {
            Position = newState and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11),
        }, 0.25, Enum.EasingStyle.Back)
    end

    ToggleBG.MouseButton1Click:Connect(function()
        state = not state
        animateToggle(state)
        if callback then callback(state) end
    end)

    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.25}, 0.15)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.45}, 0.15)
    end)

    return {
        SetState = function(newState)
            state = newState
            animateToggle(state)
        end,
        GetState = function()
            return state
        end,
    }
end

--==========================================================================
--  GlassGUI.CreateSlider(parent, name, labelText, min, max, default, cb)
--==========================================================================

function GlassGUI.CreateSlider(parent, name, labelText, min, max, defaultValue, callback)
    if not parent or GlassGUI.IsDestroyed then return nil end

    min = min or 0
    max = max or 100
    defaultValue = math.clamp(defaultValue or min, min, max)

    local Container = Util.Create("Frame", {
        Name = name .. "_Slider",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Parent = parent,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Container})

    Util.Create("TextLabel", {
        Size = UDim2.new(0.55, 0, 0, 20),
        Position = UDim2.new(0, 14, 0, 4),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })

    local ValueLabel = Util.Create("TextLabel", {
        Size = UDim2.new(0.35, 0, 0, 20),
        Position = UDim2.new(0.6, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(math.floor(defaultValue)),
        TextColor3 = GlassGUI.Theme.AccentBlue,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Container,
    })

    local Track = Util.Create("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 32),
        BackgroundColor3 = GlassGUI.Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = Container,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Track})

    local pct = (defaultValue - min) / math.max(max - min, 1)

    local Fill = Util.Create("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BorderSizePixel = 0,
        Parent = Track,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Fill})

    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 132, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 200, 250)),
        }),
        Parent = Fill,
    })

    local SliderKnob = Util.Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(pct, -8, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = Track,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderKnob})
    Util.Create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.8,
        Thickness = 1,
        Parent = SliderKnob,
    })

    local isDragging = false

    local function updateSlider(input)
        local trackPos = Track.AbsolutePosition.X
        local trackWidth = Track.AbsoluteSize.X
        if trackWidth == 0 then return end

        local pos = math.clamp((input.Position.X - trackPos) / trackWidth, 0, 1)
        local value = math.floor(min + (max - min) * pos)

        Fill.Size = UDim2.new(pos, 0, 1, 0)
        SliderKnob.Position = UDim2.new(pos, -8, 0.5, -8)
        ValueLabel.Text = tostring(value)

        if callback then callback(value) end
    end

    SliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
            isDragging = true
        end
    end)

    Services.UIS.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                           input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    Services.UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.25}, 0.15)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.45}, 0.15)
    end)

    return {
        SetValue = function(value)
            value = math.clamp(value, min, max)
            local p = (value - min) / math.max(max - min, 1)
            Fill.Size = UDim2.new(p, 0, 1, 0)
            SliderKnob.Position = UDim2.new(p, -8, 0.5, -8)
            ValueLabel.Text = tostring(math.floor(value))
            if callback then callback(math.floor(value)) end
        end,
    }
end

--==========================================================================
--  GlassGUI.CreateInput(parent, name, labelText, defaultValue, callback)
--==========================================================================

function GlassGUI.CreateInput(parent, name, labelText, defaultValue, callback)
    if not parent or GlassGUI.IsDestroyed then return nil end

    local Container = Util.Create("Frame", {
        Name = name .. "_Input",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Parent = parent,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Container})

    Util.Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })

    local TextBox = Util.Create("TextBox", {
        Size = UDim2.new(0, 64, 0, 26),
        Position = UDim2.new(1, -76, 0.5, -13),
        BackgroundColor3 = GlassGUI.Theme.InputBg,
        BackgroundTransparency = 0.2,
        Text = tostring(defaultValue),
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        Parent = Container,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TextBox})

    TextBox.FocusLost:Connect(function()
        local val = tonumber(TextBox.Text)
        if val then
            if callback then callback(val) end
        else
            TextBox.Text = tostring(defaultValue)
        end
    end)

    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.25}, 0.15)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.45}, 0.15)
    end)

    return {
        SetText = function(text) TextBox.Text = tostring(text) end,
    }
end

--==========================================================================
--  GlassGUI.CreateActionButton(parent, name, displayName, btnLabel, color, cb)
--  Clean card: name on left + small launch button on right.
--==========================================================================

function GlassGUI.CreateActionButton(parent, name, displayName, btnLabel, color, callback)
    if not parent or GlassGUI.IsDestroyed then return nil end

    local Container = Util.Create("Frame", {
        Name = name .. "_Action",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = parent,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Container})

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -96, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = displayName,
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })

    local Btn = Util.Create("TextButton", {
        Size = UDim2.new(0, 68, 0, 26),
        Position = UDim2.new(1, -78, 0.5, -13),
        BackgroundColor3 = color or GlassGUI.Theme.AccentBlue,
        BackgroundTransparency = 0.15,
        Text = btnLabel or "Launch",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = Container,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Btn})

    Btn.MouseButton1Click:Connect(function()
        Util.Tween(Btn, {
            Size = UDim2.new(0, 64, 0, 24),
            Position = UDim2.new(1, -76, 0.5, -12),
        }, 0.06)
        task.wait(0.06)
        Util.Tween(Btn, {
            Size = UDim2.new(0, 68, 0, 26),
            Position = UDim2.new(1, -78, 0.5, -13),
        }, 0.1, Enum.EasingStyle.Back)
        if callback then callback() end
    end)

    Btn.MouseEnter:Connect(function()
        Util.Tween(Btn, {BackgroundTransparency = 0}, 0.12)
    end)
    Btn.MouseLeave:Connect(function()
        Util.Tween(Btn, {BackgroundTransparency = 0.15}, 0.12)
    end)

    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.2}, 0.15)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.4}, 0.15)
    end)

    return Btn
end

--==========================================================================
--  GlassGUI.RegisterModuleUI(module)
--  Auto-routes module UI to the correct tab based on Category metadata.
--==========================================================================

local TAB_ROUTING = {
    Movement = "Player",
    Player   = "Player",
    Visual   = "Player",
    Utility  = "Player",
    External = "Apps",
    Tools    = "Apps",
    Game     = "Apps",
}

function GlassGUI.RegisterModuleUI(module)
    local meta = module.Metadata or {}
    local category = meta.Category or "Player"
    local targetTabName = TAB_ROUTING[category] or "Player"
    local page = GlassGUI.TabPages[targetTabName]

    if not page then
        page = GlassGUI.TabPages["Player"]
    end

    -- Toggle (ON/OFF switch)
    if meta.HasToggle ~= false then
        local defaultState = module.Config.Enabled or meta.AutoEnable or false
        local toggle = GlassGUI.CreateToggle(
            page,
            module.Name,
            meta.DisplayName or module.Name,
            defaultState,
            function(state)
                if state then
                    module:Enable()
                else
                    module:Disable()
                end
                module:SetConfig("Enabled", state)
            end
        )
        GlassGUI.ToggleButtons[module.Name] = toggle
    end

    -- Slider
    if meta.Slider then
        local s = meta.Slider
        GlassGUI.CreateSlider(
            page,
            module.Name .. "_Slider",
            s.Label or "Value",
            s.Min or 0,
            s.Max or 100,
            module.Config[s.ConfigKey] or s.Default or 50,
            function(value)
                module:SetConfig(s.ConfigKey or "Value", value)
                if s.OnChange then s.OnChange(module, value) end
            end
        )
    end

    -- Input
    if meta.Input then
        local i = meta.Input
        GlassGUI.CreateInput(
            page,
            module.Name .. "_Input",
            i.Label or "Input",
            module.Config[i.ConfigKey] or i.Default or "",
            function(value)
                module:SetConfig(i.ConfigKey or "Value", value)
                if i.OnChange then i.OnChange(module, value) end
            end
        )
    end

    -- Action Button (for external script launchers)
    if meta.ActionButton then
        local b = meta.ActionButton
        GlassGUI.CreateActionButton(
            page,
            module.Name,
            meta.DisplayName or module.Name,
            b.Label or "Launch",
            b.Color,
            function()
                if b.OnClick then b.OnClick(module) end
            end
        )
    end

    -- Update status
    local moduleCount = 0
    for _ in pairs(ModuleRegistry.Modules) do moduleCount = moduleCount + 1 end
    GlassGUI.UpdateStatus("Ready · " .. moduleCount .. " modules")
end

--==========================================================================
--  GlassGUI.SetupHomeTab()
--  Populates the Home tab with framework info and settings.
--==========================================================================

function GlassGUI.SetupHomeTab()
    local page = GlassGUI.TabPages["Home"]
    if not page then return end

    -- Welcome Banner
    local Banner = Util.Create("Frame", {
        Name = "WelcomeBanner",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = page,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = Banner})
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 132, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 200, 250)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(1, 0.92),
        }),
        Rotation = 25,
        Parent = Banner,
    })

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 14, 0, 12),
        BackgroundTransparency = 1,
        Text = "SC999 Hub",
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Banner,
    })

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 14, 0, 36),
        BackgroundTransparency = 1,
        Text = "Modular Framework · Glassmorphism Edition",
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Banner,
    })

    -- Info Section
    GlassGUI.CreateSection(page, "INFO")

    local InfoCard = Util.Create("Frame", {
        Name = "InfoCard",
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Parent = page,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = InfoCard})

    local gameName = "Unknown"
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)

    local infoLines = {
        {label = "Player", value = player.DisplayName or player.Name},
        {label = "Game", value = gameName},
        {label = "Modules", value = "Loading..."},
    }

    for idx, info in ipairs(infoLines) do
        local yPos = (idx - 1) * 22

        Util.Create("TextLabel", {
            Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.new(0, 14, 0, yPos + 2),
            BackgroundTransparency = 1,
            Text = info.label,
            TextColor3 = GlassGUI.Theme.TextSecondary,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextTransparency = 0.3,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = InfoCard,
        })

        local valLabel = Util.Create("TextLabel", {
            Name = info.label .. "_Value",
            Size = UDim2.new(1, -90, 0, 20),
            Position = UDim2.new(0, 78, 0, yPos + 2),
            BackgroundTransparency = 1,
            Text = info.value,
            TextColor3 = GlassGUI.Theme.TextPrimary,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = InfoCard,
        })

        if info.label == "Modules" then
            GlassGUI._ModuleCountLabel = valLabel
        end
    end

    -- Settings Section
    GlassGUI.CreateSection(page, "SETTINGS")

    local debugConfig = getgenv().SC999_Config or {}
    GlassGUI.CreateToggle(page, "DebugMode", "Debug Mode", debugConfig.DebugMode or false, function(state)
        local config = getgenv().SC999_Config or {}
        config.DebugMode = state
        getgenv().SC999_Config = config
        ConfigManager.Save(config)
    end)

    -- Credits Section
    GlassGUI.CreateSection(page, "CREDITS")

    local CreditsCard = Util.Create("Frame", {
        Name = "CreditsCard",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Parent = page,
    })
    Util.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = CreditsCard})

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 14, 0, 4),
        BackgroundTransparency = 1,
        Text = "Made by Biasaemail",
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = CreditsCard,
    })

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 14, 0, 22),
        BackgroundTransparency = 1,
        Text = "github.com/Biasaemail/SC999-Framework",
        TextColor3 = GlassGUI.Theme.AccentBlue,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = CreditsCard,
    })
end

--===============================================================================
--  FRAMEWORK API
--===============================================================================

local SC999 = {}
SC999.Version = "2.0"

-- Core references
SC999.Services = Services
SC999.Util = Util
SC999.ConfigManager = ConfigManager
SC999.ModuleRegistry = ModuleRegistry
SC999.GUI = GlassGUI

-- Create a new module
function SC999.CreateModule(name, metadata)
    local module = ModuleBase.new(name, metadata)
    ModuleRegistry.Register(module)

    task.delay(0.15, function()
        GlassGUI.RegisterModuleUI(module)
    end)

    return module
end

-- Get existing module
function SC999.GetModule(name)
    return ModuleRegistry.Get(name)
end

-- Load external module from URL
function SC999.LoadModule(url, moduleName, metadata)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success then
        Util.DebugLog("Loader", "Loaded module:", moduleName or url)
        if result and moduleName then
            ModuleRegistry.Register(result)
            GlassGUI.RegisterModuleUI(result)
        end
        return result
    else
        warn("[SC999] Failed to load module:", moduleName or url, "-", result)
        return nil
    end
end

-- Execute external script
function SC999.Execute(url, scriptName)
    local success, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if success then
        Util.Notify("SC999", scriptName .. " loaded!")
    else
        warn("[SC999] Failed to execute:", scriptName, "-", err)
        Util.Notify("SC999", "Failed: " .. scriptName)
    end
    return success
end

-- Initialize Framework
function SC999.Init()
    ConfigManager.Load()
    GlassGUI.Create()

    task.delay(0.2, function()
        GlassGUI.SetupHomeTab()
    end)

    getgenv().SC999_FrameworkLoaded = true
    getgenv().SC999_Framework = SC999

    Util.Notify("SC999 Framework", "v2.0 Loaded Successfully")
    print("=== SC999 FRAMEWORK v2.0 ACTIVE ===")
    print("GitHub: https://github.com/Biasaemail/SC999-Framework")

    return SC999
end

-- Cleanup
function SC999.Destroy()
    GlassGUI.Close()
end

-- Unload (for safe reload)
function SC999.Unload()
    GlassGUI.Close()
end

-- Update module count on Home tab
function SC999.UpdateHomeModuleCount()
    if GlassGUI._ModuleCountLabel then
        local count = 0
        for _ in pairs(ModuleRegistry.Modules) do count = count + 1 end
        GlassGUI._ModuleCountLabel.Text = tostring(count) .. " loaded"
    end
end

-- Auto-save on exit
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "SC999_Framework" then
        ConfigManager.Save()
    end
end)

-- Return framework
return SC999
