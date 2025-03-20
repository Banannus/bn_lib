local CheckForDuty = false -- Only count on duty jobs as part of the HasGroup function.

--- Dynamically selects and returns the appropriate function for checking a player's group
--- based on the configured framework.
--- This function caters to different inventory systems and framework specifics,
--- ensuring that the group check is performed accurately and efficiently.
---@return function A group function customized to the active configuration.
local HasGroup = function()
    if Framework == 'esx' then
        return function(filter)
            local typeOfFilter = type(filter)
            local playerData = ESX.GetPlayerData()
            
            if typeOfFilter == 'string' then
                if playerData.job.name == filter then
                    return playerData.job.name, playerData.job.grade
                end
            elseif typeOfFilter == 'table' then
                if table.type(filter) == 'hash' then
                    local grade = filter[playerData.job.name]
                    if grade and grade <= playerData.job.grade then
                        return playerData.job.name, playerData.job.grade
                    end
                elseif table.type(filter) == 'array' then
                    for _, jobName in ipairs(filter) do
                        if playerData.job.name == jobName then
                            return playerData.job.name, playerData.job.grade
                        end
                    end
                end
            end

            return nil
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(filter)
            local typeOfFilter = type(filter)
            local groups = { 'job', 'gang' }
            local QBCore = exports['qb-core']:GetCoreObject()
            local playerData = QBCore.Functions.GetPlayerData()
            
            if typeOfFilter == 'string' then
                -- Check job
                if playerData.job and playerData.job.name == filter then
                    if CheckForDuty and not playerData.job.onduty then
                        return nil
                    end
                    return playerData.job.name, playerData.job.grade.level
                end
                
                -- Check gang
                if playerData.gang and playerData.gang.name == filter then
                    return playerData.gang.name, playerData.gang.grade.level
                end
            elseif typeOfFilter == 'table' then
                if table.type(filter) == 'hash' then
                    -- Check job
                    if playerData.job then
                        local grade = filter[playerData.job.name]
                        if grade and grade <= playerData.job.grade.level then
                            if CheckForDuty and not playerData.job.onduty then
                                return nil
                            end
                            return playerData.job.name, playerData.job.grade.level
                        end
                    end
                    
                    -- Check gang
                    if playerData.gang then
                        local grade = filter[playerData.gang.name]
                        if grade and grade <= playerData.gang.grade.level then
                            return playerData.gang.name, playerData.gang.grade.level
                        end
                    end
                elseif table.type(filter) == 'array' then
                    for _, groupName in ipairs(filter) do
                        -- Check job
                        if playerData.job and playerData.job.name == groupName then
                            if CheckForDuty and not playerData.job.onduty then
                                return nil
                            end
                            return playerData.job.name, playerData.job.grade.level
                        end
                        
                        -- Check gang
                        if playerData.gang and playerData.gang.name == groupName then
                            return playerData.gang.name, playerData.gang.grade.level
                        end
                    end
                end
            end

            return nil
        end
    else
        -- Fallback function for unsupported frameworks.
        return function() return false end
    end
end

-- Assign the dynamically selected function to BN.HasGroup.
local PlayerHasGroup = HasGroup()

--- Check if the player belongs to a specific group.
-- This function determines if the current player belongs to a group specified by 'filter'.
-- @param filter string|table The group name(s) to check against.
-- @return string|nil The name of the matched group or nil if no match.
-- @return number|nil The grade level of the matched group or nil if no match.
BN.HasGroup = function(filter)
    -- Client-side implementation doesn't need source parameter
    return PlayerHasGroup(filter)
end

return BN.HasGroup