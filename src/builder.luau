local types = require(script.Parent.types)

local function remote(...: types.Validator): types.RemoteBuilder
	local metadata: types.RemoteBuilderMetadata = {
		parameters = { ... },
		returns = {},
		middleware = {},
		unreliable = false,
	}

	local self = {
		type = "event",
		metadata = metadata,
	} :: types.RemoteBuilder

	function self.returns(...)
		self.type = "function"
		metadata.returns = { ... }
		return self
	end

	function self.middleware(...)
		for index = 1, select("#", ...) do
			table.insert(metadata.middleware, (select(index, ...)))
		end
		return self
	end

	function self.unreliable()
		metadata.unreliable = true
		return self
	end

	return self
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
