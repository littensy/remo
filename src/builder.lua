local types = require(script.Parent.types)

local function remote(...: types.Validator): types.RemoteBuilder
	local builder: types.RemoteBuilder

	local metadata: types.RemoteBuilderMetadata = {
		parameters = { ... },
		returns = {},
		middleware = {},
	}

	local function returns(...)
		builder.type = "function"
		metadata.returns = { ... }
		return builder
	end

	local function middleware(...)
		for index = 1, select("#", ...) do
			table.insert(metadata.middleware, (select(index, ...)))
		end
		return builder
	end

	builder = {
		type = "event",
		metadata = metadata,
		returns = returns,
		middleware = middleware,
	}

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
