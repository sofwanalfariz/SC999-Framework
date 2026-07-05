--===============================================================================
--  MODULE: Sniper Arena Hub
--  Desc: One-click loader for Sniper Arena Hub
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    
    local module = SC999.CreateModule("SniperArena", {
        DisplayName = "Sniper Arena Hub",
        Category = "External Scripts",
        HasToggle = false,
        ActionButton = {
            Label = "Load Sniper Arena",
            Color = Color3.fromRGB(255, 59, 48),
            OnClick = function(mod)
                mod:Execute()
            end,
        },
    })
    
    --============================================================================
    --  CORE
    --============================================================================
    
    local URL = "https://raw.githubusercontent.com/polo242c/sniper-arena/main/snpar"
    local Loaded = false
    
    function module:Execute()
        if Loaded then
            Util.Notify("Sniper Arena", "Already loaded!")
            return
        end
        
        Util.Notify("Sniper Arena", "Loading...")
        
        local success = SC999.Execute(URL, "Sniper Arena Hub")
        if success then
            Loaded = true
            self:SetConfig("Loaded", true)
        end
    end
    
    function module:OnEnable()
        if not Loaded then
            self:Execute()
        end
    end
    
    return module
end
