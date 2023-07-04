local types = require(script.Parent.types)
local constants = require(script.Parent.constants)
local client = require(script.Parent.client)
local server = require(script.Parent.server)

local function createRemotes<Map>(builders: types.RemoteBuilders): types.Remotes<Map>
	local map = if constants.IS_SERVER then server.createRemotes(builders) else client.createRemotes(builders)

	local function recursiveDestroy(values: any)
		for _, value in values do
			if type(value) ~= "table" then
				return
			end

			if value.destroy then
				value:destroy()
			else
				recursiveDestroy(value)
			end
		end
	end

	local remotes: any = {
		destroy = function()
			recursiveDestroy(map)
		end,
	}

	for key, value in map do
		remotes[key] = value
	end

	return remotes
end

return createRemotes
