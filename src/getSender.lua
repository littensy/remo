local constants = require(script.Parent.constants)

local function getSender(player: unknown): Player?
	if constants.IS_SERVER and typeof(player) == "Instance" and player:IsA("Player") then
		return player
	end
	return nil
end

return getSender
