local Players = game:GetService("Players")

local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)
local compose = require(script.Parent.Parent.utils.compose)
local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)

local remotes = script.Parent.Parent.remotes

local function createRemoteEvent(name: string): RemoteEvent
	if remotes:FindFirstChild(name) then
		return remotes[name]
	end

	if constants.IS_EDIT then
		return mockRemotes.createMockRemoteEvent(name)
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = remotes

	return remoteEvent
end

local function createServerEvent(name: string, builder: types.RemoteBuilder): types.ServerEvent
	local instance = createRemoteEvent(name)
	local connected = true

	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local serverEvent: types.ServerEvent = {
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

		fire = function(self, player, ...)
			assert(connected, `Cannot fire destroyed event '{name}'`)
			instance:FireClient(player, ...)
		end,

		fireExcept = function(self, player, ...)
			assert(connected, `Cannot fire destroyed event '{name}'`)
			for _, otherPlayer in Players:GetPlayers() do
				if otherPlayer ~= player then
					instance:FireClient(otherPlayer, ...)
				end
			end
		end,

		firePlayers = function(self, players, ...)
			assert(connected, `Cannot fire destroyed event '{name}'`)
			for _, player in players do
				instance:FireClient(player, ...)
			end
		end,

		fireAll = function(self, ...)
			assert(connected, `Cannot fire destroyed event '{name}'`)
			instance:FireAllClients(...)
		end,

		destroy = function(self)
			if not connected then
				return
			end

			connected = false

			instance:Destroy()
			instance = nil :: never

			table.clear(listeners)
		end,
	}

	local emit = compose(builder.metadata.middleware)(function(...): ()
		for _, listener in listeners do
			task.spawn(listener, ...)
		end
	end, serverEvent)

	instance.OnServerEvent:Connect(function(player: Player, ...)
		for index, validator in builder.metadata.parameters do
			local value = select(index, ...)
			assert(validator(value), `Invalid parameter #{index} for event '{name}': got {value}`)
		end

		emit(player, ...)
	end)

	return serverEvent
end

return createServerEvent
