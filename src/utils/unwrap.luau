local Promise = require(script.Parent.Parent.Promise)

type Promise<T> = Promise.Promise<T>

local function unwrap<T, U...>(promise: T | Promise<T>?, ...: U...): (T, U...)
	if Promise.is(promise) then
		return (promise :: Promise<T>):expect()
	end

	return promise :: T, ...
end

return unwrap
