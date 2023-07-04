local types = require(script.Parent.Parent.types)

local function compose(middlewares: { types.Middleware }): types.Middleware
	local length = #middlewares

	if length == 0 then
		return function(next)
			return next
		end
	elseif length == 1 then
		return middlewares[1]
	end

	return function(next, ...)
		for index = length, 1, -1 do
			next = middlewares[index](next, ...)
		end

		return next
	end
end

return compose
