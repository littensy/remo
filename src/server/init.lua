local types = require(script.Parent.types)
local createServerEvent = require(script.createServerEvent)
local createServerFunction = require(script.createServerFunction)

local function createServerRemotes(builders: types.RemoteBuilders, namespace: string?): types.ServerRemotes
	local server: types.ServerRemotes = {}
	local prefix = namespace and `{namespace}.` or ""

	for key, builder in builders do
		server[key] = if builder.type == "namespace"
			then createServerRemotes(builder.remotes, key)
			elseif builder.metadata.returns then createServerFunction(prefix .. key, builder)
			else createServerEvent(prefix .. key, builder)
	end

	return server
end

return {
	createServerRemotes = createServerRemotes,
}
