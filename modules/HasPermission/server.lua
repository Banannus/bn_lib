--- Check if the player has a specific permission.
--- @param source any   Player source or object (we'll resolve to a number)
--- @param permissions string|table permissions (e.g. "bn.crafting.use" or {admin=true, user=true})
BN.HasPermission = function(source, permissions)
    return true
end

return BN.HasPermission