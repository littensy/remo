local types = require(script.Parent.types)
local constants = require(script.Parent.constants)
local client = require(script.Parent.client)
local server = require(script.Parent.server)

local locked: {} = setmetatable({}, {
	__index = function(_, key)
		error(`Cannot access this field on the {constants.IS_CLIENT and "client" or "server"}`)
	end,
}) :: any

local function createRemotes<Client, Server>(builders: types.RemoteBuilders): types.Remotes<Client, Server>
	local isClient = constants.IS_CLIENT or constants.IS_TEST
	local isServer = constants.IS_SERVER or constants.IS_TEST

	local client = if isClient then client.createClientRemotes(builders) else locked
	local server = if isServer then server.createServerRemotes(builders) else locked

	local function cleanup(remotes)
		for _, remote in remotes do
			if type(remote) ~= "table" then
				continue
			end

			if remote.destroy then
				remote:destroy()
			else
				cleanup(remote)
			end
		end
	end

	return {
		client = (client :: any) :: Client,
		server = (server :: any) :: Server,
		destroy = function(self)
			cleanup(self.client)
			cleanup(self.server)
		end,
	}
end

return createRemotes
