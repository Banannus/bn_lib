--- @class BN.Callback
BN.Callback = {}

local pendingCallbacks = {}
local timers = {}
local cbEvent = ('__bn_cb_%s')
local callbackTimeout = GetConvarInt('bn:callbackTimeout', 300000)

-- Register the callback event handler
RegisterNetEvent(cbEvent:format(cache.resource), function(key, ...)
    if source == '' then return end

    local cb = pendingCallbacks[key]
    if not cb then return end

    pendingCallbacks[key] = nil
    cb(...)
end)

--- Manages delay timers for events to prevent spamming or rapid calls.
---@param event string The name of the event.
---@param delay number | false A delay in milliseconds to enforce between activations, or false to ignore timing.
---@return boolean True if the event can proceed, false if it is being throttled.
local function eventTimer(event, delay)
    if delay and type(delay) == 'number' and delay > 0 then
        local time = GetGameTimer()
        if (timers[event] or 0) > time then
            return false
        end
        timers[event] = time + delay
    end
    return true
end

--- Triggers a server callback and manages its lifecycle.
---@param event string The event name.
---@param delay number | false Optional delay to throttle the event.
---@param cb function|false The callback function or false for a promise-based response.
---@param ... any The arguments to pass to the server event.
---@return ... The results from the callback or a resolved promise.
local function triggerServerCallback(event, delay, cb, ...)
    if not eventTimer(event, delay) then return end

    local key
    repeat
        key = ('%s:%s'):format(event, math.random(0, 100000))
    until not pendingCallbacks[key]

    TriggerServerEvent('bn_lib:validateCallback', event, cache.resource, key)
    TriggerServerEvent(cbEvent:format(event), cache.resource, key, ...)

    local promise = not cb and promise.new()

    pendingCallbacks[key] = function(response, ...)
        if response == 'cb_invalid' then
            response = ("callback '%s' does not exist"):format(event)
            return promise and promise:reject(response) or error(response)
        end
        
        response = {response, ...}
        
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

--- Allows triggering server callbacks directly through the module.
---@param event string
---@param delay number | false
---@param cb function
---@param ...
BN.Callback = setmetatable({}, {
    __call = function(_, event, delay, cb, ...)
        if not cb then
            print(("warning: callback event '%s' does not have a function to callback to and will instead await"):format(event))
        else
            local cbType = type(cb)
            if cbType == 'table' and getmetatable(cb)?.__call then
                cbType = 'function'
            end
            assert(cbType == 'function', ("expected argument 3 to have type 'function' (received %s)"):format(cbType))
        end
        
        return triggerServerCallback(event, delay, cb, ...)
    end
})

--- Sends an event to the server and halts the current thread until a response is returned.
---@param event string
---@param delay number | false prevent the event from being called for the given time.
---@param ... any The arguments to pass to the server event.
---@return ... The results from the callback or a resolved promise.
function BN.Callback.Await(event, delay, ...)
    return triggerServerCallback(event, delay, false, ...)
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

--- Registers an event handler and callback function to respond to server requests.
---@param name string The name of the event.
---@param cb function The callback function to register.
function BN.Callback.Register(name, cb)
    local event = cbEvent:format(name)
    
    RegisterNetEvent(event, function(resource, key, ...)
        TriggerServerEvent(cbEvent:format(resource), key, callbackResponse(pcall(cb, ...)))
    end)
end

return BN.Callback