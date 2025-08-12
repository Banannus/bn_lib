--- ACE-only permission check
--- Usage: BN.HasPermission(source, "your.permission.string")
--- Make sure to define your ACEs in server.cfg with add_ace/add_principal.

-- Best-effort source resolver (accepts number or common player objects)
local function resolveSource(src)
    if type(src) == "number" then return src end
    if type(src) == "string" then return tonumber(src) end
    if type(src) == "table" then
        -- Try common fields from ESX/QB/QBX wrappers
        if src.source then return src.source end
        if src.PlayerData and src.PlayerData.source then return src.PlayerData.source end
        if src.src then return src.src end
        if src.id then return src.id end
    end
    return nil
end

--- Check if the player has a specific ACE permission.
--- @param source any   Player source or object (we'll resolve to a number)
--- @param permission string  ACE permission (e.g. "bn.crafting.use" or "command.kick")
BN.HasPermission = function(source, permission)
    local src = resolveSource(source)
    if not src then return false end
    if not permission or permission == "" then return false end
    return IsPlayerAceAllowed(src, "command") or false
end

return BN.HasPermission
