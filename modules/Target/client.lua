--- @class BN.Target
BN.Target = {}

--- Initialize the target system by checking available resources and setting the target module.
local Initialize = function()
    local resources = {"qb-target", "qtarget", "ox_target"}  -- List of potential target resources.
    for _, resource in ipairs(resources) do
        if GetResourceState(resource) == 'started' then
            if resource == 'qtarget' then
                target = 'ox_target'
            else
                target = resource
            end
            break  -- Break the loop once the first active target resource is found.
        end
    end

    -- Optionally handle the case where none of the resources are started.
    if not target then
        error("No target resource found or started.")
        return false  -- Indicate unsuccessful initialization.
    end
    return true  -- Indicate successful initialization.
end

Initialize() -- Initialize the target system

--- Add a box zone.
---@param identifier string The identifier for the zone.
---@param coords table Coordinates where the zone is centered.
---@param width number The width of the box zone.
---@param length number The length of the box zone.
---@param data table Additional data such as heading, options, and distance.
---@param debugPoly boolean Whether to debug the polygon.
---@return handler The handle to the created zone.
BN.Target.AddBoxZone = function(identifier, coords, width, length, data, debugPoly)
    local handler = exports[target]:AddBoxZone(identifier, coords, width, length, {
        name = identifier,
        heading = data.heading,
        debugPoly = debugPoly,
        minZ = coords.z - 1.2,
        maxZ = coords.z + 1.2,
    }, {
        options = data.options,
        distance = data.distance,
    })
    return handler
end

--- Add a circle zone.
---@param identifier string The identifier for the zone.
---@param coords table Coordinates where the zone is centered.
---@param radius number The radius of the circle zone.
---@param data table Additional data such as options and distance.
---@param debugPoly boolean Whether to debug the polygon.
---@return handler The handle to the created zone.
BN.Target.AddCircleZone = function(identifier, coords, radius, data, debugPoly)
    local handler = exports[target]:AddCircleZone(identifier, coords, radius, {
        name = identifier,
        useZ = true,
        debugPoly = debugPoly,
    }, {
        options = data.options,
        distance = data.distance,
    })
    return handler
end

--- Add a target entity.
---@param entityId number The entity ID to target.
---@param data table Additional data such as options and distance.
BN.Target.AddTargetEntity = function(entityId, data)
    exports[target]:AddTargetEntity(entityId, {
        options = data.options,
        distance = data.distance,
    })
end

--- Add a target model.
---@param models table|array Models to target.
---@param data table Additional data such as options and distance.
BN.Target.AddTargetModel = function(models, data)
    exports[target]:AddTargetModel(models, {
        options = data.options,
        distance = data.distance,
    })
end

--- Remove a target entity.
---@param entity number The entity to remove from targeting.
BN.Target.RemoveTargetEntity = function(entity)
    exports[target]:RemoveTargetEntity(entity)
end

--- Remove a zone.
---@param identifier string The identifier for the zone to remove.
BN.Target.RemoveZone = function(identifier)
    exports[target]:RemoveZone(identifier)
end

--- Add a global ped target.
---@param identifier string The identifier for the global ped.
---@param data table Additional data such as options and distance.
BN.Target.AddGlobalPed = function(identifier, data)
    exports[target]:AddGlobalPed({
        name = identifier,
        options = data.options,
        distance = data.distance,
    })
end

--- Remove a global ped target.
---@param identifier string The identifier for the global ped to remove.
BN.Target.RemoveGlobalPed = function(identifier)
    exports[target]:RemoveGlobalPed(identifier)
end


--- Add a local entity target.
---@param entity number The entity to target.
---@param data table Additional data such as options and distance.
BN.Target.AddLocalEntity = function(entity, data)
    if target == 'ox_target' then
        local oxOptions = {}
        for _, option in ipairs(data.options) do
            table.insert(oxOptions, {
                icon = option.icon,
                label = option.label,
                canInteract = option.canInteract,
                onSelect = option.onSelect,
                iconColor = option.iconColor,
                distance = data.distance
            })
        end
        exports.ox_target:addLocalEntity(entity, oxOptions)
    elseif target == 'qb-target' then
        exports["qb-target"]:AddTargetEntity(entity, {
            options = data.options,
            distance = data.distance,
        })
    end
end

return BN.Target