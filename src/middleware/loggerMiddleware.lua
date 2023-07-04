local types = require(script.Parent.Parent.types)

local function stringify(...)
	local args = table.pack(...)

	for index, value in ipairs(args) do
		if type(value) == "string" then
			args[index] = string.format("%q", value)
		elseif type(value) == "userdata" then
			args[index] = `{typeof(value)}({value})`
		end

		args[index] = `\n\t{index}. {args[index]}`
	end

	return table.unpack(args, 1, args.n)
end

local loggerMiddleware: types.Middleware = function(next, remote)
	return function(...)
		if remote.type == "event" then
			print(`[Remo] {remote.name} fired:`, stringify(...))
			return next(...)
		end

		print(`[Remo] {remote.name} request:`, stringify(...))

		local result = table.pack(next(...))

		print(`[Remo] {remote.name} response:`, stringify(table.unpack(result, 1, result.n)))

		return table.unpack(result, 1, result.n)
	end
end

return loggerMiddleware
