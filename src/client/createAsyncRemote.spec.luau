return function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local Promise = require(script.Parent.Parent.Promise)
	local builder = require(script.Parent.Parent.builder)
	local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)
	local createAsyncRemote = require(script.Parent.createAsyncRemote)

	local player: Player = Players.LocalPlayer or {} :: any
	local asyncRemote, instance

	beforeEach(function()
		asyncRemote = createAsyncRemote("test", builder.remote(t.string, t.number).returns(t.string))
		instance = mockRemotes.createMockRemoteFunction("test")
	end)

	afterEach(function()
		asyncRemote:destroy()
		instance:Destroy()
	end)

	it("should validate incoming argument types", function()
		asyncRemote:onRequest(function()
			return ""
		end)

		expect(function()
			instance:InvokeClient(player, 1, "")
		end).to.throw()

		expect(function()
			instance:InvokeClient(player, "")
		end).to.throw()

		expect(function()
			instance:InvokeClient(player, "", 1)
		end).to.never.throw()
	end)

	it("should validate incoming return types", function()
		instance.OnServerInvoke = function()
			return 1 -- bad return type
		end

		expect(function()
			asyncRemote:request("", 1):expect()
		end).to.throw()

		instance.OnServerInvoke = function()
			return "" -- good return type
		end

		expect(function()
			asyncRemote:request("", 1):expect()
		end).to.never.throw()
	end)

	it("should send and receive the correct values", function()
		local player, a, b

		asyncRemote:onRequest(function(...)
			a, b = ...
			return "result"
		end)

		function instance.OnServerInvoke(...)
			player, a, b = ...
			return "result"
		end

		-- incoming invoke
		expect(instance:InvokeClient(player, "test", 1)).to.equal("result")
		expect(player).to.never.be.ok()
		expect(a).to.equal("test")
		expect(b).to.equal(1)

		-- outgoing invoke
		expect(asyncRemote:request("test2", 2):expect()).to.equal("result")
		expect(player).to.be.ok()
		expect(a).to.equal("test2")
		expect(b).to.equal(2)
	end)

	it("should unwrap promises on invoke", function()
		local a, b

		asyncRemote:onRequest(function(...)
			a, b = ...
			return Promise.resolve("result")
		end)

		-- incoming invoke
		expect(instance:InvokeClient(player, "test", 1)).to.equal("result")
		expect(a).to.equal("test")
		expect(b).to.equal(1)
	end)

	it("should throw when used after destruction", function()
		asyncRemote:onRequest(function(): () end)
		asyncRemote:destroy()

		expect(function()
			asyncRemote:request("", 1):expect()
		end).to.throw()

		expect(function()
			instance:InvokeClient(player, "", 1)
		end).to.throw()

		expect(function()
			asyncRemote:onRequest(function(): () end)
		end).to.throw()
	end)

	it("should apply the middleware", function()
		local middlewareRemote, arg1, arg2, result

		asyncRemote = createAsyncRemote(
			"test",
			builder.remote(t.string, t.number).returns(t.string).middleware(function(next, remote)
				middlewareRemote = remote
				return function()
					result = next("intercepted", 2)
					return result .. "!"
				end
			end)
		)

		expect(middlewareRemote).to.equal(asyncRemote)

		asyncRemote:onRequest(function(...)
			arg1, arg2 = ...
			return "result"
		end)

		expect(instance:InvokeClient(player, "test", 1)).to.equal("result!")
		expect(arg1).to.equal("intercepted")
		expect(arg2).to.equal(2)
		expect(result).to.equal("result")
	end)

	it("should support multiple return values", function()
		asyncRemote = createAsyncRemote("test", builder.remote().returns(t.string, t.string, t.string))

		asyncRemote:onRequest(function()
			return Promise.resolve("a", "b", "c")
		end)

		local a, b, c = instance:InvokeClient(player)

		expect(a).to.equal("a")
		expect(b).to.equal("b")
		expect(c).to.equal("c")

		instance.OnServerInvoke = function()
			return "a", "b", "c"
		end

		a, b, c = asyncRemote:request():expect()

		expect(a).to.equal("a")
		expect(b).to.equal("b")
		expect(c).to.equal("c")
	end)

	it("should be callable", function()
		function instance.OnServerInvoke()
			return "result"
		end

		expect(asyncRemote("test", 1):expect()).to.equal("result")
	end)

	it("should invoke the test handler", function()
		local arg1, arg2

		asyncRemote.test:handleRequest(function(...)
			arg1, arg2 = ...
			return "result"
		end)

		expect(asyncRemote:request("test", 1):expect()).to.equal("result")
		expect(arg1).to.equal("test")
		expect(arg2).to.equal(1)

		asyncRemote.test:disconnectAll()

		expect(function()
			asyncRemote:request("test", 1):expect()
		end).to.throw()
	end)
end
