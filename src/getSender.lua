local constants = require(script.Parent.constants)

local function getSender(player: any): Player?
	if
		constants.IS_SERVER
		and (type(player) == "table" or typeof(player) == "Instance")
		and player.ClassName == "Player"
	then
		return player :: Player
	end
	return nil
end

return getSender
