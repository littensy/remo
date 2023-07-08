local types = require(script.Parent.types)
local createAsyncRemote = require(script.createAsyncRemote)
local createRemote = require(script.createRemote)

local function createRemotes(builders: types.RemoteBuilders, namespace: string?): types.RemoteMap
	local remotes: types.RemoteMap = {}
	local scope = if namespace then `{namespace}.` else ""

	for name, builder in builders do
		remotes[name] = if builder.type == "namespace"
			then createRemotes(builder.remotes, scope .. name)
			elseif builder.type == "event" then createRemote(scope .. name, builder)
			elseif builder.type == "function" then createAsyncRemote(scope .. name, builder)
			else error(`Invalid remote type "{builder.type}"`)
	end

	return remotes
end

return {
	createRemotes = createRemotes,
}
