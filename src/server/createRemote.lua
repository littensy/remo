local Players = game:GetService("Players")

local types = require(script.Parent.Parent.types)
local compose = require(script.Parent.Parent.utils.compose)
local instances = require(script.Parent.Parent.utils.instances)

local function createRemote(name: string, builder: types.RemoteBuilder): types.Remote
	local instance = instances.createRemoteEvent(name)
	local connected = true

	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local function connect(self: any, listener)
		assert(connected, `Cannot connect to destroyed event remote '{name}'`)

		local id = nextListenerId
		nextListenerId += 1
		listeners[id] = listener

		return function()
			listeners[id] = nil
		end
	end

	local function fire(self: any, player, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		instance:FireClient(player, ...)
	end

	local function fireAll(self, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		instance:FireAllClients(...)
	end

	local function fireAllExcept(self, exception, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		for _, player in Players:GetPlayers() do
			if player ~= exception then
				instance:FireClient(player, ...)
			end
		end
	end

	local function firePlayers(self, players, ...)
		assert(connected, `Cannot fire destroyed event remote '{name}'`)
		for _, player in players do
			instance:FireClient(player, ...)
		end
	end

	local function destroy()
		if not connected then
			return
		end

		connected = false

		instance:Destroy()
		instance = nil :: never

		table.clear(listeners)
	end

	local remote: types.Remote = {
		name = name,
		type = "event" :: "event",
		connect = connect,
		fire = fire,
		fireAll = fireAll,
		fireAllExcept = fireAllExcept,
		firePlayers = firePlayers,
		destroy = destroy,
	}

	local emit = compose(builder.metadata.middleware)(function(...): ()
		for _, listener in listeners do
			task.spawn(listener, ...)
		end
	end, remote)

	instance.OnServerEvent:Connect(function(player: Player, ...)
		for index, validator in builder.metadata.parameters do
			local value = select(index, ...)
			assert(validator(value), `Invalid parameter #{index} for event remote '{name}': got {value}`)
		end

		emit(player, ...)
	end)

	return remote
end

return createRemote
