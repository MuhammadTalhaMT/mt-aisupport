local configuredLocations = {}


function GetBlipInfo(searchName)
    if not searchName then 
        print('[AI-Support] Search name is nil')
        return nil 
    end
    
    print('[AI-Support] Searching for location:', searchName)
    print('[AI-Support] Available locations:')
    for name, data in pairs(Config.ServerInfo.Locations) do
        print('  -', name, json.encode(data))
    end
    
    
    if Config.ServerInfo.Locations[searchName] then
        print('[AI-Support] Found exact match:', searchName)
        return {
            name = searchName,
            coords = Config.ServerInfo.Locations[searchName].coords,
            blip = Config.ServerInfo.Locations[searchName].blip
        }
    end
    
    
    local searchNameLower = string.lower(searchName)
    for name, data in pairs(Config.ServerInfo.Locations) do
        if string.lower(name) == searchNameLower then
            print('[AI-Support] Found case-insensitive match:', name)
            return {
                name = name,
                coords = data.coords,
                blip = data.blip
            }
        end
    end
    
    print('[AI-Support] No location found for:', searchName)
    return nil
end


function SetWaypointToLocation(searchName)
    local blipInfo = GetBlipInfo(searchName)
    if blipInfo then
        if Config.Debug then
            print('[AI-Support] Setting waypoint to:', blipInfo.name)
            print('[AI-Support] Coordinates:', json.encode(blipInfo.coords))
        end
        
        
        SetNewWaypoint(blipInfo.coords.x, blipInfo.coords.y)
        return true
    end
    
    if Config.Debug then
        print('[AI-Support] Failed to find location:', searchName)
    end
    return false
end


function GetNearbyLocations(coords, radius)
    local nearby = {}
    
    for name, data in pairs(Config.ServerInfo.Locations) do
        local distance = #(coords - data.coords)
        if distance <= radius then
            table.insert(nearby, {
                name = name,
                distance = distance,
                coords = data.coords
            })
        end
    end
    
    
    table.sort(nearby, function(a, b)
        return a.distance < b.distance
    end)
    
    return nearby
end


CreateThread(function()
    
    configuredLocations = Config.ServerInfo.Locations
end) 