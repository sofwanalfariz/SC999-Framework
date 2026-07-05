--===============================================================================
--  MODULE: Walkspeed System v3.2
--  Desc: Safe MetaHook, SmartCheck, Anti-conflict speed system
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    local ConfigManager = SC999.ConfigManager
    local Services = SC999.Services
    local player = Services.Players.LocalPlayer
    
    local module = SC999.CreateModule("Walkspeed", {
        DisplayName = "Walkspeed",
        Category = "Movement",
        HasToggle = true,
        AutoEnable = true,
        Slider = {
            Label = "Speed",
            Min = 16,
            Max = 500,
            Default = 100,
            ConfigKey = "Speed",
            OnChange = function(mod, value)
                mod:SetSpeed(value)
            end,
        },
    })
    
    -- Local state
    local SmartCheckRunning = false
    local MetaHookInstalled = false
    
    --============================================================================
    --  CORE FUNCTIONS (Preserved from v3.2)
    --============================================================================
    
    function module:GetHumanoid()
        local char = player.Character
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
    end
    
    function module:SetSpeed(hum, value)
        if not hum then
            hum = self:GetHumanoid()
            if not hum then return end
        end
        value = value or self:GetConfig("Speed", 100)
        hum.AutoJumpEnabled = false
        pcall(function() hum.WalkSpeed = value end)
    end
    
    function module:PrepareMetaHook()
        if MetaHookInstalled then return true end
        if not getrawmetatable then return false end
        
        local success = pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            
            if not getgenv()._SC999_OriginalNewIndex then
                getgenv()._SC999_OriginalNewIndex = mt.__newindex
            end
            
            local originalFunc = getgenv()._SC999_OriginalNewIndex
            local selfConfig = self.Config
            
            mt.__newindex = newcclosure(function(self, idx, val)
                if idx == "WalkSpeed" and not checkcaller() then
                    if selfConfig.UseMetaHook then
                        return originalFunc(self, idx, selfConfig.Speed or 100)
                    end
                end
                return originalFunc(self, idx, val)
            end)
            
            setreadonly(mt, true)
            MetaHookInstalled = true
            Util.DebugLog("Walkspeed", "MetaHook Installed")
        end)
        
        return success
    end
    
    function module:SetupLogic1(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        
        -- Disconnect old speed lock
        if self.Connections.speedLock then
            pcall(function() self.Connections.speedLock:Disconnect() end)
        end
        
        local selfConfig = self.Config
        
        self.Connections.speedLock = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if selfConfig.UseMetaHook then return end
            if not self.Enabled then return end
            
            local speed = selfConfig.Speed or 100
            if math.abs(hum.WalkSpeed - speed) > 1 then
                self:SetSpeed(hum, speed)
            end
        end)
    end
    
    function module:SmartCheck()
        if SmartCheckRunning then return end
        SmartCheckRunning = true
        
        task.spawn(function()
            local char = player.Character
            task.wait(1.5)
            
            if not player.Character or player.Character ~= char then
                SmartCheckRunning = false
                return
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then
                SmartCheckRunning = false
                return
            end
            
            local speed = self.Config.Speed or 100
            
            self:PrepareMetaHook()
            self:SetSpeed(hum, speed)
            task.wait(0.5)
            
            local diff = math.abs(hum.WalkSpeed - speed)
            
            if diff <= 1 then
                self.Config.UseMetaHook = false
                Util.DebugLog("Walkspeed", "Mode: Simple Lock")
            else
                self.Config.UseMetaHook = true
                Util.DebugLog("Walkspeed", "Mode: MetaHook Active")
                self:SetSpeed(hum, speed)
            end
            
            ConfigManager.SetModuleConfig(self.Name, self.Config)
            SmartCheckRunning = false
        end)
    end
    
    function module:UpdateSpeed(newSpeed)
        self:SetConfig("Speed", newSpeed)
        self:SetSpeed(nil, newSpeed)
    end
    
    --============================================================================
    --  LIFECYCLE
    --============================================================================
    
    function module:OnEnable()
        SmartCheckRunning = false
        MetaHookInstalled = false
        
        -- Apply speed immediately
        local hum = self:GetHumanoid()
        if hum then
            self:SetSpeed(hum, self.Config.Speed or 100)
            self:SetupLogic1(player.Character)
            self:SmartCheck()
        end
        
        -- Listen for character respawn
        self:AddConnection("charAdded", player.CharacterAdded:Connect(function(char)
            SmartCheckRunning = false
            task.wait(0.5)
            if not self.Enabled then return end
            self:SetupLogic1(char)
            self:SmartCheck()
        end))
        
        -- Initial character check
        if player.Character then
            self:SetupLogic1(player.Character)
            self:SmartCheck()
        end
    end
    
    function module:OnDisable()
        SmartCheckRunning = false
        MetaHookInstalled = false
        
        -- Reset walkspeed to default (16)
        local hum = self:GetHumanoid()
        if hum then
            pcall(function() hum.WalkSpeed = 16 end)
        end
    end
    
    return module
end
