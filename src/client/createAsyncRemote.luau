local types = require(script.Parent.Parent.types)
local compose = require(script.Parent.Parent.utils.compose)
local instances = require(script.Parent.Parent.utils.instances)
local unwrap = require(script.Parent.Parent.utils.unwrap)
local testRemote = require(script.Parent.Parent.utils.testRemote)

local function createAsyncRemote(name: string, builder: types.RemoteBuilder): types.AsyncRemote
	local test = testRemote.createTestAsyncRemote()
	local connected = true
	local handler = function() end :: (...any) -> ()

	local self = {
		name = name,
		type = "function",
		test = test,
	} :: types.AsyncRemote

	function self:onRequest(callback)
		assert(connected, `Cannot use destroyed async remote '{name}'`)
		handler = callback
	end

	function self:request(...)
		assert(connected, `Cannot use destroyed async remote '{name}'`)

		local arguments = table.pack(...)

		return instances.promiseRemoteFunction(name):andThen(function(instance)
			local response = if test:hasRequestHandler()
				then table.pack(test:_request(table.unpack(arguments, 1, arguments.n))) :: never
				else table.pack(instance:InvokeServer(table.unpack(arguments, 1, arguments.n)))

			for index, validator in builder.metadata.returns do
				local value = response[index]
				assert(validator(value), `Invalid return value #{index} for async remote '{name}': got {value}`)
			end

			return table.unpack(response, 1, response.n)
		end, function(error): ()
			warn(`Failed to invoke async remote '{name}': {error}`)
		end) :: any
	end

	function self:destroy()
		if connected then
			connected = false
			handler = function() end :: (...any) -> ()
		end
	end

	local invoke = compose(builder.metadata.middleware)(function(...: any): any
		handler(...)
		return unwrap(handler(...))
	end, self)

	instances.promiseRemoteFunction(name):andThen(function(instance): ()
		if not connected then
			return
		end

		function instance.OnClientInvoke(...)
			assert(connected, `Async remote '{name}' was invoked after it was destroyed`)

			for index, validator in builder.metadata.parameters do
				local value = select(index, ...)
				assert(validator(value), `Invalid parameter #{index} for async remote '{name}': got {value}`)
			end

			return invoke(...)
		end
	end, function(error): ()
		warn(`Failed to initialize async remote '{name}': {error}`)
	end)

	setmetatable(self :: {}, {
		__call = self.request,
	})

	return self
end

return createAsyncRemote
