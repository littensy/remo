local Promise = require(script.Parent.Parent.Promise)

type Promise<T> = Promise.Promise<T>

local function unwrap<T>(...: Promise<T> | T): T
	if Promise.is(...) then
		return (... :: Promise<T>):expect()
	end

	return (...) :: T
end

return unwrap
