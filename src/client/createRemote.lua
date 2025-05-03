local Promise = require(script.Parent.Parent.Promise)
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
	local queue: { { any } } = {}

	local function noop()
		error(`Attempted to use a server-only function on the client remote '{name}'`)
	end

	local self = {
		name = name,
		type = "event" :: "event",
		test = test,
		fireAll = noop,
		fireAllExcept = noop,
		firePlayers = noop,
	} :: types.Remote

	function self:connect(listener)
		assert(connected, `Cannot use destroyed remote '{name}'`)

		local id = nextListenerId
		nextListenerId += 1
		listeners[id] = listener

		if #queue > 0 then
			for _, args in queue do
				task.spawn(listener, table.unpack(args))
			end
			table.clear(queue)
		end

		return function()
			listeners[id] = nil
		end
	end

	function self:promise(predicate, mapper)
		assert(connected, `Cannot promise destroyed event remote '{name}'`)

		return Promise.new(function(resolve, _, onCancel)
			local disconnect
			disconnect = self:connect(function(...)
				if not predicate or predicate(...) then
					disconnect()
					if mapper then
						resolve(mapper(...))
					else
						resolve(...)
					end
				end
			end)

			onCancel(disconnect)
		end)
	end

	function self:fire(...)
		assert(connected, `Cannot use destroyed remote '{name}'`)

		local arguments = table.pack(...)

		instances.promiseRemoteEvent(name):andThen(function(instance)
			instance:FireServer(table.unpack(arguments, 1, arguments.n))
			test:_fire(table.unpack(arguments, 1, arguments.n))
		end, function(error): ()
			warn(`Failed to fire remote '{name}': {error}`)
		end)
	end

	function self:destroy()
		if not connected then
			return
		end

		connected = false

		if connection then
			connection:Disconnect()
			connection = nil
		end

		table.clear(listeners)
		table.clear(queue)
	end

	local emit = compose(builder.metadata.middleware)(function(...): ()
		if next(listeners) then
			for _, listener in listeners do
				task.spawn(listener, ...)
			end
		else
			table.insert(queue, table.pack(...))
		end
	end, self)

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

	setmetatable(self :: {}, {
		__call = self.fire,
	})

	return self
end

return createRemote
