local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)

local compose = require(script.Parent.Parent.utils.compose)
local instances = require(script.Parent.Parent.utils.instances)
local unwrap = require(script.Parent.Parent.utils.unwrap)
local testRemote = require(script.Parent.Parent.utils.testRemote)

local function createAsyncRemote(name: string, builder: types.RemoteBuilder): types.AsyncRemote
	assert(builder.metadata.returns, `Missing return value validator for async remote '{name}'`)

	local instance = instances.createRemoteFunction(name)
	local test = testRemote.createTestAsyncRemote()
	local connected = true

	local function handler(...): ...any
		return
	end

	local function onRequest(self, callback)
		assert(connected, `Cannot use destroyed async remote '{name}'`)
		handler = callback
	end

	local function request(self, player, ...)
		assert(connected, `Cannot use destroyed async remote '{name}'`)

		return Promise.try(function(...)
			local response = if test:hasRequestHandler()
				then table.pack(test:_request(player, ...)) :: never
				else table.pack(instance:InvokeClient(player, ...))

			for index, validator in builder.metadata.returns do
				local value = response[index]
				assert(validator(value), `Invalid return value #{index} for async remote '{name}': got {value}`)
			end

			return table.unpack(response, 1, response.n)
		end, ...)
	end

	local function destroy()
		if connected then
			connected = false
			instance:Destroy()
			instance = nil :: any
		end
	end

	local api: types.AsyncRemoteApi = {
		name = name,
		type = "function" :: "function",
		test = test,
		onRequest = onRequest,
		request = request,
		destroy = destroy,
	}

	local asyncRemote = setmetatable(api, {
		__call = request,
	}) :: types.AsyncRemote

	local invoke = compose(builder.metadata.middleware)(function(...)
		return unwrap(handler(...))
	end, asyncRemote)

	function instance.OnServerInvoke(player: Player, ...)
		for index, validator in builder.metadata.parameters do
			local value = select(index, ...)
			assert(validator(value), `Invalid parameter #{index} for async remote '{name}': got {value}`)
		end

		return invoke(player, ...)
	end

	return asyncRemote
end

return createAsyncRemote
