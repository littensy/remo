local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)
local compose = require(script.Parent.Parent.utils.compose)
local thenable = require(script.Parent.Parent.utils.thenable)
local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)

local remotes = script.Parent.Parent.remotes

local function promiseRemoteFunction(name: string): types.Thenable<RemoteFunction>
	if remotes:FindFirstChild(name) then
		return Promise.resolve(remotes[name])
	end

	if constants.IS_EDIT then
		return Promise.resolve(mockRemotes.createMockRemoteFunction(name))
	end

	return Promise.fromEvent(remotes.ChildAdded, function(child)
		return child:IsA("RemoteFunction") and child.Name == name
	end)
end

local function createClientFunction(name: string, builder: types.RemoteBuilder): types.ClientFunction
	assert(builder.metadata.returns, `Missing return value validator for function '{name}'`)

	local connected = true

	local function handler(...)
		error(`Remote function '{name}' was invoked before a handler was set`)
	end

	local clientFunction: types.ClientFunction = {
		name = name,

		onInvoke = function(self, callback)
			assert(connected, `Cannot connect to destroyed function '{name}'`)
			handler = callback
		end,

		invoke = function(self, ...)
			assert(connected, `Cannot invoke destroyed function '{name}'`)

			local arguments = table.pack(...)

			return promiseRemoteFunction(name):andThen(function(instance)
				local response = instance:InvokeServer(table.unpack(arguments, 1, arguments.n))
				assert(builder.metadata.returns(response), `Invalid return value for function '{name}': got {response}`)
				return response
			end, function(error): ()
				warn(`Failed to invoke function '{name}': {error}`)
			end) :: any
		end,

		destroy = function(self)
			if not connected then
				return
			end

			connected = false

			function handler()
				error(`Remote function '{name}' was invoked after it was destroyed`)
			end
		end,
	}

	local invoke = compose(builder.metadata.middleware)(function(...)
		return thenable.unwrap(handler(...))
	end, clientFunction)

	promiseRemoteFunction(name):andThen(function(instance): ()
		if not connected then
			return
		end

		function instance.OnClientInvoke(...)
			assert(connected, `Remote function '{name}' was invoked after it was destroyed`)

			for index, validator in builder.metadata.parameters do
				local value = select(index, ...)
				assert(validator(value), `Invalid parameter #{index} for function '{name}': got {value}`)
			end

			return invoke(...)
		end
	end, function(error): ()
		warn(`Failed to initialize function '{name}': {error}`)
	end)

	return clientFunction
end

return createClientFunction
