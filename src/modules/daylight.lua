--===============================================================================
--  MODULE: Daylight Control (Day/Night Toggle)
--  Desc: Enhanced daylight script - Full brightness, no fog, effects control
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    local Services = SC999.Services
    
    local module = SC999.CreateModule("Daylight", {
        DisplayName = "Full Bright",
        Category = "Visual",
        HasToggle = true,
        AutoEnable = false,
    })
    
    --============================================================================
    --  CONSTANTS
    --============================================================================
    
    local Lighting = game:GetService("Lighting")
    local Camera = workspace:WaitForChild("Camera")
    local RunService = Services.RunService
    
    local DAY_SETTINGS = {
        ClockTime = 14,
        Brightness = 2.0,
        Ambient = Color3.fromRGB(128, 128, 128),
        OutdoorAmbient = Color3.fromRGB(128, 128, 128),
        FogEnd = 1000000,
        FogStart = 999000,
        GlobalShadows = false,
        ShadowSoftness = 0,
    }
    
    local NIGHT_SETTINGS = {
        ClockTime = 0,
        Brightness = 0.5,
        Ambient = Color3.fromRGB(40, 40, 60),
        OutdoorAmbient = Color3.fromRGB(40, 40, 60),
        FogEnd = 500,
        FogStart = 0,
        GlobalShadows = true,
        ShadowSoftness = 0.5,
    }
    
    local EFFECTS_TO_DISABLE = {
        "ColorCorrectionEffect",
        "BloomEffect",
        "BlurEffect",
        "SunRaysEffect",
        "DepthOfFieldEffect",
        "Atmosphere",
        "ChromaticAberrationEffect",
    }
    
    local originalSettings = {}
    local steppedConnection = nil
    
    --============================================================================
    --  CORE FUNCTIONS
    --============================================================================
    
    local function disableEffectsIn(parent)
        if not parent then return end
        for _, effectName in ipairs(EFFECTS_TO_DISABLE) do
            local effect = parent:FindFirstChildOfClass(effectName)
            if effect then
                pcall(function()
                    if effect:IsA("Atmosphere") then
                        effect.Density = 0
                        effect.Haze = 0
                        effect.Glare = 0
                    elseif effect:IsA("ColorCorrectionEffect") then
                        effect.Contrast = 0
                        effect.Saturation = 1
                        effect.Brightness = 0
                        effect.TintColor = Color3.new(1, 1, 1)
                        effect.Enabled = false
                    elseif effect:IsA("BloomEffect") then
                        effect.Intensity = 0
                        effect.Enabled = false
                    elseif effect:IsA("DepthOfFieldEffect") then
                        effect.Enabled = false
                    else
                        effect.Enabled = false
                    end
                end)
            end
        end
    end
    
    local function applySettings(settings)
        pcall(function()
            for property, value in pairs(settings) do
                if Lighting[property] ~= nil then
                    Lighting[property] = value
                end
            end
            disableEffectsIn(Lighting)
            disableEffectsIn(Camera)
        end)
    end
    
    local function saveOriginalSettings()
        originalSettings = {
            ClockTime = Lighting.ClockTime,
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            GlobalShadows = Lighting.GlobalShadows,
            ShadowSoftness = Lighting.ShadowSoftness,
        }
    end
    
    --============================================================================
    --  LIFECYCLE
    --============================================================================
    
    function module:OnEnable()
        saveOriginalSettings()
        
        -- Apply day settings immediately
        applySettings(DAY_SETTINGS)
        
        -- Continuous enforcement
        steppedConnection = RunService.Heartbeat:Connect(function()
            if not self.Enabled then return end
            applySettings(DAY_SETTINGS)
        end)
        self:AddConnection("daylightLoop", steppedConnection)
        
        -- Watch for property changes
        self:AddConnection("propChange", Lighting.Changed:Connect(function()
            if self.Enabled then
                applySettings(DAY_SETTINGS)
            end
        end))
        
        -- Watch for new effects
        self:AddConnection("childAdded", Lighting.ChildAdded:Connect(function(child)
            if not self.Enabled then return end
            for _, effectName in ipairs(EFFECTS_TO_DISABLE) do
                if child:IsA(effectName) then
                    task.wait(0.1)
                    disableEffectsIn(Lighting)
                    break
                end
            end
        end))
        
        Util.DebugLog("Daylight", "Full Bright activated")
    end
    
    function module:OnDisable()
        -- Stop enforcement
        if steppedConnection then
            pcall(function() steppedConnection:Disconnect() end)
            steppedConnection = nil
        end
        
        -- Restore original settings
        if next(originalSettings) then
            applySettings(originalSettings)
        end
        
        -- Re-enable effects
        pcall(function()
            for _, effectName in ipairs(EFFECTS_TO_DISABLE) do
                local effect = Lighting:FindFirstChildOfClass(effectName)
                if effect then
                    effect.Enabled = true
                end
            end
        end)
        
        Util.DebugLog("Daylight", "Settings restored")
    end
    
    return module
end
