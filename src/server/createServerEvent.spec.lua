return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local remote = require(script.Parent.Parent.remote)
	local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)
	local createServerEvent = require(script.Parent.createServerEvent)

	local serverEvent, instance

	beforeEach(function()
		serverEvent = createServerEvent("test", remote(t.string, t.number))
		instance = mockRemotes.createMockRemoteEvent("test")
	end)

	afterEach(function()
		serverEvent:destroy()
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

		serverEvent:connect(function(...)
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

		serverEvent:fireAll("test", 1)
		expect(a).to.equal("test")
		expect(b).to.equal(1)

		serverEvent:fireAll("test2", 2)
		expect(a).to.equal("test2")
		expect(b).to.equal(2)
	end)

	it("should throw when used after destruction", function()
		serverEvent:destroy()

		expect(function()
			serverEvent:fireAll("test", 1)
		end).to.throw()

		expect(function()
			serverEvent:connect(function() end)
		end).to.throw()
	end)

	it("should not fire disconnected events", function()
		local fired = false
		local disconnect = serverEvent:connect(function()
			fired = true
		end)
		disconnect()
		serverEvent:fireAll("test", 1)
		expect(fired).to.equal(false)
	end)

	it("should apply the middleware", function()
		local middlewareServerEvent, player, arg1, arg2

		serverEvent = createServerEvent(
			"test",
			remote(t.string, t.number).middleware(function(next, serverEvent)
				middlewareServerEvent = serverEvent
				return function(player, ...)
					return next(player, "intercepted", 2)
				end
			end)
		)

		expect(middlewareServerEvent).to.equal(serverEvent)

		serverEvent:connect(function(...)
			player, arg1, arg2 = ...
		end)

		instance:FireServer("test", 1)

		expect(player).to.be.ok()
		expect(arg1).to.equal("intercepted")
		expect(arg2).to.equal(2)
	end)
end
