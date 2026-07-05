--===============================================================================
--  MODULE: Talentless
--  Desc: One-click loader for Talentless script
--  Author: SC999 Framework
--===============================================================================

return function(SC999)
    local Util = SC999.Util
    
    local module = SC999.CreateModule("Talentless", {
        DisplayName = "Talentless",
        Category = "External Scripts",
        HasToggle = false,
        ActionButton = {
            Label = "Load Talentless",
            Color = Color3.fromRGB(255, 149, 0),
            OnClick = function(mod)
                mod:Execute()
            end,
        },
    })
    
    --============================================================================
    --  CORE
    --============================================================================
    
    local URL = "https://hellohellohell0.com/talentless-raw/TALENTLESS.lua"
    local Loaded = false
    
    function module:Execute()
        if Loaded then
            Util.Notify("Talentless", "Already loaded!")
            return
        end
        
        Util.Notify("Talentless", "Loading...")
        
        local success = pcall(function()
            loadstring(game:HttpGet(URL, true))()
        end)
        
        if success then
            Loaded = true
            self:SetConfig("Loaded", true)
            Util.Notify("SC999", "Talentless loaded successfully!")
        else
            warn("[SC999] Failed to execute Talentless")
            Util.Notify("SC999", "Failed to load Talentless")
        end
    end
    
    function module:OnEnable()
        if not Loaded then
            self:Execute()
        end
    end
    
    return module
end
