--===============================================================================
--  MODULE: Infinite Jump
--  Desc: Event-based infinite jump system
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    local Services = SC999.Services
    local player = Services.Players.LocalPlayer
    
    local module = SC999.CreateModule("InfJump", {
        DisplayName = "Infinite Jump",
        Category = "Movement",
        HasToggle = true,
        AutoEnable = true,
    })
    
    --============================================================================
    --  CORE FUNCTIONS
    --============================================================================
    
    function module:OnEnable()
        self:AddConnection("infJump", Services.UIS.JumpRequest:Connect(function()
            if not self.Enabled then return end
            
            local char = player.Character
            if not char then return end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
        end))
    end
    
    function module:OnDisable()
        -- Connections auto-cleanup via ModuleBase
    end
    
    return module
end
