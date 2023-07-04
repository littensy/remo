local Promise = require(script.Parent.Parent.Promise)

local function unwrap(...)
	if Promise.is(...) then
		return (... :: Promise.Promise):expect()
	end

	return ...
end

return unwrap
