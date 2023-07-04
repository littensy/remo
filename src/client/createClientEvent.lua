local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)
local compose = require(script.Parent.Parent.utils.compose)
local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)

local remotes = script.Parent.Parent.remotes

local function promiseRemoteEvent(name: string): types.Thenable<RemoteEvent>
	if remotes:FindFirstChild(name) then
		return Promise.resolve(remotes[name])
	end

	if constants.IS_EDIT then
		return Promise.resolve(mockRemotes.createMockRemoteEvent(name))
	end

	return Promise.fromEvent(remotes.ChildAdded, function(child)
		return child:IsA("RemoteEvent") and child.Name == name
	end)
end

local function createClientEvent(name: string, builder: types.RemoteBuilder): types.ClientEvent
	local connection: RBXScriptConnection?
	local connected = true

	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local clientEvent: types.ClientEvent = {
		name = name,

		connect = function(self, callback)
			assert(connected, `Cannot connect to destroyed event '{name}'`)

			local id = nextListenerId
			nextListenerId += 1
			listeners[id] = callback

			return function()
				listeners[id] = nil
			end
		end,

		fire = function(self, ...)
			assert(connected, `Cannot fire destroyed event '{name}'`)

			local arguments = table.pack(...)

			promiseRemoteEvent(name):andThen(function(instance)
				instance:FireServer(table.unpack(arguments, 1, arguments.n))
			end, function(error): ()
				warn(`Failed to fire event '{name}': {error}`)
			end)
		end,

		destroy = function(self)
			if not connected then
				return
			end

			connected = false

			if connection then
				connection:Disconnect()
				connection = nil
			end

			table.clear(listeners)
		end,
	}

	local emit = compose(builder.metadata.middleware)(function(...): ()
		for _, listener in listeners do
			task.spawn(listener, ...)
		end
	end, clientEvent)

	promiseRemoteEvent(name):andThen(function(instance)
		if not connected then
			return
		end

		connection = instance.OnClientEvent:Connect(function(...)
			for index, validator in builder.metadata.parameters do
				local value = select(index, ...)
				assert(validator(value), `Invalid parameter #{index} for event '{name}': got {value}`)
			end

			emit(...)
		end)
	end, function(error): ()
		warn(`Failed to initialize event '{name}': {error}`)
	end)

	return clientEvent
end

return createClientEvent
