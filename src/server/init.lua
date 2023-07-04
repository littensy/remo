local types = require(script.Parent.types)
local createAsyncRemote = require(script.createAsyncRemote)
local createRemote = require(script.createRemote)

local function createRemotes(builders: types.RemoteBuilders): types.RemoteMap
	local remotes: types.RemoteMap = {}

	for name, builder in builders do
		remotes[name] = if builder.type == "namespace"
			then createRemotes(builder.remotes)
			elseif builder.type == "event" then createRemote(name, builder)
			elseif builder.type == "function" then createAsyncRemote(name, builder)
			else error(`Invalid remote type "{builder.type}"`)
	end

	return remotes
end

return {
	createRemotes = createRemotes,
}
