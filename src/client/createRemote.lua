local types = require(script.Parent.Parent.types)
local compose = require(script.Parent.Parent.utils.compose)
local instances = require(script.Parent.Parent.utils.instances)
local testRemote = require(script.Parent.Parent.utils.testRemote)

local function createRemote(name: string, builder: types.RemoteBuilder): types.Remote
	local connection: RBXScriptConnection?
	local test = testRemote.createTestRemote()
	local connected = true

	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local function noop()
		error(`Attempted to use a server-only function on the client remote '{name}'`)
	end

	local function connect(self: any, listener)
		assert(connected, `Cannot use destroyed remote '{name}'`)

		local id = nextListenerId
		nextListenerId += 1
		listeners[id] = listener

		return function()
			listeners[id] = nil
		end
	end

	local function fire(self: any, ...)
		assert(connected, `Cannot use destroyed remote '{name}'`)

		local arguments = table.pack(...)

		instances.promiseRemoteEvent(name):andThen(function(instance)
			instance:FireServer(table.unpack(arguments, 1, arguments.n))
			test:_fire(table.unpack(arguments, 1, arguments.n))
		end, function(error): ()
			warn(`Failed to fire remote '{name}': {error}`)
		end)
	end

	local function destroy()
		if not connected then
			return
		end

		connected = false

		if connection then
			connection:Disconnect()
			connection = nil
		end

		table.clear(listeners)
	end

	local remote: types.Remote = {
		name = name,
		type = "event" :: "event",
		test = test,
		connect = connect,
		fire = fire,
		fireAll = noop,
		fireAllExcept = noop,
		firePlayers = noop,
		destroy = destroy,
	}

	local emit = compose(builder.metadata.middleware)(function(...): ()
		for _, listener in listeners do
			task.spawn(listener, ...)
		end
	end, remote)

	instances.promiseRemoteEvent(name):andThen(function(instance)
		if not connected then
			return
		end

		connection = instance.OnClientEvent:Connect(function(...)
			for index, validator in builder.metadata.parameters do
				local value = select(index, ...)
				assert(validator(value), `Invalid parameter #{index} for remote '{name}': got {value}`)
			end

			emit(...)
		end)
	end, function(error): ()
		warn(`Failed to initialize remote '{name}': {error}`)
	end)

	return remote
end

return createRemote
