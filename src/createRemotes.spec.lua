return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local types = require(script.Parent.types)
	local createRemotes = require(script.Parent.createRemotes)
	local builder = require(script.Parent.builder)
	local mockRemotes = require(script.Parent.utils.mockRemotes)

	local remotes: types.Remotes<{
		event: types.ClientToServer<string, number>,
		callback: types.ServerAsync<(string, number), (string)>,
		namespace: {
			event: types.ClientToServer<string, number>,
			callback: types.ServerAsync<(string, number), (string)>,
		},
	}>

	beforeEach(function()
		-- This runs on the server, so don't test client APIs in this file
		remotes = createRemotes({
			event = builder.remote(t.string, t.number),
			callback = builder.remote(t.string, t.number).returns(t.string),
			namespace = builder.namespace({
				event = builder.remote(t.string, t.number),
				callback = builder.remote(t.string, t.number).returns(t.string),
			}),
		})
	end)

	afterEach(function()
		remotes:destroy()
	end)

	it("should create top-level remotes", function()
		expect(remotes.event).to.be.ok()
		expect(remotes.callback).to.be.ok()
		expect(mockRemotes.getMockRemoteEvent("event")).to.be.ok()
		expect(mockRemotes.getMockRemoteFunction("callback")).to.be.ok()
	end)

	it("should create namespaced remotes", function()
		expect(remotes.namespace.event).to.be.ok()
		expect(remotes.namespace.callback).to.be.ok()
		expect(mockRemotes.getMockRemoteEvent("namespace.event")).to.be.ok()
		expect(mockRemotes.getMockRemoteFunction("namespace.callback")).to.be.ok()
	end)

	it("should fire a top-level event", function()
		local arg1, arg2, arg3

		remotes.event:connect(function(...)
			arg1, arg2, arg3 = ...
		end)

		mockRemotes.createMockRemoteEvent("event"):FireServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
	end)

	it("should fire a namespaced event", function()
		local arg1, arg2, arg3

		remotes.namespace.event:connect(function(...)
			arg1, arg2, arg3 = ...
		end)

		mockRemotes.createMockRemoteEvent("namespace.event"):FireServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
	end)

	it("should invoke a top-level callback", function()
		local arg1, arg2, arg3

		remotes.callback:onRequest(function(...)
			arg1, arg2, arg3 = ...
			return "test"
		end)

		local result = mockRemotes.createMockRemoteFunction("callback"):InvokeServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
		expect(result).to.equal("test")
	end)

	it("should invoke a namespaced callback", function()
		local arg1, arg2, arg3

		remotes.namespace.callback:onRequest(function(...)
			arg1, arg2, arg3 = ...
			return "test"
		end)

		local result = mockRemotes.createMockRemoteFunction("namespace.callback"):InvokeServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
		expect(result).to.equal("test")
	end)

	it("should apply middleware to every remote", function()
		remotes:destroy()
		mockRemotes.destroyAll()

		local callOrder, middlewareRemotes, middlewareArguments = {}, {}, {}

		local function middleware(index: number): types.Middleware
			return function(next, remote)
				table.insert(middlewareRemotes, remote)
				return function(...)
					table.insert(middlewareArguments, { ... })
					table.insert(callOrder, index)
					return next(...)
				end
			end
		end

		remotes = createRemotes({
			event = builder.remote(t.string, t.number),
			callback = builder.remote(t.string, t.number).returns(t.string),
			namespace = builder.namespace({
				event = builder.remote(t.string, t.number),
				callback = builder.remote(t.string, t.number).returns(t.string),
			}),
		}, middleware(1), middleware(2), middleware(3))

		local function test(eventName, callbackName)
			callOrder, middlewareArguments = {}, {}

			mockRemotes.createMockRemoteEvent(eventName):FireServer("test", 1)

			for i = 1, 3 do
				expect(middlewareRemotes[i]).to.be.ok()
				expect(middlewareArguments[i][1]).to.be.ok() -- player
				expect(middlewareArguments[i][2]).to.equal("test")
				expect(middlewareArguments[i][3]).to.equal(1)
				expect(callOrder[i]).to.equal(i)
			end

			callOrder, middlewareArguments = {}, {}

			mockRemotes.createMockRemoteFunction(callbackName):InvokeServer("test", 1)

			for i = 1, 3 do
				expect(middlewareArguments[i][1]).to.be.ok() -- player
				expect(middlewareArguments[i][2]).to.equal("test")
				expect(middlewareArguments[i][3]).to.equal(1)
				expect(callOrder[i]).to.equal(i)
			end
		end

		test("event", "callback")
		test("namespace.event", "namespace.callback")
	end)
end
