local types = require(script.Parent.types)

local function remote(...: types.Validator): types.RemoteBuilder
	local metadata: types.RemoteBuilderMetadata = {
		parameters = { ... },
		returns = nil,
		middleware = {},
	}

	local builder = {
		type = "remote",
		metadata = metadata,
	} :: types.RemoteBuilder

	function builder.returns(validator: types.Validator): types.RemoteBuilder
		metadata.returns = validator
		return builder
	end

	function builder.middleware(...: types.Middleware): types.RemoteBuilder
		for _, middleware in { ... } do
			table.insert(metadata.middleware, middleware)
		end
		return builder
	end

	return builder
end

local function namespace(remotes: types.RemoteBuilders): types.RemoteNamespace
	return {
		type = "namespace",
		remotes = remotes,
	}
end

return {
	remote = remote,
	namespace = namespace,
}
