--===============================================================================
--  MODULE: Infinite Yield FE
--  Desc: One-click loader for Infinite Yield admin script
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    
    local module = SC999.CreateModule("InfiniteYield", {
        DisplayName = "Infinite Yield FE",
        Category = "External Scripts",
        HasToggle = false,
        ActionButton = {
            Label = "Load Infinite Yield",
            Color = Color3.fromRGB(52, 199, 89),
            OnClick = function(mod)
                mod:Execute()
            end,
        },
    })
    
    --============================================================================
    --  CORE
    --============================================================================
    
    local URL = "https://rawscripts.net/raw/Universal-Script-Infinite-Yeild-FE-92170"
    local Loaded = false
    
    function module:Execute()
        if Loaded then
            Util.Notify("Infinite Yield", "Already loaded!")
            return
        end
        
        Util.Notify("Infinite Yield", "Loading...")
        
        local success = SC999.Execute(URL, "Infinite Yield FE")
        if success then
            Loaded = true
            self:SetConfig("Loaded", true)
        end
    end
    
    -- Allow re-load if explicitly requested
    function module:OnEnable()
        if not Loaded then
            self:Execute()
        end
    end
    
    return module
end
