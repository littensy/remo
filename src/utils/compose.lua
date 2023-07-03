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

	return function(last, ...)
		local next: (...any) -> any

		for index = length, 1, -1 do
			local middleware = middlewares[index]

			if index == length then
				next = middleware
			else
				next = middleware(next, ...)
			end
		end

		return next(last, ...)
	end
end

return compose
