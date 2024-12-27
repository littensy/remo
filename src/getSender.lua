local constants = require(script.Parent.constants)

local function getSender(player: any): Player?
	if constants.IS_SERVER and (typeof(player) == "Instance" and player:IsA("Player")) or player.__unique_player_identifier_do_not_use then
		return player
	end
	return nil
end

return getSender
