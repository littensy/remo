local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)
local compose = require(script.Parent.Parent.utils.compose)
local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)

local remotes = script.Parent.Parent.remotes

local function createRemoteFunction(name: string): RemoteFunction
	if remotes:FindFirstChild(name) then
		return remotes[name]
	end

	if constants.IS_EDIT then
		return mockRemotes.createMockRemoteFunction(name)
	end

	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = name
	remoteFunction.Parent = remotes

	return remoteFunction
end

local function createServerFunction(name: string, builder: types.RemoteBuilder): types.ServerFunction
	assert(builder.metadata.returns, `Missing return value validator for function '{name}'`)

	local instance = createRemoteFunction(name)
	local connected = true

	local function handler(...)
		error(`Remote function '{name}' was invoked before a handler was set`)
	end

	local serverFunction: types.ServerFunction = {
		name = name,

		onInvoke = function(self, callback)
			assert(connected, `Cannot set handler for destroyed remote function '{name}'`)
			handler = callback
		end,

		invoke = function(self, player, ...)
			assert(connected, `Cannot invoke destroyed remote function '{name}'`)

			return Promise.try(function(...)
				local response = instance:InvokeClient(player, ...)
				assert(builder.metadata.returns(response), `Invalid return value for function '{name}': got {response}`)
				return response
			end, ...)
		end,

		destroy = function(self)
			if not connected then
				return
			end

			connected = false
			instance:Destroy()
			instance = nil :: never
		end,
	}

	local invoke = compose(builder.metadata.middleware)(function(...)
		return handler(...)
	end, serverFunction)

	function instance.OnServerInvoke(player: Player, ...)
		for index, validator in builder.metadata.parameters do
			local value = select(index, ...)
			assert(validator(value), `Invalid parameter #{index} for function '{name}': got {value}`)
		end

		return invoke(player, ...)
	end

	return serverFunction
end

return createServerFunction
