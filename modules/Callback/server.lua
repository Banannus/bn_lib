--- @class BN.Callback
BN.Callback = {}

local pendingCallbacks = {}
local cbEvent = ('__bn_cb_%s')
local callbackTimeout = GetConvarInt('bn:callbackTimeout', 300000)

-- Register the callback event handler
RegisterNetEvent(cbEvent:format(cache.resource), function(key, ...)
    local cb = pendingCallbacks[key]
    if not cb then return end
    
    pendingCallbacks[key] = nil
    cb(...)
end)

-- Register validation callback
RegisterNetEvent('bn_lib:validateCallback', function(name, resource, key)
    -- Add validation logic here if needed
end)

---@param _ any
---@param event string
---@param playerId number
---@param cb function|false
---@param ... any
---@return ...
local function triggerClientCallback(_, event, playerId, cb, ...)
    assert(DoesPlayerExist(playerId --[[@as string]]), ("target playerId '%s' does not exist"):format(playerId))

    local key
    repeat
        key = ('%s:%s:%s'):format(event, math.random(0, 100000), playerId)
    until not pendingCallbacks[key]

    TriggerClientEvent('bn_lib:validateCallback', playerId, event, cache.resource, key)
    TriggerClientEvent(cbEvent:format(event), playerId, cache.resource, key, ...)

    local promise = not cb and promise.new()

    pendingCallbacks[key] = function(response, ...)
        if response == 'cb_invalid' then
            response = ("callback '%s' does not exist"):format(event)
            return promise and promise:reject(response) or error(response)
        end
        
        response = { response, ... }
        
        if promise then
            return promise:resolve(response)
        end
        
        if cb then
            cb(table.unpack(response))
        end
    end

    if promise then
        SetTimeout(callbackTimeout, function() 
            promise:reject(("callback event '%s' timed out"):format(key)) 
        end)
        return table.unpack(Citizen.Await(promise))
    end
end

--- Allows triggering client callbacks directly through the module.
---@param event string
---@param playerId number
---@param cb function
---@param ...
BN.Callback = setmetatable({}, {
    __call = function(_, event, playerId, cb, ...)
        if not cb then
            print(("warning: callback event '%s' does not have a function to callback to and will instead await"):format(event))
        else
            local cbType = type(cb)
            if cbType == 'table' and getmetatable(cb)?.__call then
                cbType = 'function'
            end
            assert(cbType == 'function', ("expected argument 3 to have type 'function' (received %s)"):format(cbType))
        end
        
        return triggerClientCallback(_, event, playerId, cb, ...)
    end
})

--- Sends an event to a client and halts the current thread until a response is returned.
---@param event string
---@param playerId number
---@param ... any
---@return ...
function BN.Callback.Await(event, playerId, ...)
    return triggerClientCallback(nil, event, playerId, false, ...)
end

--- Handles the response from a callback and ensures any script errors are cleanly logged.
---@param success boolean Whether the call was successful.
---@param result any The result of the call, if successful.
---@param ... any Additional results.
---@return any The processed result, or false if an error occurred.
local function callbackResponse(success, result, ...)
    if not success then
        if result then
            return print(('^1SCRIPT ERROR: %s^0\n%s'):format(result, Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
        end
        return false
    end
    return result, ...
end

local pcall = pcall

--- Registers an event handler and callback function to respond to client requests.
---@param name string The name of the event.
---@param cb function The callback function to register.
function BN.Callback.Register(name, cb)
    local event = cbEvent:format(name)
    
    -- Register the callback as valid (similar to ox_lib's setValidCallback)
    -- You could implement this if needed
    
    RegisterNetEvent(event, function(resource, key, ...)
        TriggerClientEvent(cbEvent:format(resource), source, key, callbackResponse(pcall(cb, source, ...)))
    end)
end

return BN.Callback