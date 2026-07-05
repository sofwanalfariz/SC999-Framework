--===============================================================================
--  SC999 FRAMEWORK CORE v1.0
--  Modular Roblox Script Framework with iOS Glassmorphism GUI
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
    GUIPosition = {0.5, -140, 0.5, -160},
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
            -- Merge with defaults
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
    -- Disconnect all connections
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
    -- Destroy all objects
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
--  iOS GLASSMORPHISM GUI SYSTEM
--===============================================================================

local GlassGUI = {}
GlassGUI.MainFrame = nil
GlassGUI.ContentFrame = nil
GlassGUI.ToggleButtons = {}
GlassGUI.IsMinimized = false
GlassGUI.IsDestroyed = false

-- Theme Colors
GlassGUI.Theme = {
    Background = Color3.fromRGB(20, 20, 22),
    GlassTransparency = 0.25,
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.88,
    AccentGreen = Color3.fromRGB(52, 199, 89),
    AccentBlue = Color3.fromRGB(10, 132, 255),
    AccentPurple = Color3.fromRGB(175, 82, 222),
    AccentOrange = Color3.fromRGB(255, 149, 0),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(230, 230, 230),
    ToggleOff = Color3.fromRGB(70, 70, 75),
    ToggleOn = Color3.fromRGB(52, 199, 89),
    InputBg = Color3.fromRGB(40, 40, 45),
    CardBg = Color3.fromRGB(30, 30, 33),
}

function GlassGUI.Create()
    if GlassGUI.IsDestroyed then return end
    
    -- Cleanup old GUI
    local oldGui = Services.CoreGui:FindFirstChild("SC999_Framework")
    if oldGui then oldGui:Destroy() end
    
    -- Main ScreenGui
    local ScreenGui = Util.Create("ScreenGui", {
        Name = "SC999_Framework",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = (gethui and gethui()) or Services.CoreGui,
    })
    
    -- Glassmorphism Background Effect
    local GlassBg = Util.Create("Frame", {
        Name = "GlassBg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Parent = ScreenGui,
    })
    
    -- Backdrop blur effect (iOS style)
    local BlurEffect = nil
    pcall(function()
        if getgenv().createBlur then
            BlurEffect = getgenv().createBlur(GlassBg)
        end
    end)
    
    -- Main Container
    local MainContainer = Util.Create("Frame", {
        Name = "MainContainer",
        Size = UDim2.new(0, 280, 0, 380),
        Position = UDim2.new(0.85, 0, 0.1, 0),
        BackgroundTransparency = 1,
        Active = true,
        Parent = ScreenGui,
    })
    
    -- Main Frame (Glass)
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
    
    -- Corner radius
    local Corner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 20),
        Parent = MainFrame,
    })
    
    -- Glass stroke
    local Stroke = Util.Create("UIStroke", {
        Color = GlassGUI.Theme.StrokeColor,
        Transparency = GlassGUI.Theme.StrokeTransparency,
        Thickness = 1.2,
        Parent = MainFrame,
    })
    
    -- Gradient overlay for glass effect
    local Gradient = Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 240, 245)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 230)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.93),
            NumberSequenceKeypoint.new(0.5, 0.95),
            NumberSequenceKeypoint.new(1, 0.93),
        }),
        Rotation = 135,
        Parent = MainFrame,
    })
    
    -- Top Bar (Header)
    local TopBar = Util.Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = MainFrame,
    })
    
    -- Title
    local Title = Util.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Text = "SC999 Hub",
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })
    
    -- Subtitle
    local Subtitle = Util.Create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -100, 0, 16),
        Position = UDim2.new(0, 20, 0, 30),
        BackgroundTransparency = 1,
        Text = "v1.0 | Glass Edition",
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextTransparency = 0.4,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })
    
    -- Minimize Button (-)
    local MinBtn = Util.Create("TextButton", {
        Name = "MinimizeBtn",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -72, 0, 9),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BackgroundTransparency = 0.2,
        Text = "-",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = false,
        Parent = TopBar,
    })
    local MinCorner = Util.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = MinBtn})
    
    -- Close Button (X)
    local CloseBtn = Util.Create("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -36, 0, 9),
        BackgroundColor3 = Color3.fromRGB(255, 59, 48),
        BackgroundTransparency = 0.2,
        Text = "x",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = TopBar,
    })
    local CloseCorner = Util.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = CloseBtn})
    
    -- Divider
    local Divider = Util.Create("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, -30, 0, 1),
        Position = UDim2.new(0, 15, 0, 50),
        BackgroundColor3 = GlassGUI.Theme.StrokeColor,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    
    -- Scrollable Content Area
    local ScrollFrame = Util.Create("ScrollingFrame", {
        Name = "ScrollContent",
        Size = UDim2.new(1, -20, 1, -110),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = GlassGUI.Theme.AccentBlue,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = MainFrame,
    })
    
    local ScrollLayout = Util.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = ScrollFrame,
    })
    
    local ScrollPadding = Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = ScrollFrame,
    })
    
    -- Bottom Status Bar
    local StatusBar = Util.Create("Frame", {
        Name = "StatusBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 1, -36),
        BackgroundTransparency = 0.6,
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    
    local StatusCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 0),
        Parent = StatusBar,
    })
    
    local StatusLabel = Util.Create("TextLabel", {
        Name = "StatusText",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "Ready | Modules: 0",
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = StatusBar,
    })
    
    GlassGUI.MainFrame = MainFrame
    GlassGUI.ContentFrame = ScrollFrame
    GlassGUI.StatusLabel = StatusLabel
    GlassGUI.ScreenGui = ScreenGui
    GlassGUI.MainContainer = MainContainer
    
    --========== DRAGGING ==========
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
            }, 0.08, Enum.EasingStyle.Sine)
        end
    end)
    
    Services.UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    --========== MINIMIZE ==========
    MinBtn.MouseButton1Click:Connect(function()
        GlassGUI.ToggleMinimize()
    end)
    
    -- Hover effects for buttons
    MinBtn.MouseEnter:Connect(function()
        Util.Tween(MinBtn, {BackgroundTransparency = 0}, 0.15)
    end)
    MinBtn.MouseLeave:Connect(function()
        Util.Tween(MinBtn, {BackgroundTransparency = 0.2}, 0.15)
    end)
    
    --========== CLOSE ==========
    CloseBtn.MouseButton1Click:Connect(function()
        GlassGUI.Close()
    end)
    
    CloseBtn.MouseEnter:Connect(function()
        Util.Tween(CloseBtn, {BackgroundTransparency = 0}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Util.Tween(CloseBtn, {BackgroundTransparency = 0.2}, 0.15)
    end)
    
    -- Entrance Animation
    MainContainer.Size = UDim2.new(0, 0, 0, 0)
    MainContainer.Position = UDim2.new(0.85, 140, 0.1, 190)
    Util.Tween(MainContainer, {
        Size = UDim2.new(0, 280, 0, 380),
        Position = UDim2.new(0.85, 0, 0.1, 0),
    }, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Entrance for content
    MainFrame.BackgroundTransparency = 1
    Util.Tween(MainFrame, {BackgroundTransparency = GlassGUI.Theme.GlassTransparency}, 0.8)
    
    return GlassGUI
end

-- Toggle Minimize
function GlassGUI.ToggleMinimize()
    if GlassGUI.IsDestroyed then return end
    GlassGUI.IsMinimized = not GlassGUI.IsMinimized
    
    if GlassGUI.IsMinimized then
        Util.Tween(GlassGUI.MainFrame, {
            Size = UDim2.new(1, 0, 0, 50),
        }, 0.4, Enum.EasingStyle.Quart)
        GlassGUI.ContentFrame.Visible = false
        GlassGUI.MainFrame.StatusBar.Visible = false
    else
        Util.Tween(GlassGUI.MainFrame, {
            Size = UDim2.new(1, 0, 1, 0),
        }, 0.4, Enum.EasingStyle.Quart)
        task.delay(0.2, function()
            GlassGUI.ContentFrame.Visible = true
            GlassGUI.MainFrame.StatusBar.Visible = true
        end)
    end
end

-- Close GUI
function GlassGUI.Close()
    if GlassGUI.IsDestroyed then return end
    GlassGUI.IsDestroyed = true
    
    -- Disable all modules
    for _, module in pairs(ModuleRegistry.Modules) do
        pcall(function() module:Disable() end)
    end
    
    -- Close animation
    if GlassGUI.MainContainer then
        Util.Tween(GlassGUI.MainContainer, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.85, 140, 0.1, 190),
        }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.45)
        GlassGUI.ScreenGui:Destroy()
    end
    
    -- Cleanup globals
    getgenv().SC999_FrameworkLoaded = false
    getgenv().SC999_Framework = nil
    ConfigManager.Save()
end

-- Update status bar
function GlassGUI.UpdateStatus(text)
    if GlassGUI.StatusLabel and not GlassGUI.IsDestroyed then
        GlassGUI.StatusLabel.Text = text
    end
end

-- Create iOS Toggle in GUI
function GlassGUI.CreateToggle(name, labelText, defaultState, callback)
    if not GlassGUI.ContentFrame or GlassGUI.IsDestroyed then return nil end
    
    local Container = Util.Create("Frame", {
        Name = name .. "_ToggleContainer",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = GlassGUI.ContentFrame,
    })
    
    local ContainerCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = Container,
    })
    
    local Label = Util.Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })
    
    -- iOS Toggle Background
    local ToggleBG = Util.Create("TextButton", {
        Size = UDim2.new(0, 48, 0, 26),
        Position = UDim2.new(1, -60, 0.5, -13),
        BackgroundColor3 = defaultState and GlassGUI.Theme.ToggleOn or GlassGUI.Theme.ToggleOff,
        Text = "",
        AutoButtonColor = false,
        Parent = Container,
    })
    
    local ToggleCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ToggleBG,
    })
    
    -- Knob
    local Knob = Util.Create("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = defaultState and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = ToggleBG,
    })
    
    local KnobCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Knob,
    })
    
    -- Toggle Logic
    local state = defaultState
    ToggleBG.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        
        local goalBG = {
            BackgroundColor3 = state and GlassGUI.Theme.ToggleOn or GlassGUI.Theme.ToggleOff
        }
        local goalKnob = {
            Position = state and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        }
        
        Util.Tween(ToggleBG, goalBG, 0.25)
        Util.Tween(Knob, goalKnob, 0.25)
    end)
    
    -- Hover effect
    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.3}, 0.2)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    return {
        SetState = function(newState)
            state = newState
            local goalBG = {
                BackgroundColor3 = state and GlassGUI.Theme.ToggleOn or GlassGUI.Theme.ToggleOff
            }
            local goalKnob = {
                Position = state and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
            }
            Util.Tween(ToggleBG, goalBG, 0.25)
            Util.Tween(Knob, goalKnob, 0.25)
        end,
        GetState = function() return state end,
    }
end

-- Create Slider
function GlassGUI.CreateSlider(name, labelText, min, max, defaultValue, callback)
    if not GlassGUI.ContentFrame or GlassGUI.IsDestroyed then return nil end
    
    min = min or 0
    max = max or 100
    defaultValue = math.clamp(defaultValue or min, min, max)
    
    local Container = Util.Create("Frame", {
        Name = name .. "_SliderContainer",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = GlassGUI.ContentFrame,
    })
    
    local ContainerCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = Container,
    })
    
    local Label = Util.Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 24),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })
    
    local ValueLabel = Util.Create("TextLabel", {
        Size = UDim2.new(0.3, 0, 0, 24),
        Position = UDim2.new(0.65, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(defaultValue),
        TextColor3 = GlassGUI.Theme.AccentBlue,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Container,
    })
    
    -- Slider Track
    local Track = Util.Create("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 36),
        BackgroundColor3 = GlassGUI.Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = Container,
    })
    
    local TrackCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Track,
    })
    
    -- Fill
    local percent = (defaultValue - min) / (max - min)
    local Fill = Util.Create("Frame", {
        Size = UDim2.new(percent, 0, 1, 0),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BorderSizePixel = 0,
        Parent = Track,
    })
    
    local FillCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Fill,
    })
    
    -- Knob
    local SliderKnob = Util.Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(percent, -8, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = Track,
    })
    
    local SliderKnobCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = SliderKnob,
    })
    
    -- Slider Logic
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        
        Util.Tween(Fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05)
        Util.Tween(SliderKnob, {Position = UDim2.new(pos, -8, 0.5, -8)}, 0.05)
        ValueLabel.Text = tostring(value)
        callback(value)
    end
    
    SliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
            dragging = true
        end
    end)
    
    Services.UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    Services.UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Hover
    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.3}, 0.2)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    return {
        SetValue = function(value)
            value = math.clamp(value, min, max)
            local pos = (value - min) / (max - min)
            Util.Tween(Fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
            Util.Tween(SliderKnob, {Position = UDim2.new(pos, -8, 0.5, -8)}, 0.1)
            ValueLabel.Text = tostring(value)
            callback(value)
        end,
    }
end

-- Create Input Box
function GlassGUI.CreateInput(name, labelText, defaultValue, callback)
    if not GlassGUI.ContentFrame or GlassGUI.IsDestroyed then return nil end
    
    local Container = Util.Create("Frame", {
        Name = name .. "_InputContainer",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = GlassGUI.ContentFrame,
    })
    
    local ContainerCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = Container,
    })
    
    local Label = Util.Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Container,
    })
    
    local TextBox = Util.Create("TextBox", {
        Size = UDim2.new(0, 60, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = GlassGUI.Theme.InputBg,
        BackgroundTransparency = 0.3,
        Text = tostring(defaultValue),
        TextColor3 = GlassGUI.Theme.TextPrimary,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ClearTextOnFocus = false,
        Parent = Container,
    })
    
    local BoxCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = TextBox,
    })
    
    TextBox.FocusLost:Connect(function()
        local val = tonumber(TextBox.Text)
        if val then
            callback(val)
        else
            TextBox.Text = tostring(defaultValue)
        end
    end)
    
    -- Hover
    Container.MouseEnter:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.3}, 0.2)
    end)
    Container.MouseLeave:Connect(function()
        Util.Tween(Container, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    return {
        SetText = function(text) TextBox.Text = tostring(text) end,
    }
end

-- Create Section Header
function GlassGUI.CreateSection(title)
    if not GlassGUI.ContentFrame or GlassGUI.IsDestroyed then return end
    
    local Section = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = GlassGUI.ContentFrame,
    })
    
    local Accent = Util.Create("Frame", {
        Size = UDim2.new(0, 3, 0, 14),
        Position = UDim2.new(0, 4, 0.5, -7),
        BackgroundColor3 = GlassGUI.Theme.AccentBlue,
        BorderSizePixel = 0,
        Parent = Section,
    })
    
    local AccentCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Accent,
    })
    
    local Label = Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = GlassGUI.Theme.TextSecondary,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextTransparency = 0.4,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Section,
    })
    
    return Section
end

-- Create Action Button (for external scripts)
function GlassGUI.CreateActionButton(name, labelText, color, callback)
    if not GlassGUI.ContentFrame or GlassGUI.IsDestroyed then return nil end
    
    local Container = Util.Create("Frame", {
        Name = name .. "_BtnContainer",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = GlassGUI.Theme.CardBg,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = GlassGUI.ContentFrame,
    })
    
    local ContainerCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = Container,
    })
    
    local Button = Util.Create("TextButton", {
        Size = UDim2.new(1, -16, 0, 36),
        Position = UDim2.new(0, 8, 0.5, -18),
        BackgroundColor3 = color or GlassGUI.Theme.AccentBlue,
        BackgroundTransparency = 0.15,
        Text = labelText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = Container,
    })
    
    local BtnCorner = Util.Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = Button,
    })
    
    Button.MouseButton1Click:Connect(function()
        -- Click animation
        Util.Tween(Button, {Size = UDim2.new(1, -20, 0, 32), Position = UDim2.new(0, 10, 0.5, -16)}, 0.08)
        task.wait(0.08)
        Util.Tween(Button, {Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 0.5, -18)}, 0.12)
        callback()
    end)
    
    Button.MouseEnter:Connect(function()
        Util.Tween(Button, {BackgroundTransparency = 0}, 0.2)
        Util.Tween(Container, {BackgroundTransparency = 0.3}, 0.2)
    end)
    Button.MouseLeave:Connect(function()
        Util.Tween(Button, {BackgroundTransparency = 0.15}, 0.2)
        Util.Tween(Container, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    return Button
end

-- Register module UI elements based on metadata
function GlassGUI.RegisterModuleUI(module)
    local meta = module.Metadata or {}
    
    -- Section header if category specified
    if meta.Category then
        GlassGUI.CreateSection(meta.Category)
    end
    
    -- Toggle for enable/disable
    if meta.HasToggle ~= false then
        local defaultState = module.Config.Enabled or meta.AutoEnable or false
        local toggle = GlassGUI.CreateToggle(
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
    
    -- Slider if specified
    if meta.Slider then
        local sliderMeta = meta.Slider
        GlassGUI.CreateSlider(
            module.Name .. "_Slider",
            sliderMeta.Label or "Value",
            sliderMeta.Min or 0,
            sliderMeta.Max or 100,
            module.Config[sliderMeta.ConfigKey] or sliderMeta.Default or 50,
            function(value)
                module:SetConfig(sliderMeta.ConfigKey or "Value", value)
                if sliderMeta.OnChange then
                    sliderMeta.OnChange(module, value)
                end
            end
        )
    end
    
    -- Input if specified
    if meta.Input then
        local inputMeta = meta.Input
        GlassGUI.CreateInput(
            module.Name .. "_Input",
            inputMeta.Label or "Input",
            module.Config[inputMeta.ConfigKey] or inputMeta.Default or "",
            function(value)
                module:SetConfig(inputMeta.ConfigKey or "Value", value)
                if inputMeta.OnChange then
                    inputMeta.OnChange(module, value)
                end
            end
        )
    end
    
    -- Action Button if specified (for external script loaders)
    if meta.ActionButton then
        local btnMeta = meta.ActionButton
        GlassGUI.CreateActionButton(
            module.Name,
            btnMeta.Label or "Execute",
            btnMeta.Color,
            function()
                if btnMeta.OnClick then
                    btnMeta.OnClick(module)
                end
            end
        )
    end
    
    -- Update status
    local moduleCount = 0
    for _ in pairs(ModuleRegistry.Modules) do moduleCount = moduleCount + 1 end
    GlassGUI.UpdateStatus("Ready | Modules: " .. moduleCount)
end

--===============================================================================
--  FRAMEWORK API
--===============================================================================

local SC999 = {}

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
    
    -- Auto-create UI after a short delay to ensure GUI is ready
    task.delay(0.1, function()
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
        Util.Notify("SC999", scriptName .. " loaded successfully!")
    else
        warn("[SC999] Failed to execute:", scriptName, "-", err)
        Util.Notify("SC999", "Failed to load " .. scriptName)
    end
    return success
end

-- Initialize Framework
function SC999.Init()
    -- Load config
    ConfigManager.Load()
    
    -- Create GUI
    GlassGUI.Create()
    
    -- Mark loaded
    getgenv().SC999_FrameworkLoaded = true
    getgenv().SC999_Framework = SC999
    
    Util.Notify("SC999 Framework", "v1.0 Loaded Successfully")
    print("=== SC999 FRAMEWORK v1.0 ACTIVE ===")
    print("GitHub: https://github.com/Biasaemail/SC999-Framework")
    
    return SC999
end

-- Cleanup
function SC999.Destroy()
    GlassGUI.Close()
end

-- Auto-save on exit
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "SC999_Framework" then
        ConfigManager.Save()
    end
end)

-- Return framework
return SC999
