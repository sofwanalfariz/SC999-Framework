--===============================================================================
--  SC999 FRAMEWORK - MAIN LOADER
--  One-click loader: All modules auto-loaded from GitHub
--  Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/Biasaemail/SC999-Framework/main/loader.lua"))()
--  GitHub: https://github.com/Biasaemail/SC999-Framework
--===============================================================================

local GITHUB_BASE = "https://raw.githubusercontent.com/Biasaemail/SC999-Framework/main"

-- Prevent double load
if getgenv().SC999_FrameworkLoaded then
    warn("[SC999] Already loaded!")
    return
end

-- Error tracking
local loadErrors = {}

-- Safe loader function
local function safeLoad(url, name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if not success then
        table.insert(loadErrors, name .. ": " .. tostring(result))
        warn("[SC999] Failed to load " .. name .. ": " .. tostring(result))
    end
    return success, result
end

-- Step 1: Load Core Framework
print("[SC999] Loading core framework...")
local coreSuccess, SC999 = safeLoad(GITHUB_BASE .. "/src/core/SC999.lua", "Core")

if not coreSuccess or not SC999 then
    warn("[SC999] CRITICAL: Failed to load core framework!")
    for _, err in ipairs(loadErrors) do
        warn("  - " .. err)
    end
    return
end

-- Step 2: Initialize core
SC999.Init()

-- Step 3: Module list
local modules = {
    {name = "Walkspeed", path = "/src/modules/walkspeed.lua"},
    {name = "Noclip", path = "/src/modules/noclip.lua"},
    {name = "InfJump", path = "/src/modules/infjump.lua"},
    {name = "AntiAFK", path = "/src/modules/antiafk.lua"},
    {name = "Daylight", path = "/src/modules/daylight.lua"},
    {name = "InfiniteYield", path = "/src/modules/infiniteyield.lua"},
    {name = "AKADMIN", path = "/src/modules/akadmin.lua"},
    {name = "SniperArena", path = "/src/modules/sniperarena.lua"},
    {name = "Talentless", path = "/src/modules/talentless.lua"},
}

-- Step 4: Load all modules
print("[SC999] Loading modules...")
for _, mod in ipairs(modules) do
    local url = GITHUB_BASE .. mod.path
    local success, loader = safeLoad(url, mod.name)
    
    if success and loader and type(loader) == "function" then
        local modSuccess, result = pcall(function()
            return loader(SC999)
        end)
        if modSuccess and result then
            print("[SC999] Module loaded: " .. mod.name)
        else
            table.insert(loadErrors, mod.name .. " init: " .. tostring(result))
        end
    end
    task.wait(0.05) -- Small delay between loads
end

-- Step 5: Auto-enable modules with AutoEnable flag
SC999.ModuleRegistry.EnableAll()

-- Summary
print("\n========================================")
print("  SC999 FRAMEWORK v1.0 READY")
print("  Modules loaded: " .. tostring(#modules - #loadErrors) .. "/" .. tostring(#modules))
if #loadErrors > 0 then
    print("  Errors:")
    for _, err in ipairs(loadErrors) do
        print("    - " .. err)
    end
end
print("========================================")

-- Global access
getgenv().SC999 = SC999
