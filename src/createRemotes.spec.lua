return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local types = require(script.Parent.types)
	local createRemotes = require(script.Parent.createRemotes)
	local builder = require(script.Parent.builder)
	local mockRemotes = require(script.Parent.utils.mockRemotes)

	local remotes: types.Remotes<{
		event: types.ClientEvent<string, number>,
		callback: types.ClientFunction<string, string, number>,
		namespace: {
			event: types.ClientEvent<string, number>,
			callback: types.ClientFunction<string, string, number>,
		},
	}, {
		event: types.ServerEvent<string, number>,
		callback: types.ServerFunction<string, string, number>,
		namespace: {
			event: types.ServerEvent<string, number>,
			callback: types.ServerFunction<string, string, number>,
		},
	}>

	beforeEach(function()
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
		expect(remotes.client.event).to.be.ok()
		expect(remotes.client.callback).to.be.ok()
		expect(remotes.server.event).to.be.ok()
		expect(remotes.server.callback).to.be.ok()
		expect(remotes.server.callback.name).to.equal("callback")
		expect(mockRemotes.getMockRemoteEvent("event")).to.be.ok()
		expect(mockRemotes.getMockRemoteFunction("callback")).to.be.ok()
	end)

	it("should create namespace remotes", function()
		expect(remotes.client.namespace.event).to.be.ok()
		expect(remotes.client.namespace.callback).to.be.ok()
		expect(remotes.server.namespace.event).to.be.ok()
		expect(remotes.server.namespace.callback).to.be.ok()
		expect(mockRemotes.getMockRemoteEvent("namespace.event")).to.be.ok()
		expect(mockRemotes.getMockRemoteFunction("namespace.callback")).to.be.ok()
	end)
end
