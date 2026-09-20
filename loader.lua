--===============================================================================
--  SC999 FRAMEWORK - MAIN LOADER v2.0
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

-- Safe loader: fetch → compile → execute (3-step for better error messages)
local function safeLoad(url, name)
    -- Step 1: Fetch
    local fetchOk, source = pcall(function()
        return game:HttpGet(url .. "?v=" .. tostring(os.time()), true)
    end)
    if not fetchOk or not source or #source == 0 then
        local err = name .. ": Fetch failed (" .. tostring(source) .. ")"
        table.insert(loadErrors, err)
        warn("[SC999] " .. err)
        return false, nil
    end

    -- Step 2: Compile
    local compiled, compileErr = loadstring(source, name)
    if not compiled then
        local err = name .. ": Syntax Error (" .. tostring(compileErr) .. ")"
        table.insert(loadErrors, err)
        warn("[SC999] " .. err)
        return false, nil
    end

    -- Step 3: Execute
    local execOk, result = pcall(compiled)
    if not execOk then
        local err = name .. ": Runtime Error (" .. tostring(result) .. ")"
        table.insert(loadErrors, err)
        warn("[SC999] " .. err)
        return false, nil
    end

    return true, result
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

-- Step 2: Initialize core (creates GUI with tabs)
SC999.Init()

-- Step 3: Module list
local modules = {
    {name = "Walkspeed",     path = "/src/modules/walkspeed.lua"},
    {name = "Noclip",        path = "/src/modules/noclip.lua"},
    {name = "InfJump",       path = "/src/modules/infjump.lua"},
    {name = "AntiAFK",       path = "/src/modules/antiafk.lua"},
    {name = "Daylight",      path = "/src/modules/daylight.lua"},
    {name = "InfiniteYield", path = "/src/modules/infiniteyield.lua"},
    {name = "AKADMIN",       path = "/src/modules/akadmin.lua"},
    {name = "SniperArena",   path = "/src/modules/sniperarena.lua"},
    {name = "Talentless",    path = "/src/modules/talentless.lua"},
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
    task.wait(0.05)
end

-- Step 5: Auto-enable modules with AutoEnable flag
SC999.ModuleRegistry.EnableAll()

-- Step 6: Update Home tab module count
if SC999.UpdateHomeModuleCount then
    SC999.UpdateHomeModuleCount()
end

-- Summary
print("\n========================================")
print("  SC999 FRAMEWORK v2.0 READY")
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
