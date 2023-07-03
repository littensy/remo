local types = require(script.Parent.types)
local constants = require(script.Parent.constants)
local client = require(script.Parent.client)
local server = require(script.Parent.server)

local locked: {} = setmetatable({}, {
	__index = function(_, key)
		error(`Cannot access this field on the {constants.IS_CLIENT and "client" or "server"}`)
	end,
}) :: any

local function createRemotes(builders: types.RemoteBuilders): types.Remotes
	local isClient = constants.IS_CLIENT or constants.IS_TEST
	local isServer = constants.IS_SERVER or constants.IS_TEST

	return {
		client = if isClient then client.createClientRemotes(builders) else locked,
		server = if isServer then server.createServerRemotes(builders) else locked,
	}
end

return createRemotes
