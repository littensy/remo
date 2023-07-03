local types = require(script.Parent.types)
local createServerEvent = require(script.createServerEvent)
local createServerFunction = require(script.createServerFunction)

local function createServerRemotes(builders: types.RemoteBuilders): types.ServerRemotes
	local server: types.ServerRemotes = {}

	for key, builder in builders do
		server[key] = if builder.metadata.returns
			then createServerFunction(key, builder)
			else createServerEvent(key, builder)
	end

	return server
end

return {
	createServerRemotes = createServerRemotes,
}
