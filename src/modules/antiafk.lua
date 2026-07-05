--===============================================================================
--  MODULE: Anti-AFK
--  Desc: Prevents being kicked for idle/AFK
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    local Services = SC999.Services
    local player = Services.Players.LocalPlayer
    
    local module = SC999.CreateModule("AntiAFK", {
        DisplayName = "Anti-AFK",
        Category = "Utility",
        HasToggle = true,
        AutoEnable = true,
    })
    
    local lastAction = 0
    
    --============================================================================
    --  CORE FUNCTIONS
    --============================================================================
    
    function module:OnEnable()
        lastAction = 0
        
        self:AddConnection("antiAFK", player.Idled:Connect(function()
            if not self.Enabled then return end
            if tick() - lastAction < 3 then return end
            lastAction = tick()
            
            pcall(function()
                Services.VirtualUser:CaptureController()
                Services.VirtualUser:ClickButton2(Vector2.new())
            end)
        end))
    end
    
    function module:OnDisable()
        -- Connections auto-cleanup via ModuleBase
    end
    
    return module
end
