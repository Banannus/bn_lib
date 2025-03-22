---@class BN.String
BN.String = {}

--- Checks if a string starts with a specified substring.
---@param str string The string to check.
---@param start string The substring to match at the start.
---@return boolean True if 'str' starts with 'start', false otherwise.
BN.String.StartsWith = function(str, start)
    return str:sub(1, #start) == start
end

--- Checks if a string ends with a specified substring.
---@param str string The string to check.
---@param ending string The substring to match at the end.
---@return boolean True if 'str' ends with 'ending', false otherwise.
BN.String.EndsWith = function(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

--- Capitalizes the first letter of a string and lowercases the rest.
---@param str string The string to capitalize.
---@return string The capitalized string.
BN.String.CapitalizeFirst = function(str)
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

--- Splits a string by a specified delimiter.
---@param str string The string to split.
---@param delim string The delimiter to use for splitting.
---@return table A table of substrings.
BN.String.Split = function(str, delim)
    local result = {}
    local pattern = "(.-)" .. delim
    local last_end = 1
    local s, e, cap = str:find(pattern, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(result, cap)
        end
        last_end = e + 1
        s, e, cap = str:find(pattern, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(result, cap)
    end
    return result
end

return BN.String