local types = require(script.Parent.Parent.types)
local getSender = require(script.Parent.Parent.getSender)

local function noop() end

local function createTestRemote(): types.TestRemote
	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local function fire(_self, first, ...)
		local shouldOmitPlayer = getSender(first)

		for _, listener in listeners do
			if shouldOmitPlayer then
				listener(...)
			else
				listener(first, ...)
			end
		end
	end

	local function onFire(_self, listener)
		local id = nextListenerId
		nextListenerId += 1
		listeners[id] = listener

		return function()
			listeners[id] = nil
		end
	end

	local function disconnectAll(_self)
		table.clear(listeners)
	end

	local testRemote: types.TestRemote = {
		_fire = fire,
		onFire = onFire,
		disconnectAll = disconnectAll,
	}

	return testRemote
end

local function createTestAsyncRemote(): types.TestAsyncRemote
	local handler: (...any) -> () = noop

	local function request(_self, first, ...)
		return if getSender(first) then handler(...) else handler(first, ...)
	end

	local function handleRequest(_self, newHandler)
		handler = newHandler
	end

	local function hasRequestHandler()
		return handler ~= noop
	end

	local function disconnectAll()
		handler = noop
	end

	local testAsyncRemote: types.TestAsyncRemote = {
		_request = request,
		handleRequest = handleRequest,
		hasRequestHandler = hasRequestHandler,
		disconnectAll = disconnectAll,
	}

	return testAsyncRemote
end

return {
	createTestRemote = createTestRemote,
	createTestAsyncRemote = createTestAsyncRemote,
}
