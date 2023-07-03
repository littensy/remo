return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local builder = require(script.Parent.Parent.builder)
	local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)
	local createServerFunction = require(script.Parent.createServerFunction)

	local player: Player = Players.LocalPlayer or {}
	local serverFunction, instance

	beforeEach(function()
		serverFunction = createServerFunction("test", builder.remote(t.string, t.number).returns(t.string))
		instance = mockRemotes.createMockRemoteFunction("test")
	end)

	afterEach(function()
		serverFunction:destroy()
		instance:Destroy()
	end)

	it("should throw when invoked without a handler", function()
		expect(function()
			instance:InvokeServer("", 0)
		end).to.throw()
	end)

	it("should validate incoming argument types", function()
		serverFunction:onInvoke(function()
			return ""
		end)

		expect(function()
			instance:InvokeServer(1, "")
		end).to.throw()

		expect(function()
			instance:InvokeServer("")
		end).to.throw()

		expect(function()
			instance:InvokeServer("", 1)
		end).to.never.throw()
	end)

	it("should validate incoming return types", function()
		instance.OnClientInvoke = function()
			return 1 -- bad return type
		end

		expect(function()
			serverFunction:invoke(player, "", 1):expect()
		end).to.throw()

		instance.OnClientInvoke = function()
			return "" -- good return type
		end

		expect(function()
			serverFunction:invoke(player, "", 1):expect()
		end).to.never.throw()
	end)

	it("should send and receive the correct values", function()
		local player, a, b

		serverFunction:onInvoke(function(...)
			player, a, b = ...
			return "result"
		end)

		function instance.OnClientInvoke(...)
			a, b = ...
			return "result"
		end

		-- outgoing invoke
		expect(serverFunction:invoke(player, "test2", 2):expect()).to.equal("result")
		expect(player).to.never.be.ok()
		expect(a).to.equal("test2")
		expect(b).to.equal(2)

		-- incoming invoke
		expect(instance:InvokeServer("test", 1)).to.equal("result")
		expect(player).to.be.ok()
		expect(a).to.equal("test")
		expect(b).to.equal(1)
	end)

	it("should throw when used after destruction", function()
		serverFunction:onInvoke(function(): () end)
		serverFunction:destroy()

		expect(function()
			serverFunction:invoke(player, "", 1):expect()
		end).to.throw()

		expect(function()
			serverFunction:onInvoke(function(): () end)
		end).to.throw()
	end)

	it("should apply the middleware", function()
		local middlewareServerFunction, playerInvoked, arg1, arg2, result

		serverFunction = createServerFunction(
			"test",
			builder.remote(t.string, t.number).returns(t.string).middleware(function(next, serverFunction)
				middlewareServerFunction = serverFunction
				return function(player, ...)
					result = next(player, "intercepted", 2)
					return result .. "!"
				end
			end)
		)

		expect(middlewareServerFunction).to.equal(serverFunction)

		serverFunction:onInvoke(function(...)
			playerInvoked, arg1, arg2 = ...
			return "result"
		end)

		expect(instance:InvokeServer("test", 1)).to.equal("result!")
		expect(playerInvoked).to.be.ok()
		expect(arg1).to.equal("intercepted")
		expect(arg2).to.equal(2)
		expect(result).to.equal("result")
	end)
end
