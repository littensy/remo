return function()
	local RunService = game:GetService("RunService")

	local types = require(script.Parent.Parent.types)
	local createRemotes = require(script.Parent.Parent.createRemotes)
	local builder = require(script.Parent.Parent.builder)
	local instances = require(script.Parent.Parent.utils.instances)
	local throttleMiddleware = require(script.Parent.throttleMiddleware)

	local function pause(frames: number?)
		local counter = frames or 1
		local thread = coroutine.running()
		local connection

		connection = RunService.Heartbeat:Connect(function()
			counter -= 1
			if counter <= 0 then
				connection:Disconnect()
				task.defer(thread)
			end
		end)

		coroutine.yield()
	end

	describe("event throttle", function()
		local remotes, remote: types.ClientToServer, instance: RemoteEvent

		local function create(options: throttleMiddleware.ThrottleMiddlewareOptions)
			remotes = createRemotes({ remote = builder.remote() }, throttleMiddleware(options))
			remote = remotes.remote
			instance = instances.createRemoteEvent("remote", false)
		end

		afterEach(function()
			remotes:destroy()
		end)

		it("should throttle subsequent calls", function()
			local calls = 0

			create({ throttle = 0, trailing = false })

			remote:connect(function()
				calls += 1
			end)

			for _ = 1, 5 do
				instance:FireServer()
			end
			expect(calls).to.equal(1)

			pause()

			for _ = 1, 5 do
				instance:FireServer()
			end
			expect(calls).to.equal(2)
		end)

		it("should emit trailing calls", function()
			local calls = 0

			create({ throttle = 0, trailing = true })

			remote:connect(function()
				calls += 1
			end)

			for _ = 1, 5 do
				instance:FireServer()
			end
			expect(calls).to.equal(1)

			pause()
			expect(calls).to.equal(2)

			for _ = 1, 5 do
				instance:FireServer()
			end
			expect(calls).to.equal(3)

			pause()
			expect(calls).to.equal(4)
		end)

		it("should pass the latest arguments to the trailing call", function()
			local calls = 0
			local arg1, arg2

			create({ throttle = 0, trailing = true })

			remote:connect(function(_, a, b)
				calls += 1
				arg1, arg2 = a, b
			end)

			for i = 1, 5 do
				instance:FireServer(i, i + 1)
			end
			instance:FireServer("a", "b")

			expect(calls).to.equal(1)
			expect(arg1).to.be.a("number")
			expect(arg2).to.be.a("number")

			pause()
			expect(calls).to.equal(2)
			expect(arg1).to.equal("a")
			expect(arg2).to.equal("b")

			instance:FireServer("c", "d")
			expect(calls).to.equal(3)
			expect(arg1).to.equal("c")
			expect(arg2).to.equal("d")

			pause()
			expect(calls).to.equal(4)
			expect(arg1).to.equal("c")
			expect(arg2).to.equal("d")
		end)

		it("should receive a throttle time as options", function()
			local calls = 0

			create(0)

			remote:connect(function()
				calls += 1
			end)

			for _ = 1, 5 do
				instance:FireServer()
			end
			expect(calls).to.equal(1)

			pause()

			for _ = 1, 5 do
				instance:FireServer()
			end
			expect(calls).to.equal(2)
		end)
	end)

	describe("async throttle", function()
		local remotes, remote: types.ServerAsync, instance: RemoteFunction

		local function create(options: throttleMiddleware.ThrottleMiddlewareOptions)
			remotes = createRemotes({ remote = builder.remote().returns() }, throttleMiddleware(options))
			remote = remotes.remote
			instance = instances.createRemoteFunction("remote")
		end

		local function didYield(callback: () -> any)
			local blocked = true
			local success, result

			task.spawn(function()
				success, result = pcall(callback)
				blocked = false
			end)

			assert(success or success == nil, result)

			return blocked
		end

		afterEach(function()
			remotes:destroy()
		end)

		it("should throttle subsequent calls", function()
			local calls = 0

			create({ throttle = 0 })

			remote:onRequest(function(): ()
				calls += 1
			end)

			for _ = 1, 5 do
				instance:InvokeServer()
			end
			expect(calls).to.equal(1)

			pause()

			for _ = 1, 5 do
				instance:InvokeServer()
			end
			expect(calls).to.equal(2)
		end)

		it("should return the cached value when throttled", function()
			local acc = 0

			create({ throttle = 0 })

			remote:onRequest(function(): number
				acc += 1
				return acc
			end)

			expect(instance:InvokeServer()).to.equal(1)
			for _ = 1, 5 do
				expect(instance:InvokeServer()).to.equal(1)
			end

			pause()

			expect(instance:InvokeServer()).to.equal(2)
			for _ = 1, 5 do
				expect(instance:InvokeServer()).to.equal(2)
			end
		end)

		it("should throw if the initial cache is not ready", function()
			create({ throttle = 0 })

			remote:onRequest(function(): ()
				pause()
			end)

			task.spawn(function()
				instance:InvokeServer()
			end)

			expect(function()
				instance:InvokeServer()
			end).to.throw()
		end)

		it("should return the cached value if a request is still pending", function()
			local acc = 0

			create({ throttle = 0 })

			remote:onRequest(function(): number
				-- set cache synchronously on first request
				if acc > 0 then
					pause()
				end
				acc += 1
				return acc
			end)

			expect(didYield(function(): ()
				-- initialize cache immediately
				expect(instance:InvokeServer()).to.equal(1)
			end)).to.equal(false)

			expect(didYield(function(): ()
				-- throttle not over, return cached value
				expect(instance:InvokeServer()).to.equal(1)
				expect(instance:InvokeServer()).to.equal(1)
			end)).to.equal(false)

			pause()

			expect(didYield(function(): ()
				-- make a new request, it will eventually return 2
				expect(instance:InvokeServer()).to.equal(2)
			end)).to.equal(true)

			expect(didYield(function(): ()
				-- throttle not over, return cached value
				expect(instance:InvokeServer()).to.equal(1)
				expect(instance:InvokeServer()).to.equal(1)
			end)).to.equal(false)
		end)

		it("should throttle if the handler throws an error", function()
			local acc = 0

			create({ throttle = 0 })

			remote:onRequest(function(): number
				acc += 1
				assert(acc ~= 1, "error")
				return acc
			end)

			expect(function()
				instance:InvokeServer() -- handler error
			end).to.throw()

			expect(function()
				instance:InvokeServer() -- throttle error
			end).to.throw()

			pause()

			expect(instance:InvokeServer()).to.equal(2)
			for _ = 1, 5 do
				expect(instance:InvokeServer()).to.equal(2)
			end

			pause()

			expect(instance:InvokeServer()).to.equal(3)
			for _ = 1, 5 do
				expect(instance:InvokeServer()).to.equal(3)
			end
		end)
	end)
end
