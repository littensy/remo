local types = require(script.Parent.types)
local constants = require(script.Parent.constants)
local client = require(script.Parent.client)
local server = require(script.Parent.server)

local function deepApplyMiddleware(builders: types.RemoteBuilders, ...: types.Middleware)
	for _, builder in builders do
		if builder.type == "namespace" then
			deepApplyMiddleware(builder.remotes, ...)
		else
			builder.middleware(...)
		end
	end
end

local function createRemotes<Map>(builders: types.RemoteBuilders, ...: types.Middleware): types.Remotes<Map>
	local self = {} :: types.Remotes<Map>

	deepApplyMiddleware(builders, ...)

	local map = if constants.IS_SERVER then server.createRemotes(builders) else client.createRemotes(builders)

	local function recursiveDestroy(values: any)
		for _, value in values do
			if type(value) ~= "table" then
				return
			end

			if value.destroy then
				value:destroy()
			else
				recursiveDestroy(value)
			end
		end
	end

	function self:destroy()
		recursiveDestroy(map)
	end

	for key, value in map do
		(self :: {})[key] = value
	end

	return self
end

return createRemotes
