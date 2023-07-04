local Promise = require(script.Parent.Parent.Promise)

local function unwrap(...)
	if Promise.is(...) then
		return (...):expect()
	end

	return ...
end

return unwrap
