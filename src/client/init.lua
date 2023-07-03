local types = require(script.Parent.types)
local createClientEvent = require(script.createClientEvent)
local createClientFunction = require(script.createClientFunction)

local function createClientRemotes(builders: types.RemoteBuilders): types.ClientRemotes
	local client: types.ClientRemotes = {}

	for key, builder in builders do
		client[key] = if builder.metadata.returns
			then createClientFunction(key, builder)
			else createClientEvent(key, builder)
	end

	return client
end

return {
	createClientRemotes = createClientRemotes,
}
