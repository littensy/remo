local Players = game:GetService("Players")

local mockRemoteEvents: { [string]: RemoteEvent } = {}
local mockRemoteFunctions: { [string]: RemoteFunction } = {}

local function createMockRemoteEvent(name: string): RemoteEvent
	if mockRemoteEvents[name] then
		return mockRemoteEvents[name]
	end

	local remoteEvent: RemoteEvent = {
		Name = name,
		OnClientEvent = {},
		OnServerEvent = {},
	} :: any

	local clientListeners = {}
	local serverListeners = {}

	function remoteEvent.OnClientEvent:Connect(callback: (any) -> ())
		clientListeners[callback] = true

		return {
			Connected = true,
			Disconnect = function(self: RBXScriptConnection)
				self.Connected = false
				clientListeners[callback] = nil
			end,
		} :: never
	end

	function remoteEvent.OnServerEvent:Connect(callback: (any) -> ())
		serverListeners[callback] = true

		return {
			Connected = true,
			Disconnect = function(self: RBXScriptConnection)
				self.Connected = false
				serverListeners[callback] = nil
			end,
		} :: never
	end

	function remoteEvent:FireClient(_player: Player, ...)
		for callback in clientListeners do
			callback(...)
		end
	end

	function remoteEvent:FireAllClients(...)
		for callback in clientListeners do
			callback(...)
		end
	end

	function remoteEvent:FireServer(...)
		for callback in serverListeners do
			callback(Players.LocalPlayer or {}, ...)
		end
	end

	function remoteEvent:Destroy(): ()
		mockRemoteEvents[name] = nil
		table.clear(clientListeners)
		table.clear(serverListeners)
	end

	mockRemoteEvents[name] = remoteEvent

	return remoteEvent
end

local function createMockRemoteFunction(name: string): RemoteFunction
	if mockRemoteFunctions[name] then
		return mockRemoteFunctions[name]
	end

	local remoteFunction: RemoteFunction = {
		Name = name,
		OnClientInvoke = function() end,
		OnServerInvoke = function() end,
	} :: any

	function remoteFunction:InvokeClient(_player: Player, ...)
		return self.OnClientInvoke(...)
	end

	function remoteFunction:InvokeServer(...)
		return self.OnServerInvoke(Players.LocalPlayer or {} :: any, ...)
	end

	function remoteFunction:Destroy(): ()
		mockRemoteFunctions[name] = nil
		remoteFunction.OnClientInvoke = function() end
		remoteFunction.OnServerInvoke = function() end
	end

	mockRemoteFunctions[name] = remoteFunction

	return remoteFunction
end

local function getMockRemoteEvent(name: string): RemoteEvent?
	return mockRemoteEvents[name]
end

local function getMockRemoteFunction(name: string): RemoteFunction?
	return mockRemoteFunctions[name]
end

local function destroyAll()
	table.clear(mockRemoteEvents)
	table.clear(mockRemoteFunctions)
end

return {
	createMockRemoteEvent = createMockRemoteEvent,
	createMockRemoteFunction = createMockRemoteFunction,
	getMockRemoteEvent = getMockRemoteEvent,
	getMockRemoteFunction = getMockRemoteFunction,
	destroyAll = destroyAll,
}
