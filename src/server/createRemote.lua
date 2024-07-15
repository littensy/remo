local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)

local compose = require(script.Parent.Parent.utils.compose)
local instances = require(script.Parent.Parent.utils.instances)
local testRemote = require(script.Parent.Parent.utils.testRemote)

local function createRemote(name: string, builder: types.RemoteBuilder): types.Remote
	local instance = instances.createRemoteEvent(name, builder.metadata.unreliable)
	local test = testRemote.createTestRemote()
	local connected = true

	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local self = {
		name = name,
		type = "event" :: "event",
		test = test,
	} :: types.Remote

	function self:connect(listener)
		assert(connected, `Cannot connect to destroyed event remote '{name}'`)

		local id = nextListenerId
		nextListenerId += 1
		listeners[id] = listener

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

	function self:fire(player, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		instance:FireClient(player, ...)
		test:_fire(player, ...) -- do not risk omitting first argument
	end

	function self:fireAll(...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		instance:FireAllClients(...)
		test:_fire(...)
	end

	function self:fireAllExcept(exception, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		for _, player in Players:GetPlayers() do
			if player ~= exception then
				instance:FireClient(player, ...)
			end
		end
		test:_fire(...)
	end

	function self:firePlayers(players, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		for _, player in players do
			instance:FireClient(player, ...)
		end
		test:_fire(...)
	end

	function self:destroy()
		if not connected then
			return
		end

		connected = false

		instance:Destroy()
		instance = nil :: never

		table.clear(listeners)
	end

	local emit = compose(builder.metadata.middleware)(function(...): ()
		for _, listener in listeners do
			task.spawn(listener, ...)
		end
	end, self)

	instance.OnServerEvent:Connect(function(player: Player, ...)
		for index, validator in builder.metadata.parameters do
			local value = select(index, ...)
			assert(validator(value), `Invalid parameter #{index} for event remote '{name}': got {value}`)
		end

		emit(player, ...)
	end)

	setmetatable(self :: {}, {
		__call = self.fire,
	})

	return self
end

return createRemote
