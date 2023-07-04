local types = require(script.Parent.Parent.types)

local function is(value: any): boolean
	return type(value) == "table" and type(value.andThen) == "function"
end

local function expect<T>(promise: types.Thenable<T>): T
	local thread = coroutine.running()
	local traceback = debug.traceback("Expected promise to resolve")
	local success, result

	promise:andThen(function(value)
		success, result = true, value
		coroutine.resume(thread)
	end, function(error): ()
		success, result = false, error
		coroutine.resume(thread)
	end)

	task.delay(10, function()
		if success == nil then
			warn(`Promise did not resolve after 10 seconds; infinite yield possible\n{traceback}`)
		end
	end)

	if success == nil then
		coroutine.yield()
	end

	if not success then
		error(result)
	end

	return result
end

local function unwrap<T>(value: T | types.Thenable<T>): T
	return if is(value) then expect(value :: types.Thenable<T>) else value :: T
end

return {
	expect = expect,
	is = is,
	unwrap = unwrap,
}
