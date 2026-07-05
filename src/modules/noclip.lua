--===============================================================================
--  MODULE: Noclip (Stepped Loop)
--  Desc: Efficient conditional noclip using RunService.Stepped
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    local Services = SC999.Services
    local player = Services.Players.LocalPlayer
    
    local module = SC999.CreateModule("Noclip", {
        DisplayName = "Noclip",
        Category = "Movement",
        HasToggle = true,
        AutoEnable = false,
    })
    
    --============================================================================
    --  CORE FUNCTIONS
    --============================================================================
    
    function module:OnEnable()
        self:AddConnection("steppedNoclip", Services.RunService.Stepped:Connect(function()
            if not self.Enabled then return end
            
            local char = player.Character
            if not char then return end
            
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end))
    end
    
    function module:OnDisable()
        -- Re-enable collision for all character parts
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    -- Only re-enable for body parts, not accessories
                    if part.Parent == char or part.Parent:IsA("Accessory") == false then
                        if part.Name == "Head" or part.Name == "Torso" or 
                           part.Name == "Left Arm" or part.Name == "Right Arm" or
                           part.Name == "Left Leg" or part.Name == "Right Leg" or
                           part.Name == "UpperTorso" or part.Name == "LowerTorso" or
                           part.Name == "LeftFoot" or part.Name == "LeftHand" or
                           part.Name == "LeftLowerArm" or part.Name == "LeftUpperArm" or
                           part.Name == "RightFoot" or part.Name == "RightHand" or
                           part.Name == "RightLowerArm" or part.Name == "RightUpperArm" or
                           part.Name == "LeftLowerLeg" or part.Name == "LeftUpperLeg" or
                           part.Name == "RightLowerLeg" or part.Name == "RightUpperLeg" or
                           part.Name == "HumanoidRootPart" then
                            pcall(function() part.CanCollide = true end)
                        end
                    end
                end
            end
        end
    end
    
    return module
end
