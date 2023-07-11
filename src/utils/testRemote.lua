local types = require(script.Parent.Parent.types)

local function createTestRemote(): types.TestRemote
	local listeners: { (...any) -> () } = {}
	local nextListenerId = 0

	local function fire(self, ...)
		for _, listener in listeners do
			listener(...)
		end
	end

	local function onFire(self, listener)
		local id = nextListenerId
		nextListenerId += 1
		listeners[id] = listener

		return function()
			listeners[id] = nil
		end
	end

	local function disconnectAll(self)
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
	local function noop() end

	local handler = noop

	local function request(self, ...)
		return handler(...)
	end

	local function handleRequest(self, newHandler)
		handler = newHandler
	end

	local function hasRequestHandler(self)
		return handler ~= noop
	end

	local function disconnectAll(self)
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
