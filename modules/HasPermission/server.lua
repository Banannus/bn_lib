--- Check if the player has a specific permission.
--- @param source any   Player source or object (we'll resolve to a number)
--- @param permissions string|table permissions (e.g. "bn.crafting.use" or {admin=true, user=true})
BN.HasPermission = function(source, permissions)
    local src = source
    if not src then return false end
    if not permissions or permissions == "" then return false end
    local group = Framework == 'esx' and ESX.GetPlayerFromId(src).getGroup() or Framework == 'qb' and QBCore.Functions.GetPlayer(src).PlayerData.group
    if type(permissions) == "table" then
        if permissions[group] then
            return true
        else
            return false
        end
    else
        if group == permissions then
            return true
        else
            return false
        end
    end
end

return BN.HasPermission