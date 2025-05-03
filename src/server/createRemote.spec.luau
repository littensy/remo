return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local builder = require(script.Parent.Parent.builder)
	local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)
	local createRemote = require(script.Parent.createRemote)

	local remote, instance

	beforeEach(function()
		remote = createRemote("test", builder.remote(t.string, t.number))
		instance = mockRemotes.createMockRemoteEvent("test")
	end)

	afterEach(function()
		remote:destroy()
		instance:Destroy()
	end)

	it("should validate incoming argument types", function()
		expect(function()
			instance:FireServer(1, "")
		end).to.throw()

		expect(function()
			instance:FireServer("")
		end).to.throw()

		expect(function()
			instance:FireServer("", 1)
		end).to.never.throw()
	end)

	it("should receive incoming events", function()
		local player, a, b

		remote:connect(function(...)
			player, a, b = ...
		end)

		instance:FireServer("test", 1)

		expect(player).to.be.ok()
		expect(a).to.equal("test")
		expect(b).to.equal(1)
	end)

	it("should fire outgoing events", function()
		local a, b

		instance.OnClientEvent:Connect(function(...)
			a, b = ...
		end)

		remote:fireAll("test", 1)
		expect(a).to.equal("test")
		expect(b).to.equal(1)

		remote:fireAll("test2", 2)
		expect(a).to.equal("test2")
		expect(b).to.equal(2)
	end)

	it("should throw when used after destruction", function()
		remote:destroy()

		expect(function()
			remote:fireAll("test", 1)
		end).to.throw()

		expect(function()
			remote:connect(function() end)
		end).to.throw()
	end)

	it("should not fire disconnected events", function()
		local fired = false
		local disconnect = remote:connect(function()
			fired = true
		end)
		disconnect()
		remote:fireAll("test", 1)
		expect(fired).to.equal(false)
	end)

	it("should apply the middleware", function()
		local middlewareRemote, player, arg1, arg2

		remote = createRemote(
			"test",
			builder.remote(t.string, t.number).middleware(function(next, remote)
				middlewareRemote = remote
				return function(player)
					return next(player, "intercepted", 2)
				end
			end)
		)

		expect(middlewareRemote).to.equal(remote)

		remote:connect(function(...)
			player, arg1, arg2 = ...
		end)

		instance:FireServer("test", 1)

		expect(player).to.be.ok()
		expect(arg1).to.equal("intercepted")
		expect(arg2).to.equal(2)
	end)

	it("should fire the test listeners", function()
		local test1, test2, arg1, arg2

		remote.test:onFire(function(...)
			test1, test2 = ...
		end)

		instance.OnClientEvent:Connect(function(...)
			arg1, arg2 = ...
		end)

		remote:fireAll("test", 1)

		expect(test1).to.equal(arg1)
		expect(test2).to.equal(arg2)

		test1, test2, arg1, arg2 = nil
		remote.test:disconnectAll()
		remote:fireAll("test", 1)

		expect(test1).to.never.be.ok()
		expect(test2).to.never.be.ok()
		expect(arg1).to.equal("test")
		expect(arg2).to.equal(1)
	end)

	it("should be callable", function()
		local a, b

		instance.OnClientEvent:Connect(function(...)
			a, b = ...
		end)

		remote({}, "test", 1)
		expect(a).to.equal("test")
		expect(b).to.equal(1)
	end)

	it("should promise an event", function()
		local player, a, b

		remote:promise():andThen(function(...)
			player, a, b = ...
		end)

		instance:FireServer("test", 1)

		expect(player).to.be.ok()
		expect(a).to.equal("test")
		expect(b).to.equal(1)
	end)

	it("should promise a predicated event", function()
		local player, a, b

		remote
			:promise(function(_, a)
				return a == "true"
			end)
			:andThen(function(...)
				player, a, b = ...
			end)

		instance:FireServer("false", 2)

		expect(player).to.never.be.ok()
		expect(a).to.never.be.ok()
		expect(b).to.never.be.ok()

		instance:FireServer("true", 1)

		expect(player).to.be.ok()
		expect(a).to.equal("true")
		expect(b).to.equal(1)
	end)
end
