local types = require(script.Parent.types)
local createClientEvent = require(script.createClientEvent)
local createClientFunction = require(script.createClientFunction)

local function createClientRemotes(builders: types.RemoteBuilders, namespace: string?): types.ClientRemotes
	local client: types.ClientRemotes = {}
	local prefix = namespace and `{namespace}.` or ""

	for key, builder in builders do
		client[key] = if builder.type == "namespace"
			then createClientRemotes(builder.remotes, key)
			elseif builder.metadata.returns then createClientFunction(prefix .. key, builder)
			else createClientEvent(prefix .. key, builder)
	end

	return client
end

return {
	createClientRemotes = createClientRemotes,
}
