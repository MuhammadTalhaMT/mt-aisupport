Config = {}

Config.Command = 'support' -- Command to open support menu
Config.Key = 'F9' -- Key to open support menu
Config.Title = 'Test Support' -- Title shown in the support window
Config.EnableKeyMapping = true -- Enable/disable key mapping for the command

-- Server Information
Config.ServerInfo = {
    Name = "Your Server Name", -- Server name
    Description = "Your server description", -- Brief server description
    MaxSlots = 64, -- Maximum player slots
    Website = "https://yourwebsite.com", -- Server website
    Discord = "https://discord.gg/yourserver", -- Discord invite
    Features = { -- List of server features
        "Custom cars",
        "Custom jobs",
        "Economy system",
        "Housing system"
    },
    Rules = { -- Server rules
        "Be respectful to all players",
        "No cheating or exploiting",
        "No harassment or bullying",
        "Follow RP guidelines",
        "No breaking character",
        "Use common sense"
    },
    Locations = { -- Important server locations with coordinates
        ['Police Station'] = {
            coords = vector3(442.5, -983.0, 30.7),
            blip = {sprite = 60, color = 29} -- Blip configuration
        },
        ['Hospital'] = {
            coords = vector3(294.6, -1448.2, 29.9),
            blip = {sprite = 61, color = 2}
        },
        ['City Hall'] = {
            coords = vector3(-544.9, -204.4, 38.2),
            blip = {sprite = 419, color = 0}
        },
        ['Legion Square'] = {
            coords = vector3(195.2, -934.4, 30.7),
            blip = {sprite = 492, color = 0}
        },
        ['Airport'] = {
            coords = vector3(-1037.5, -2968.1, 13.9),
            blip = {sprite = 90, color = 3}
        }
    },
    GameMode = "Roleplay", -- Server game mode
    Language = "English", -- Primary server language
    Whitelist = false, -- Whether the server is whitelisted
    AntiCheat = true, -- Whether the server uses anti-cheat
    CustomScripts = { -- List of major custom scripts/features
        "Custom jobs system",
        "Advanced housing",
        "Gang system",
        "Drug system"
    }
}

Config.AIMemory = {
    EnableServerInfo = true, -- Whether bot should know about server info
    EnableBlipTracking = true, -- Whether bot should track and know about blips
    EnableRules = true, -- Whether bot should know about rules
    EnableFeatures = true, -- Whether bot should know about features
    EnableLocations = true, -- Whether bot should know about locations
    EnableFAQ = true,  -- Whether bot should use FAQ knowledge
    RulesDetail = {
        ShowPunishments = true, -- Whether to include punishment info in responses
        ShowAppeals = true,    -- Whether to include appeal info in responses
        DetailLevel = 2        -- 1: Basic, 2: Detailed, 3: Full detail with examples
    }
}

Config.RestrictedInfo = {
    'adminlist',
    'passwords',
    'security',
    'backend',
}

Config.Locale = {
    ['command_desc'] = 'Open AI Support menu',
    ['menu_opened'] = 'Support menu opened',
    ['menu_closed'] = 'Support menu closed',
}

-- Categories for bug reports
Config.BugCategories = {
    'Gameplay',
    'Vehicle',
    'Map',
    'UI/HUD',
    'Performance',
    'Other'
}

-- Frequently Asked Questions
Config.FAQ = {
    -- Format: { question = "Question here", answer = "Answer here" }
    {
        question = "How do I get a job?",
        answer = "You can get a job by visiting the job center at Legion Square. Look for the briefcase icon on your map. Available jobs include taxi driver, delivery driver, and more."
    },
    {
        question = "How do I earn money?",
        answer = "There are several ways to earn money:\n1. Get a legal job at the job center\n2. Complete missions and tasks\n3. Trade goods at various shops\n4. Start your own business\n5. Work for other players"
    },
    {
        question = "Where can I buy a car?",
        answer = "You can purchase vehicles at any of the following locations:\n- Premium Deluxe Motorsport (Main City)\n- PDM Luxury (Vinewood)\n- Used Car Dealership (South Side)\nYou'll need a valid driver's license and enough money for the vehicle and insurance."
    },
    {
        question = "How do I buy a house?",
        answer = "To buy a house:\n1. Visit the real estate office in the city\n2. Browse available properties\n3. Ensure you have enough money for down payment\n4. Complete the purchase with a real estate agent\n\nMake sure you maintain regular payments to keep your property!"
    },
    {
        question = "What are the server rules?",
        answer = "Please check the full rules on our Discord. Key points:\n1. No RDM (Random Death Match)\n2. No breaking character (FailRP)\n3. Respect other players\n4. Follow staff instructions\n5. No cheating or exploiting"
    }
}

-- Discord webhook for bug reports
Config.DiscordWebhook = 'WEBHOOK_URL'

-- Gemini API Configuration
Config.GeminiApiKey = 'YOUR_API_KEY'

Config.Debug = false -- Enable debug prints
Config.DefaultResponse = "I apologize, but I'm having trouble understanding. Could you please try again?"

-- Add this new section for server rules configuration
Config.Rules = {
    Categories = {
        General = {
            title = "General Rules",
            rules = {
                "Be respectful to all players and staff",
                "No harassment, discrimination, or hate speech",
                "No exploiting bugs or cheating",
                "Follow staff instructions at all times",
                "English only in global chat"
            }
        },
        Roleplay = {
            title = "Roleplay Rules",
            rules = {
                "No breaking character (FailRP)",
                "No random death match (RDM)",
                "No vehicle death match (VDM)",
                "No combat logging",
                "Maintain realistic roleplay scenarios",
                "No powergaming or metagaming"
            }
        },
        Combat = {
            title = "Combat & PVP Rules",
            rules = {
                "No shooting from vehicles unless in RP scenario",
                "No camping hospitals or police stations",
                "Declare hostile intentions before attacking",
                "No combat logging during active situations",
                "Respect New Life Rule after death"
            }
        },
        Business = {
            title = "Business & Economy",
            rules = {
                "No money laundering or exploiting",
                "Maintain realistic prices for goods/services",
                "Follow business zone regulations",
                "Report any economy exploits to staff",
                "No artificial market manipulation"
            }
        },
        Communication = {
            title = "Communication Rules",
            rules = {
                "Keep OOC chat in appropriate channels",
                "No advertising other servers",
                "No spamming or excessive caps",
                "Use appropriate radio channels",
                "Report issues through proper channels"
            }
        }
    },
    
    Punishments = {
        -- Define punishment levels
        levels = {
            warning = "Verbal/Written Warning",
            kick = "Temporary Kick",
            tempban = "Temporary Ban (1-7 days)",
            permban = "Permanent Ban"
        },
        
        -- Define specific rule violations and their punishments
        violations = {
            rdm = {
                name = "Random Death Match (RDM)",
                first = "warning",
                second = "tempban",
                third = "permban"
            },
            failrp = {
                name = "Breaking Character (FailRP)",
                first = "warning",
                second = "kick",
                third = "tempban"
            },
            cheating = {
                name = "Cheating/Exploiting",
                first = "permban",
                appeal = false
            },
            harassment = {
                name = "Harassment/Discrimination",
                first = "tempban",
                second = "permban",
                appeal = true
            }
        }
    },

    Appeals = {
        allowedFor = {
            "tempban",
            "permban"
        },
        waitTime = {
            tempban = 24, -- Hours before appeal can be made
            permban = 168 -- 7 days before appeal can be made
        },
        process = {
            "Fill out appeal form on Discord",
            "Wait for staff review (24-48 hours)",
            "Attend appeal interview if requested",
            "Follow any additional requirements set by staff"
        }
    }
}