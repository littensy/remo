local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)
local getSender = require(script.Parent.Parent.getSender)

local SERVER = "(SERVER)"

export type ThrottleMiddlewareOptions = {
	throttle: number?,
	trailing: boolean?,
	[any]: any,
} | number

local function timeout<T...>(callback: (T...) -> (), amount: number): () -> ()
	local timer = 0
	local connection

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		timer += deltaTime
		if timer >= amount then
			connection:Disconnect()
			callback()
		end
	end)

	return function()
		connection:Disconnect()
	end
end

local function throttleMiddleware(options: ThrottleMiddlewareOptions?): types.Middleware
	local throttle = 0.1
	local trailing = false

	if type(options) == "number" then
		throttle = options
	elseif type(options) == "table" then
		throttle = if options.throttle ~= nil then options.throttle else throttle
		trailing = if options.trailing ~= nil then options.trailing else trailing
	end

	local eventMiddleware: types.Middleware = function(next, remote)
		local timeouts: { [string]: () -> () } = {}
		local cache: { [string]: { [number]: unknown, n: number } } = {}

		return function(...)
			local sender = getSender(...)
			local senderId = if sender then sender.Name else SERVER
			local timeoutId = timeouts[senderId]

			cache[senderId] = table.pack(...)

			if timeoutId then
				if not constants.IS_TEST and constants.IS_STUDIO then
					warn(`🔴 throttled remote '{remote.name}' fired by '{senderId}'`)
				end
				return
			end

			timeouts[senderId] = timeout(function()
				local arguments = cache[senderId]
				timeouts[senderId] = nil
				cache[senderId] = nil

				if trailing then
					next(table.unpack(arguments, 1, arguments.n))
				end
			end, throttle)

			return next(...)
		end
	end

	local asyncMiddleware: types.Middleware = function(next, remote)
		local timeouts: { [string]: () -> () } = {}
		local cache: { [string]: { [number]: unknown, n: number } } = {}
		local pending: { [string]: boolean } = {}
		local watching: { [string]: Promise.Promise } = {}

		local function clearCacheOnPlayerDisconnect(sender: Player)
			if watching[sender.Name] then
				return
			end

			watching[sender.Name] = Promise.fromEvent(Players.PlayerRemoving, function(player)
				return player == sender
			end):andThen(function()
				timeouts[sender.Name] = nil
				cache[sender.Name] = nil
				pending[sender.Name] = nil
				watching[sender.Name] = nil
			end)
		end

		return function(...)
			local sender = getSender(...)
			local senderId = if sender then sender.Name else SERVER

			local timeoutId = timeouts[senderId]
			local isPending = pending[senderId]

			if sender then
				clearCacheOnPlayerDisconnect(sender)
			end

			if timeoutId or isPending then
				-- async remotes should try to return the previous value before
				-- rejecting the request
				local results =
					assert(cache[senderId], `🔴 throttled remote '{remote.name}' requested by '{senderId}'`)
				return table.unpack(results, 1, results.n)
			end

			pending[senderId] = true

			local ok, results = pcall(function(...)
				return table.pack(next(...))
			end, ...)

			pending[senderId] = nil

			timeouts[senderId] = timeout(function()
				timeouts[senderId] = nil
			end, throttle)

			assert(ok, results)

			cache[senderId] = results

			return table.unpack(results, 1, results.n)
		end
	end

	return function(next, remote)
		if remote.type == "event" then
			return eventMiddleware(next, remote)
		elseif remote.type == "function" then
			return asyncMiddleware(next, remote)
		else
			return next
		end
	end
end

return throttleMiddleware
