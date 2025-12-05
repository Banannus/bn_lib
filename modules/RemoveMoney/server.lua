--- Dynamically selects and returns the appropriate function for removing money from a player
--- based on the configured framework. This approach abstracts framework-specific calls
--- into a unified BN interface, facilitating a clean and maintainable way to interact
--- with player accounts across different frameworks.
----@return function A function that removes money from a player's account.
local RemoveMoney = function()
    if Framework == 'esx' then
        return function(source, account, amount)
            if account == 'cash' then
                account = 'money'
            end
            
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                local currentMoney = xPlayer.getAccount(account).money
                if currentMoney >= amount then
                    xPlayer.removeAccountMoney(account, amount)
                    return true
                end
                return false
            end
            return false
        end
    elseif Framework == 'qb' then
        return function(source, account, amount)
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                local currentMoney = Player.Functions.GetMoney(account)
                if currentMoney >= amount then
                    Player.Functions.RemoveMoney(account, amount)
                    return true
                end
                return false
            end
            return false
        end
    else
        -- Fallback function for unsupported frameworks. Logs an error message.
        return function(source, account, amount)
            error(string.format("Unsupported framework. Unable to remove money for source: %s", source))
            return false
        end
    end
end

-- Assign the dynamically selected function to a local variable.
local RemoveMoneyFromPlayer = RemoveMoney()

--- Removes money from a player's account, abstracting framework-specific logic.
--- This function serves as a wrapper that calls a pre-defined function based on the current game framework,
--- optimized for performance by determining the appropriate function during script initialization.
--- Checks if the player has sufficient funds before removing money.
----@param source number The server ID of the player.
----@param account string The account type ('cash', 'bank', 'black_money'). 'cash' works for both ESX and QB frameworks.
----@param amount number The amount of money to remove.
----@return boolean Returns true if money was successfully removed; returns false if the player doesn't have enough money, is not found, or if an error occurs.
BN.RemoveMoney = function(source, account, amount)
    return RemoveMoneyFromPlayer(source, account, amount)
end

return BN.RemoveMoney
