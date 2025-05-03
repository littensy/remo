local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)

local SCOPE = constants.IS_SERVER and "client → server" or "server → client"

local function stringify(...)
	local output = {}

	for index = 1, select("#", ...) do
		local value = select(index, ...)

		table.insert(output, `{if index > 1 then "\n" else ""}\t{index}.`)

		if type(value) == "string" then
			table.insert(output, string.format("%q", value))
		elseif type(value) == "userdata" then
			table.insert(output, `{typeof(value)}({value})`)
		else
			table.insert(output, value)
		end
	end

	if #output == 0 then
		return "\t1. (void)\n"
	end

	table.insert(output, "\n")

	return table.unpack(output)
end

local loggerMiddleware: types.Middleware = function(next, remote)
	return function(...)
		if remote.type == "event" then
			print(`\n🟡 ({SCOPE}) {remote.name}\n\n`, stringify(...))
			return next(...)
		end

		print(`\n🟣 ({SCOPE} async) {remote.name}\n`)
		print(`Parameters\n`, stringify(...))

		local results = table.pack(next(...))

		print("Returns\n", stringify(table.unpack(results, 1, results.n)))

		return table.unpack(results, 1, results.n)
	end
end

return loggerMiddleware
