warn("[DEBUG] [Abysall Loader] Script execution started.")

if Abysall then
    warn("[DEBUG] [Abysall Loader] ⚠️ Abysall table already exists in global environment! Aborting execution to prevent duplicate loads.")
    return 
end

warn("[DEBUG] [Abysall Loader] Initializing initial stub `getgenv().Abysall`...")
getgenv().Abysall = {
    Legit = true
}
warn("[DEBUG] [Abysall Loader] Initial stub created successfully. Abysall exists:", tostring(Abysall ~= nil))

local GameList = {
  [2440500124] = "Doors"
}
warn("[DEBUG] [Abysall Loader] GameList table configured. Current PlaceId:", tostring(game.PlaceId), "| GameId:", tostring(game.GameId))

local BaseUrl = "https://raw.githubusercontent.com/weradof/tuff/refs/heads/main"
warn("[DEBUG] [Abysall Loader] BaseUrl set to: " .. tostring(BaseUrl))

warn("[DEBUG] [Abysall Loader] Beginning remote component loading phase via HttpGet & loadstring...")

local function SafeHttpGetLoad(url, componentName)
    warn("[DEBUG] [Abysall Loader] 🌐 Fetching component [" .. componentName .. "] from URL: " .. tostring(url))
    local startTime = tick()
    local successHttp, httpResult = pcall(function()
        return game:HttpGet(url)
    end)
    local elapsedHttp = tick() - startTime
    
    if not successHttp then
        warn("[DEBUG] [Abysall Loader] ❌ HTTP GET FAILED for [" .. componentName .. "] after " .. string.format("%.3f", elapsedHttp) .. "s. Error: " .. tostring(httpResult))
        error("Failed to HTTP GET " .. componentName .. ": " .. tostring(httpResult))
    end
    warn("[DEBUG] [Abysall Loader] ✅ HTTP GET SUCCESS for [" .. componentName .. "] in " .. string.format("%.3f", elapsedHttp) .. "s (Size: " .. tostring(#httpResult) .. " bytes)")

    local startTimeLoad = tick()
    local successLoad, loadResult = pcall(function()
        return loadstring(httpResult)
    end)
    local elapsedLoad = tick() - startTimeLoad

    if not successLoad or type(loadResult) ~= "function" then
        warn("[DEBUG] [Abysall Loader] ❌ LOADSTRING FAILED or returned non-function for [" .. componentName .. "] after " .. string.format("%.3f", elapsedLoad) .. "s. Result: " .. tostring(loadResult))
        error("Failed to loadstring " .. componentName .. ": " .. tostring(loadResult))
    end
    warn("[DEBUG] [Abysall Loader] ✅ LOADSTRING SUCCESS for [" .. componentName .. "] in " .. string.format("%.3f", elapsedLoad) .. "s. Executing chunk...")

    local startTimeExec = tick()
    local successExec, execResult = pcall(loadResult)
    local elapsedExec = tick() - startTimeExec

    if not successExec then
        warn("[DEBUG] [Abysall Loader] ❌ CHUNK EXECUTION FAILED for [" .. componentName .. "] after " .. string.format("%.3f", elapsedExec) .. "s. Error: " .. tostring(execResult))
        error("Failed executing component " .. componentName .. ": " .. tostring(execResult))
    end
    warn("[DEBUG] [Abysall Loader] ✅ COMPONENT READY [" .. componentName .. "] initialized successfully in " .. string.format("%.3f", elapsedExec) .. "s (Returned type: " .. type(execResult) .. ")")

    return execResult
end

warn("[DEBUG] [Abysall Loader] Loading Environment component...")
local envResult = SafeHttpGetLoad(BaseUrl .. "Components/Environment.luau", "Environment")

warn("[DEBUG] [Abysall Loader] Loading ESP component...")
local espResult = SafeHttpGetLoad(BaseUrl .. "Components/ESP.luau", "ESPLibrary")

getgenv().Abysall = {
    Environment = envResult,
    ESPLibrary = espResult,
    Legit = true, -- pog
}
warn("[DEBUG] [Abysall Loader] getgenv().Abysall fully populated with Environment and ESPLibrary.")

local function CloneReference(Object)
    warn("[DEBUG] [CloneReference] Called for object: " .. tostring(Object) .. " (ClassName: " .. tostring(pcall(function() return Object.ClassName end) and Object.ClassName or "Unknown") .. ")")
    if Abysall and Abysall.Environment and Abysall.Environment.cloneref then
        warn("[DEBUG] [CloneReference] Abysall.Environment.cloneref is available. Invoking cloneref...")
        local success, cloned = pcall(function()
            return Abysall.Environment.cloneref(Object)
        end)
        if success then
            warn("[DEBUG] [CloneReference] ✅ Successfully cloned reference. Original:", tostring(Object), "| Cloned:", tostring(cloned))
            return cloned
        else
            warn("[DEBUG] [CloneReference] ❌ cloneref threw error: " .. tostring(cloned) .. ". Falling back to original object.")
            return Object
        end
    else
        warn("[DEBUG] [CloneReference] ⚠️ Abysall.Environment.cloneref not available. Returning original object.")
        return Object
    end
end

local Services = setmetatable({}, {
    __index = function(self, Name)
        warn("[DEBUG] [Services Index] Requested service: " .. tostring(Name))
        local getServiceSuccess, serviceObj = pcall(function()
            return game:GetService(Name)
        end)
        if not getServiceSuccess then
            warn("[DEBUG] [Services Index] ❌ Failed to get service [" .. tostring(Name) .. "]: " .. tostring(serviceObj))
            error("Failed to get service " .. tostring(Name) .. ": " .. tostring(serviceObj))
        end
        warn("[DEBUG] [Services Index] ✅ Retrieved service [" .. tostring(Name) .. "]. Passing to CloneReference...")
        return CloneReference(serviceObj)
    end
})
warn("[DEBUG] [Abysall Loader] Services metatable proxy created successfully.")

warn("[DEBUG] [Abysall Loader] Checking file system capabilities for UserData.json...")
if Abysall.Environment.writefile and Abysall.Environment.readfile then
    warn("[DEBUG] [UserData] writefile and readfile functions are available.")
    local filePath = "Abysall/UserData.json"
    
    local hasFileCheck, isFileExists = pcall(function()
        return Abysall.Environment.isfile(filePath)
    end)
    
    if not hasFileCheck then
        warn("[DEBUG] [UserData] ❌ Error checking if file exists: " .. tostring(isFileExists))
        isFileExists = false
    else
        warn("[DEBUG] [UserData] File existence check for '" .. filePath .. "': " .. tostring(isFileExists))
    end

    if not isFileExists then
        warn("[DEBUG] [UserData] UserData.json does not exist. Creating default data structure...")
        local Data = {
            TotalExecutions = 0,
            UILibrary = "Obsidian"
        }
        
        local encodeSuccess, encodeErr = pcall(function()
            return Services.HttpService:JSONEncode(Data)
        end)
        local encodedData = encodeSuccess and encodeErr or '{"TotalExecutions":0,"UILibrary":"Obsidian"}'
        if not encodeSuccess then
            warn("[DEBUG] [UserData] ❌ Failed to JSONEncode default UserData: " .. tostring(encodeErr))
        end

        local writeSuccess, writeErr = pcall(function()
            Abysall.Environment.writefile(filePath, encodedData)
        end)
        if writeSuccess then
            warn("[DEBUG] [UserData] ✅ Successfully wrote default UserData.json to disk.")
        else
            warn("[DEBUG] [UserData] ❌ Failed to writefile UserData.json: " .. tostring(writeErr))
        end
    end

    warn("[DEBUG] [UserData] Reading UserData.json from disk...")
    local readSuccess, readResult = pcall(function()
        return Abysall.Environment.readfile(filePath)
    end)

    if not readSuccess then
        warn("[DEBUG] [UserData] ❌ Failed to readfile UserData.json: " .. tostring(readResult))
    else
        warn("[DEBUG] [UserData] ✅ Successfully read UserData.json (Length: " .. tostring(#readResult) .. " bytes). Decoding JSON...")
        local decodeSuccess, decodedResult = pcall(function()
            return Services.HttpService:JSONDecode(readResult)
        end)

        if not decodeSuccess or type(decodedResult) ~= "table" then
            warn("[DEBUG] [UserData] ❌ Failed to JSONDecode UserData or result is not a table: " .. tostring(decodedResult))
            decodedResult = { TotalExecutions = 0, UILibrary = "Obsidian" }
        else
            warn("[DEBUG] [UserData] ✅ Successfully decoded UserData JSON.")
        end

        if not decodedResult.TotalExecutions then
            warn("[DEBUG] [UserData] TotalExecutions missing in decoded data. Initializing to 0.")
            decodedResult.TotalExecutions = 0    
        end

        local oldExecutions = decodedResult.TotalExecutions
        decodedResult.TotalExecutions = decodedResult.TotalExecutions + 1
        warn("[DEBUG] [UserData] Incrementing TotalExecutions: " .. tostring(oldExecutions) .. " -> " .. tostring(decodedResult.TotalExecutions))

        if not decodedResult.UILibrary then
            warn("[DEBUG] [UserData] UILibrary missing in decoded data. Setting default to 'Obsidian'.")
            decodedResult.UILibrary = "Obsidian"
        else
            warn("[DEBUG] [UserData] UILibrary currently set to: " .. tostring(decodedResult.UILibrary))
        end

        Abysall.TotalExecutions = decodedResult.TotalExecutions
        Abysall.UILibrary = decodedResult.UILibrary

        local reEncodeSuccess, reEncodeData = pcall(function()
            return Services.HttpService:JSONEncode(decodedResult)
        end)

        if reEncodeSuccess then
            local writeBackSuccess, writeBackErr = pcall(function()
                Abysall.Environment.writefile(filePath, reEncodeData)
            end)
            if writeBackSuccess then
                warn("[DEBUG] [UserData] ✅ Successfully wrote updated UserData.json back to disk.")
            else
                warn("[DEBUG] [UserData] ❌ Failed to write back updated UserData.json: " .. tostring(writeBackErr))
            end
        else
            warn("[DEBUG] [UserData] ❌ Failed to re-encode updated UserData: " .. tostring(reEncodeData))
        end
    end
else
    warn("[DEBUG] [UserData] ⚠️ writefile or readfile environment functions are missing! Skipping UserData persistence handling.")
end

warn("[DEBUG] [Abysall Loader] Loading Interface component...")
Abysall.Interface = SafeHttpGetLoad(BaseUrl .. "Components/Interface.luau", "Interface")

warn("[DEBUG] [Abysall Loader] Loading Analytics component...")
Abysall.Analytics = SafeHttpGetLoad(BaseUrl .. "Components/Analytics.luau", "Analytics")

warn("[DEBUG] [Abysall Loader] Determining game loader route based on GameId (" .. tostring(game.GameId) .. ")...")
local CurrentGame = GameList[game.GameId]
if CurrentGame then
    warn("[DEBUG] [Abysall Loader] ✅ Game matched in GameList: [" .. tostring(CurrentGame) .. "] for GameId " .. tostring(game.GameId))
    local gameLoaderUrl = BaseUrl .. "Games/" .. CurrentGame .. "/Loader.luau"
    SafeHttpGetLoad(gameLoaderUrl, CurrentGame .. " Loader")
else
    warn("[DEBUG] [Abysall Loader] ℹ️ GameId " .. tostring(game.GameId) .. " not found in GameList. Falling back to Universal loader.")
    local universalLoaderUrl = BaseUrl .. "Games/Universal/Loader.luau"
    SafeHttpGetLoad(universalLoaderUrl, "Universal Loader")
end

warn("[DEBUG] [Abysall Loader] 🎉 Abysall script execution completed successfully!")
