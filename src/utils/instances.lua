local Promise = require(script.Parent.Parent.Promise)
local constants = require(script.Parent.Parent.constants)
local mockRemotes = require(script.Parent.mockRemotes)

local container = script.Parent.Parent.container

local function promiseRemoteFunction(name: string): Promise.Promise<RemoteFunction>
	if container:FindFirstChild(name) then
		return Promise.resolve(container[name])
	end

	if constants.IS_EDIT then
		return Promise.resolve(mockRemotes.createMockRemoteFunction(name))
	end

	return Promise.fromEvent(container.ChildAdded, function(child)
		return child:IsA("RemoteFunction") and child.Name == name
	end)
end

local function promiseRemoteEvent(name: string): Promise.Promise<RemoteEvent>
	if container:FindFirstChild(name) then
		return Promise.resolve(container[name])
	end

	if constants.IS_EDIT then
		return Promise.resolve(mockRemotes.createMockRemoteEvent(name))
	end

	return Promise.fromEvent(container.ChildAdded, function(child)
		return child:IsA("RemoteEvent") and child.Name == name
	end)
end

local function createRemoteFunction(name: string): RemoteFunction
	if container:FindFirstChild(name) then
		return container[name]
	end

	if constants.IS_EDIT then
		return mockRemotes.createMockRemoteFunction(name)
	end

	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = name
	remoteFunction.Parent = container

	return remoteFunction
end

local function createRemoteEvent(name: string, unreliable: boolean): RemoteEvent
	if container:FindFirstChild(name) then
		return container[name]
	end

	if constants.IS_EDIT then
		return mockRemotes.createMockRemoteEvent(name)
	end

	local remoteEvent = Instance.new(if unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = container

	return remoteEvent :: RemoteEvent
end

return {
	promiseRemoteFunction = promiseRemoteFunction,
	promiseRemoteEvent = promiseRemoteEvent,
	createRemoteFunction = createRemoteFunction,
	createRemoteEvent = createRemoteEvent,
}
