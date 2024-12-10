local isMenuOpen = false
local currentBugReport = {
    stage = nil,
    data = {}
}


local function DebugPrint(...)
    if Config.Debug then
        print(string.format('[AI-Support] %s', ...))
    end
end


CreateThread(function()
    
    RegisterCommand(Config.Command, function()
        ToggleSupport()
    end, false)
    
    
    if Config.EnableKeyMapping then
        RegisterKeyMapping(Config.Command, Config.Locale.command_desc, 'keyboard', Config.Key)
    end
end)


function ToggleSupport()
    if not isMenuOpen then
        OpenSupport()
    else
        CloseSupport()
    end
end


function OpenSupport()
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'show'
    })
end


function CloseSupport()
    isMenuOpen = false
    SetNuiFocus(false, false)
end


RegisterNUICallback('closeSupport', function(data, cb)
    CloseSupport()
    cb('ok')
end)

RegisterNUICallback('handleMessage', function(data, cb)
    local message = data.message
    ProcessMessage(message)
    cb('ok')
end)


function ProcessMessage(message)
    DebugPrint('Processing message:', message)
    
    
    if HandleBugReport(message) then
        return
    end
    
    
    TriggerServerEvent('ai-support:handleMessage', message, nil, {})
end


function HandleBugReport(message)
    local lowerMsg = string.lower(message)
    
    
    local bugKeywords = {
        "bug", "issue", "problem", "error", "broken", "not working", "doesn't work",
        "glitch", "wrong", "incorrect", "fail"
    }
    
    
    local actionWords = {
        "report", "found", "have", "got", "submit", "tell", "inform", "notify",
        "there's", "theres", "there is", "experiencing", "noticed", "seeing"
    }
    
    
    if lowerMsg == 'cancel' then
        currentBugReport = { stage = nil, data = {} }
        TriggerServerEvent('ai-support:handleMessage', "Bug report cancelled.", nil, {})
        return true
    end

    
    if not currentBugReport.stage then
        
        local hasBugKeyword = false
        local hasActionWord = false
        
        
        for _, keyword in ipairs(bugKeywords) do
            if lowerMsg:find(keyword) then
                hasBugKeyword = true
                break
            end
        end
        
        
        for _, word in ipairs(actionWords) do
            if lowerMsg:find(word) then
                hasActionWord = true
                break
            end
        end
        
        
        if hasBugKeyword and hasActionWord or 
           lowerMsg:find("bug%s+report") or 
           lowerMsg:find("report%s+bug") then
            currentBugReport.stage = 'category'
            TriggerServerEvent('ai-support:startBugReport')
            return true
        end
    end

    
    if currentBugReport.stage then
        currentBugReport.data[currentBugReport.stage] = message
        TriggerServerEvent('ai-support:handleMessage', message, currentBugReport.stage, currentBugReport.data)
        return true
    end

    return false
end


RegisterNetEvent('ai-support:receiveResponse')
AddEventHandler('ai-support:receiveResponse', function(response)
    DebugPrint('Received response:', response)
    if response then
        SendNUIMessage({
            type = 'addBotMessage',
            message = response
        })
    else
        SendNUIMessage({
            type = 'addBotMessage',
            message = "Sorry, I couldn't process your request. Please try again."
        })
    end
end)


RegisterNetEvent('ai-support:updateStage')
AddEventHandler('ai-support:updateStage', function(newStage)
    DebugPrint('Updating stage to:', newStage)
    if newStage == 'complete' then
        
        currentBugReport = { stage = nil, data = {} }
    elseif newStage then
        
        currentBugReport.stage = newStage
    end
end)


RegisterNetEvent('ai-support:notify')
AddEventHandler('ai-support:notify', function(message)
    SendNUIMessage({
        type = 'notification',
        message = message
    })
end)


RegisterNetEvent('ai-support:setWaypoint')
AddEventHandler('ai-support:setWaypoint', function(location)
    if not location then return end
    
    
    if Config.Debug then
        print('[AI-Support] Attempting to set waypoint for:', location)
    end
    
    local success = SetWaypointToLocation(location)
    
    
    TriggerServerEvent('ai-support:waypointResult', location, success)
    
    if success then
        SendNUIMessage({
            type = 'notification',
            message = 'Waypoint set: ' .. location
        })
    else
        SendNUIMessage({
            type = 'notification',
            message = "Couldn't find location: " .. location
        })
    end
end)


RegisterNUICallback('saveChatMessage', function(data, cb)
    TriggerServerEvent('ai-support:saveChatHistory', data)
    cb('ok')
end)

RegisterNUICallback('requestChatHistory', function(data, cb)
    TriggerServerEvent('ai-support:requestChatHistory')
    cb('ok')
end)


RegisterNetEvent('ai-support:receiveChatHistory')
AddEventHandler('ai-support:receiveChatHistory', function(history)
    SendNUIMessage({
        type = 'chatHistory',
        messages = history
    })
end)



RegisterNUICallback('clearChat', function(data, cb)
    TriggerServerEvent('ai-support:clearChat')
    cb('ok')
end)

RegisterNUICallback('clearContext', function(data, cb)
    TriggerServerEvent('ai-support:clearContext')
    cb('ok')
end)


RegisterNUICallback('copyToClipboard', function(data, cb)
    if data.text then
        SendNUIMessage({
            type = 'copy',
            text = data.text
        })
    end
    cb('ok')
end)


RegisterNUICallback('getConfig', function(data, cb)
    TriggerServerEvent('ai-support:getConfig')
    cb('ok')
end)


RegisterNetEvent('ai-support:sendConfig')
AddEventHandler('ai-support:sendConfig', function(config)
    SendNUIMessage({
        type = 'setConfig',
        config = config
    })
end)


RegisterNetEvent('ai-support:clearContext')
AddEventHandler('ai-support:clearContext', function()
    
    currentBugReport = { stage = nil, data = {} }
    
    
    SendNUIMessage({
        type = 'notification',
        message = 'Context cleared'
    })
    
    
    SendNUIMessage({
        type = 'clearChat'
    })
end) 