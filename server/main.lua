local function BuildFAQPrompt()
    if not Config.FAQ or #Config.FAQ == 0 then return "No FAQ entries available" end
    
    local faqText = "Common questions and answers:\n\n"
    for _, faq in ipairs(Config.FAQ) do
        faqText = faqText .. "Q: " .. faq.question .. "\nA: " .. faq.answer .. "\n\n"
    end
    
    return faqText .. [[
When users ask questions similar to these FAQ entries:
1. Use the FAQ knowledge as a base but personalize the response
2. Add relevant additional information from other server knowledge
3. Keep the helpful and friendly tone
4. If the question is very similar to an FAQ, start with "Here's what you need to know:"
]]
end

local function BuildRulesPrompt()
    if not Config.Rules then return "Rules system not configured" end
    
    local rulesText = "Server Rules:\n\n"
    
    
    for catId, category in pairs(Config.Rules.Categories) do
        rulesText = rulesText .. category.title .. ":\n"
        for _, rule in ipairs(category.rules) do
            rulesText = rulesText .. "- " .. rule .. "\n"
        end
        rulesText = rulesText .. "\n"
    end
    
    
    if Config.AIMemory.RulesDetail.ShowPunishments then
        rulesText = rulesText .. "Rule Violations and Consequences:\n"
        for _, violation in pairs(Config.Rules.Punishments.violations) do
            rulesText = rulesText .. "- " .. violation.name .. ":\n"
            if violation.first then rulesText = rulesText .. "  First: " .. Config.Rules.Punishments.levels[violation.first] .. "\n" end
            if violation.second then rulesText = rulesText .. "  Second: " .. Config.Rules.Punishments.levels[violation.second] .. "\n" end
            if violation.third then rulesText = rulesText .. "  Third: " .. Config.Rules.Punishments.levels[violation.third] .. "\n" end
        end
    end
    
    
    if Config.AIMemory.RulesDetail.ShowAppeals then
        rulesText = rulesText .. "\nAppeals Process:\n"
        for _, step in ipairs(Config.Rules.Appeals.process) do
            rulesText = rulesText .. "- " .. step .. "\n"
        end
    end
    
    return rulesText
end

local activeReports = {}
local geminiHistory = {}
local serverBlips = {}
local serverMemory = {}
local pendingWaypoints = {}


local function HandleLocationRequest(src, location)
    if not src or not location then 
        print('[AI-Support] Invalid source or location')
        return false 
    end
    
    
    local cleanLocation = location:gsub("^%s*(.-)%s*$", "%1")
    
    
    print('[AI-Support] Attempting to mark location:', cleanLocation)
    print('[AI-Support] Available locations:')
    for name, data in pairs(Config.ServerInfo.Locations) do
        print('  -', name, '(coords:', json.encode(data.coords), ')')
    end
    
    
    local locationData = Config.ServerInfo.Locations[cleanLocation]
    local foundName = cleanLocation
    
    
    if not locationData then
        print('[AI-Support] No exact match, trying case-insensitive match')
        for name, data in pairs(Config.ServerInfo.Locations) do
            local cleanName = name:gsub("%s+", ""):lower()
            local cleanSearch = cleanLocation:gsub("%s+", ""):lower()
            
            print('[AI-Support] Comparing:', cleanSearch, 'with:', cleanName)
            
            if cleanName == cleanSearch or 
               cleanName:find(cleanSearch, 1, true) or 
               cleanSearch:find(cleanName, 1, true) then
                locationData = data
                foundName = name
                print('[AI-Support] Found match:', name)
                break
            end
        end
    end
    
    
    if not locationData then
        print('[AI-Support] Location not found in config:', cleanLocation)
        return false
    end
    
    print('[AI-Support] Found location data for:', foundName)
    print('[AI-Support] Location data:', json.encode(locationData))
    
    
    pendingWaypoints[src] = {
        location = foundName,
        success = false,
        processed = false
    }
    
    
    TriggerClientEvent('ai-support:setWaypoint', src, foundName)
    
    
    local timeoutAt = GetGameTimer() + 1000
    while GetGameTimer() < timeoutAt do
        if pendingWaypoints[src] and pendingWaypoints[src].processed then
            local success = pendingWaypoints[src].success
            pendingWaypoints[src] = nil
            print('[AI-Support] Waypoint set result:', success)
            return success
        end
        Wait(0)
    end
    
    print('[AI-Support] Waypoint request timed out')
    pendingWaypoints[src] = nil
    return false
end


RegisterNetEvent('ai-support:waypointResult')
AddEventHandler('ai-support:waypointResult', function(location, success)
    local src = source
    if pendingWaypoints[src] and pendingWaypoints[src].location == location then
        pendingWaypoints[src].success = success
        pendingWaypoints[src].processed = true
    end
end)


local function InitializeServerMemory()
    if Config.AIMemory.EnableServerInfo then
        serverMemory.serverInfo = {
            name = Config.ServerInfo.Name,
            description = Config.ServerInfo.Description,
            maxSlots = Config.ServerInfo.MaxSlots,
            gameMode = Config.ServerInfo.GameMode,
            language = Config.ServerInfo.Language,
            features = Config.AIMemory.EnableFeatures and Config.ServerInfo.Features or nil,
            rules = Config.AIMemory.EnableRules and Config.ServerInfo.Rules or nil,
            locations = Config.AIMemory.EnableLocations and Config.ServerInfo.Locations or nil
        }
    end
end


CreateThread(function()

    print('^2[AI-Support]^7 - ^5Created By MT-Scripts^7')
    print('^2[AI-Support]^7 - ^5Join Discord For Support:^7 ^3https://discord.gg/r9SmWAJccD^7')
    print('^2[AI-Support]^7 - ^5Starting...^7')
    
    InitializeServerMemory()
    
    
    if Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
        PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
            if err == 200 or err == 204 then
                print('[AI-Support] Discord webhook verified successfully')
            else
                print('[AI-Support] Failed to verify Discord webhook. Error:', err)
                print('[AI-Support] Make sure your webhook URL is correct')
            end
        end, 'GET', '', { ['Content-Type'] = 'application/json' })
    else
        print('[AI-Support] Discord webhook not configured')
    end
end)


RegisterNetEvent('ai-support:startBugReport')
AddEventHandler('ai-support:startBugReport', function()
    local src = source
    activeReports[src] = {
        stage = 'category',
        data = {}
    }
    geminiHistory[src] = {}
    
    
    TriggerClientEvent('ai-support:receiveResponse', src, "Please select: Gameplay, Vehicle, Map, UI/HUD, Performance, Other")
end)


RegisterNetEvent('ai-support:handleMessage')
AddEventHandler('ai-support:handleMessage', function(message, stage, bugReport)
    local src = source
    
    
    if not geminiHistory[src] then
        geminiHistory[src] = {}
    end
    
    
    if stage and stage ~= 'complete' then
        if not activeReports[src] then
            activeReports[src] = { stage = stage, data = {} }
        end
        
        
        activeReports[src].data = bugReport 
        
        
        local stages = {
            category = function(msg)
                local validCategory = false
                for _, cat in ipairs(Config.BugCategories) do
                    if string.lower(msg) == string.lower(cat) then
                        validCategory = true
                        break
                    end
                end
                if validCategory then
                    TriggerClientEvent('ai-support:receiveResponse', src, "Please describe the bug you encountered. Make sure to enter atleast 10 characters.")
                    return 'description'
                end
                TriggerClientEvent('ai-support:receiveResponse', src, "Please select: Gameplay, Vehicle, Map, UI/HUD, Performance, Other")
                return 'category'
            end,
            description = function(msg)
                if string.len(msg) >= 5 then
                    TriggerClientEvent('ai-support:receiveResponse', src, "What steps can someone take to reproduce this bug?")
                    return 'steps'
                end
                TriggerClientEvent('ai-support:receiveResponse', src, "Please describe the bug you encountered. Make sure to enter atleast 10 characters.")
                return stage 
            end,
            steps = function(msg)
                if string.len(msg) >= 5 then
                    TriggerClientEvent('ai-support:receiveResponse', src, "Is there any additional information you'd like to add?")
                    return 'additionalInfo'
                end
                TriggerClientEvent('ai-support:receiveResponse', src, "What steps can someone take to reproduce this bug?")
                return stage 
            end,
            additionalInfo = function(msg)
                TriggerClientEvent('ai-support:receiveResponse', src, "Would you like to submit this bug report? Type 'yes' to submit or 'cancel' to abort.")
                return 'confirm'
            end,
            confirm = function(msg)
                local lowerMsg = string.lower(msg)
                if lowerMsg == 'yes' then
                    CreateBugReport(src, activeReports[src].data)
                    
                    activeReports[src] = nil
                    
                    TriggerClientEvent('ai-support:receiveResponse', src, "Bug report submitted successfully! How else can I help you?")
                    TriggerClientEvent('ai-support:updateStage', src, 'complete')
                    
                    table.insert(geminiHistory[src], {
                        role = "assistant",
                        parts = {{ text = "How else can I help you?" }}
                    })
                    return 'complete'
                elseif lowerMsg == 'cancel' then
                    
                    activeReports[src] = nil
                    
                    TriggerClientEvent('ai-support:receiveResponse', src, "Bug report cancelled. Is there anything else I can help you with?")
                    TriggerClientEvent('ai-support:updateStage', src, 'complete')
                    
                    table.insert(geminiHistory[src], {
                        role = "assistant",
                        parts = {{ text = "How can I help you?" }}
                    })
                    return 'complete'
                else
                    
                    TriggerClientEvent('ai-support:receiveResponse', src, "Would you like to submit this bug report? Type 'yes' to submit or 'cancel' to abort.")
                    return 'confirm'
                end
            end
        }
        
        
        if stages[stage] then
            local nextStage = stages[stage](message)
            if nextStage and nextStage ~= stage then
                activeReports[src].stage = nextStage
                TriggerClientEvent('ai-support:updateStage', src, nextStage)
            end
            return 
        end
    else
        
        table.insert(geminiHistory[src], {
            role = "user",
            parts = {{ text = message }}
        })
        
        
        local context = {
            rules = Config.Rules,
            locations = Config.ServerInfo.Locations,
            bugCategories = Config.BugCategories,
            currentStage = nil,
            bugReport = nil,
            serverInfo = serverMemory.serverInfo,
            AIMemory = Config.AIMemory
        }
        
        GetGeminiResponse(src, message, context, geminiHistory[src])
    end
end)


function GetGeminiResponse(src, message, context, history)
    
    local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    local headers = {
        ['Content-Type'] = 'application/json',
        ['x-goog-api-key'] = Config.GeminiApiKey
    }

    
    local systemPrompt = [[
You are an AI support assistant for a FiveM roleplay server.

Server Information:
Server Name: ]] .. (context.serverInfo and context.serverInfo.name or "Unknown") .. [[
Server Description: ]] .. (context.serverInfo and context.serverInfo.description or "Not provided") .. [[
Max Players: ]] .. (context.serverInfo and context.serverInfo.maxSlots or "Unknown") .. [[

FAQ Knowledge Base:
]] .. (Config.AIMemory.EnableFAQ and BuildFAQPrompt() or "FAQ system disabled") .. [[

Server Rules and Guidelines:
]] .. (Config.AIMemory.EnableRules and BuildRulesPrompt() or "Rules system disabled") .. [[

For bug reports:
- Detect ANY mention of bugs, issues, or problems that need reporting
- Common patterns include but are not limited to:
  - Reporting bugs/issues
  - Finding bugs/issues
  - Having problems
  - Something not working
  - Need to report something
- When detected, ALWAYS respond with the category selection prompt
- DO NOT require exact phrases

EXACT responses for bug reports:
IF user mentions ANY bug/issue/problem they want to report:
  "Please select: Gameplay, Vehicle, Map, UI/HUD, Performance, Other"

IF stage is 'category' AND message is NOT "report bug" AND message is NOT one of [Gameplay, Vehicle, Map, UI/HUD, Performance, Other]:
  "Please select: Gameplay, Vehicle, Map, UI/HUD, Performance, Other"

IF stage is 'category' AND message IS one of [Gameplay, Vehicle, Map, UI/HUD, Performance, Other]:
  "Please describe the bug you encountered. Make sure to enter atleast 10 characters."

IF stage is 'description' AND message length >= 5:
  "What steps can someone take to reproduce this bug?"

IF stage is 'steps' AND message length >= 5:
  "Is there any additional information you'd like to add?"

IF stage is 'additionalInfo':
  "Would you like to submit this bug report? Type 'yes' to submit or 'cancel' to abort."

IF stage is 'confirm' AND message is NOT 'yes' AND message is NOT 'cancel':
  "Would you like to submit this bug report? Type 'yes' to submit or 'cancel' to abort."

Critical rules:
1. Use EXACTLY the response text shown above - no modifications
2. NEVER show more than one prompt
3. NEVER add extra text or explanations
4. NEVER acknowledge previous inputs
5. NEVER preview next steps
6. For non-bug report questions, provide helpful responses

Remember:
- Never share restricted information: ]] .. table.concat(Config.RestrictedInfo, ", ") .. [[
- Be helpful but maintain server security
- During bug reports, use ONLY the exact responses shown above

Important location instructions:
- Available locations (use EXACT names, case-sensitive):
]] .. (function()
    local locationList = ""
    for name, _ in pairs(Config.ServerInfo.Locations) do
        locationList = locationList .. "  - " .. name .. "\n"
    end
    return locationList
end)() .. [[
- When marking a location, use EXACTLY: !SETMARK{Location Name}!
- ONLY mark the specific location the user asks about
- ALWAYS preserve spaces and exact capitalization
- Example responses:
  User: "Where is the Airport?"
  Response: "The Airport is in the south. Let me mark it: !SETMARK{Airport}!"
  
  User: "How do I get to the Police Station?"
  Response: "The Police Station is downtown. I'll mark it for you: !SETMARK{Police Station}!"

- DO NOT mark multiple locations unless specifically asked
- DO NOT mark related nearby locations unless asked
- ONLY mark what the user explicitly asks about

Response Guidelines:
1. Keep responses clear and concise
2. Use markdown formatting for better readability
3. When answering rule-related questions, cite specific rules
4. For FAQ questions, provide comprehensive answers
5. Always maintain a helpful and friendly tone
]]

    
    local conversationHistory = ""
    for _, msg in ipairs(history) do
        conversationHistory = conversationHistory .. "\n" .. msg.role .. ": " .. msg.parts[1].text
    end
    
    
    local body = {
        contents = {
            {
                role = "user",
                parts = {{ text = systemPrompt .. "\n\nConversation history:" .. conversationHistory .. "\n\nUser message: " .. message }}
            }
        },
        generationConfig = {
            temperature = 0.7,
            topP = 0.8,
            topK = 40,
            maxOutputTokens = 1024,
        }
    }

    print('[AI-Support] Making request to Gemini API') 
    
    
    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
        print('[AI-Support] Received response from Gemini API:', errorCode) 
        
        if errorCode == 200 then
            local result = json.decode(resultData)
            if result and result.candidates and result.candidates[1] and result.candidates[1].content then
                local response = result.candidates[1].content.parts[1].text
                
                
                local locationMarked = false
                
                
                local location = response:match("!SETMARK{(.-)}!")
                if location then
                    local success = HandleLocationRequest(src, location)
                    locationMarked = success
                    
                    print('[AI-Support] Location mark attempt:', location, success)
                end
                
                
                response = response:gsub("!SETMARK{.-}!", "")
                
                
                if locationMarked then
                    response = response .. "\n\nI've marked the location on your map."
                end
                
                
                response = FormatResponse(response)
                TriggerClientEvent('ai-support:receiveResponse', src, response)
                
                
                table.insert(geminiHistory[src], {
                    role = "assistant",
                    parts = {{ text = response }}
                })
            else
                print('[AI-Support] Invalid response format')
                TriggerClientEvent('ai-support:receiveResponse', src, "I apologize, but I'm having trouble processing your request.\n\nCould you please rephrase that or provide more details?")
            end
        else
            print('[AI-Support] API Error:', errorCode, resultData)
            TriggerClientEvent('ai-support:receiveResponse', src, "I encountered an error processing your request.\n\nCould you please try asking your question again?")
        end
    end, 'POST', json.encode(body), headers)
end


function FormatResponse(text)
    if not text then return "" end
    
    
    text = text:gsub("%*%*(.-)%*%*", "%1") 
    text = text:gsub("%*(.-)%*", "%1")     
    text = text:gsub("_(.-)_", "%1")       
    text = text:gsub("<li>", "-")           
    text = text:gsub("</li>", "")          
    text = text:gsub("•%s+", "")           
    text = text:gsub("%-%s+", "")          
    text = text:gsub("%*%s+", "")          
    text = text:gsub("Stage:%s+", "")      
    text = text:gsub("Current stage:%s+", "") 
    
    
    text = text:gsub('%. ', '.\n\n')
    text = text:gsub('%! ', '!\n\n')
    text = text:gsub('%? ', '?\n\n')
    
    
    text = text:gsub('(Current)', '\n%1')
    text = text:gsub('(Summary)', '\n%1')
    
    
    text = text:gsub('\n\n\n+', '\n\n')
    
    
    text = text:gsub('^%s+', ''):gsub('%s+$', '')
    
    return text
end


RegisterNetEvent('ai-support:submitBugReport')
AddEventHandler('ai-support:submitBugReport', function(reportData)
    local src = source
    
    
    if Config.DiscordWebhook ~= '' then
        local embed = {
            title = "New Bug Report",
            color = 15158332,
            fields = {
                {
                    name = "Category",
                    value = reportData.category,
                    inline = true
                },
                {
                    name = "Description",
                    value = reportData.description
                },
                {
                    name = "Steps to Reproduce",
                    value = reportData.steps
                },
                {
                    name = "Reported By",
                    value = GetPlayerName(src),
                    inline = true
                },
                {
                    name = "Time",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = true
                }
            }
        }
        
        
        PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
            username = "Bug Report Bot",
            embeds = { embed }
        }), { ['Content-Type'] = 'application/json' })
    end
    
    
    activeReports[src] = nil
    geminiHistory[src] = nil
end)


AddEventHandler('playerDropped', function()
    local src = source
    activeReports[src] = nil
    geminiHistory[src] = nil
end)


function CreateBugReport(src, reportData, callback)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then
        print('[AI-Support] Discord webhook not configured')
        if callback then callback(false) end
        return
    end

    local player = GetPlayerName(src) or "Unknown"
    local identifier = GetPlayerIdentifier(src, 0) or "Unknown"
    
    
    print('[AI-Support] Creating bug report with data:', json.encode(reportData))
    print('[AI-Support] Reporter:', player, identifier)
    
    local embed = {
        {
            ["title"] = "🐛 New Bug Report",
            ["color"] = 16711680,
            ["description"] = "A new bug has been reported",
            ["fields"] = {
                {
                    ["name"] = "Category",
                    ["value"] = reportData.category or "Not specified",
                    ["inline"] = true
                },
                {
                    ["name"] = "Reporter",
                    ["value"] = string.format("%s (`%s`)", player, identifier),
                    ["inline"] = true
                },
                {
                    ["name"] = "Description",
                    ["value"] = reportData.description or "No description provided",
                    ["inline"] = false
                },
                {
                    ["name"] = "Steps to Reproduce",
                    ["value"] = reportData.steps or "No steps provided",
                    ["inline"] = false
                },
                {
                    ["name"] = "Additional Information",
                    ["value"] = reportData.additionalInfo or "None provided",
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Bug Report System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    local payload = {
        username = "Bug Report Bot",
        embeds = embed
    }

    
    print('[AI-Support] Sending Discord payload:', json.encode(payload))

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
        
        print('[AI-Support] Discord response:', err, text)
        if headers then
            print('[AI-Support] Discord headers:', json.encode(headers))
        end

        if err == 204 or err == 200 then  
            print('[AI-Support] Bug report sent to Discord successfully')
            TriggerClientEvent('ai-support:notify', src, 'Bug report submitted successfully!')
            if callback then callback(true) end
        else
            print('[AI-Support] Failed to send bug report to Discord. Error:', err)
            print('[AI-Support] Response:', text)
            TriggerClientEvent('ai-support:notify', src, 'Failed to submit bug report to Discord')
            if callback then callback(false) end
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end


RegisterNetEvent('ai-support:updateBlips')
AddEventHandler('ai-support:updateBlips', function(blips)
    if Config.AIMemory.EnableBlipTracking then
        serverBlips = blips
    end
end)



RegisterNetEvent('ai-support:clearChat')
AddEventHandler('ai-support:clearChat', function()
    local src = source
    geminiHistory[src] = {}
    activeReports[src] = nil
end)

RegisterNetEvent('ai-support:clearContext')
AddEventHandler('ai-support:clearContext', function()
    local src = source
    
    geminiHistory[src] = {
        {
            role = "assistant",
            parts = {{ text = "Context has been cleared. How can I help you?" }}
        }
    }
    
    activeReports[src] = nil
end)


RegisterNetEvent('ai-support:getConfig')
AddEventHandler('ai-support:getConfig', function()
    local src = source
    TriggerClientEvent('ai-support:sendConfig', src, {
        title = Config.Title
    })
end) 
