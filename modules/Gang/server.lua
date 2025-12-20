BN.Gang = {}

--- Dynamically selects and returns the appropriate function for checking if a player is in a gang
--- based on the configured framework.
---@return function A function to check if a player is in a gang.
local IsGang = function()
    if Framework == 'esx' then
        return function(player, gangs)
            -- ESX doesn't have native gang support, check job name against gang list
            if type(gangs) == 'table' then
                for _, gangName in ipairs(gangs) do
                    if player.job.name == gangName then
                        return true, player.job.name, player.job.grade
                    end
                end
            end
            return false, nil, nil
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(player, gangs)
            local gangData = player.PlayerData.gang
            if not gangData then return false, nil, nil end
            
            -- Check if player's gang is in the provided gangs list
            if type(gangs) == 'table' then
                for _, gangName in ipairs(gangs) do
                    if gangData.name == gangName then
                        return true, gangData.name, gangData.grade.level
                    end
                end
            end
            return false, nil, nil
        end
    else
        -- Fallback function for unsupported frameworks.
        return function() return false, nil, nil end
    end
end

local PlayerIsGang = IsGang()

--- Dynamically selects and returns the appropriate function for getting a player's gang
--- based on the configured framework.
---@return function A function to get a player's gang information.
local GetGang = function()
    if Framework == 'esx' then
        return function(player)
            -- ESX doesn't have native gang support, return job as gang
            if player.job then
                return {
                    name = player.job.name,
                    label = player.job.label,
                    grade = player.job.grade,
                    grade_name = player.job.grade_name,
                    grade_label = player.job.grade_label
                }
            end
            return nil
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(player)
            local gangData = player.PlayerData.gang
            if gangData and gangData.name then
                return {
                    name = gangData.name,
                    label = gangData.label,
                    grade = gangData.grade.level,
                    grade_name = gangData.grade.name,
                    grade_label = gangData.grade.name,
                    isboss = gangData.isboss or false
                }
            end
            return nil
        end
    else
        -- Fallback function for unsupported frameworks.
        return function() return nil end
    end
end

local PlayerGetGang = GetGang()

--- Check if the player is in any of the specified gangs.
--- @param source number The player's server ID.
--- @param gangs table A list/array of gang names to check against.
--- @return boolean, string|nil, number|nil Returns true if player is in a gang, gang name, and gang grade. Returns false, nil, nil if not in any gang.
BN.Gang.IsGang = function(source, gangs)
    local player = BN.GetPlayer(source)
    if not player then return false, nil, nil end
    return PlayerIsGang(player, gangs)
end

--- Gets the player's gang information.
--- @param source number The player's server ID.
--- @return table|nil Returns a table with gang data (name, label, grade, grade_name, grade_label) or nil if no gang.
BN.Gang.GetGang = function(source)
    local player = BN.GetPlayer(source)
    if not player then return nil end
    return PlayerGetGang(player)
end

--- Checks if the player is a gang boss.
--- @param source number The player's server ID.
--- @return boolean Returns true if the player is a gang boss, false otherwise.
BN.Gang.IsBoss = function(source)
    local player = BN.GetPlayer(source)
    if not player then return false end
    
    if Framework == 'esx' then
        -- For ESX, check if job grade is boss (typically highest grade)
        if player.job and player.job.grade_name then
            local gradeName = player.job.grade_name:lower()
            return gradeName == 'boss'
        end
        return false
    elseif Framework == 'qb' or Framework == 'qbx' then
        -- For QBCore, use the isboss property
        local gangData = player.PlayerData.gang
        if gangData then
            return gangData.isboss or false
        end
        return false
    else
        return false
    end
end

return BN.Gang