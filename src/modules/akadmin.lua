--===============================================================================
--  MODULE: AK ADMIN
--  Desc: One-click loader for AK ADMIN script
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    
    local module = SC999.CreateModule("AKADMIN", {
        DisplayName = "AK ADMIN",
        Category = "External Scripts",
        HasToggle = false,
        ActionButton = {
            Label = "Load AK ADMIN",
            Color = Color3.fromRGB(175, 82, 222),
            OnClick = function(mod)
                mod:Execute()
            end,
        },
    })
    
    --============================================================================
    --  CORE
    --============================================================================
    
    local URL = "https://absent.wtf/AKADMIN.lua"
    local Loaded = false
    
    function module:Execute()
        if Loaded then
            Util.Notify("AK ADMIN", "Already loaded!")
            return
        end
        
        Util.Notify("AK ADMIN", "Loading...")
        
        local success = SC999.Execute(URL, "AK ADMIN")
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
