--- Dynamically selects and returns the appropriate function for checking a player's permissions
--- based on the configured framework.
--- This function caters to different inventory systems and framework specifics,
--- ensuring that the permission check is performed accurately and efficiently.
---@return function A permission function customized to the active configuration.
local HasPermission = function()
    if Framework == 'esx' then
        return function(player, permission)
            return player.getGroup() >= permission
        end
    elseif Framework == 'qb' then
        return function(player, permission)
            if player and player.Functions and type(player.Functions.HasPermission) == "function" then
                return player.Functions.HasPermission(permission)
            end
            return IsPlayerAceAllowed(player.PlayerData.source, permission)
        end
    elseif Framework == 'qbx' then
        return function(player, permission)
            return IsPlayerAceAllowed(player.PlayerData.source, permission)
        end
    else
        -- Fallback: use source directly (assuming 'player' is just a source here)
        return function(player, permission)
            return IsPlayerAceAllowed(player, permission)
        end
    end
end


-- Assign the dynamically selected function to BN.HasPermission.
local PlayerHasPermission = HasPermission()

--- Check if the player has a specific permission.
-- This function determines if the given player, identified by a 'source', has a permission specified by 'permission'.
-- @param source any The identifier for the player, which is used to retrieve player data.
-- @param permission string The permission to check the player against.
BN.HasPermission = function(source, permission)
    local player = BN.GetPlayer(source)
    if not player then return false end
    return PlayerHasPermission(player, permission)
end

return BN.HasPermission
