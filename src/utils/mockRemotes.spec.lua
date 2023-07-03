return function()
	local mockRemotes = require(script.Parent.mockRemotes)

	afterEach(function()
		mockRemotes.destroyAll()
	end)

	describe("createMockRemoteEvent", function()
		it("should return a RemoteEvent-like object", function()
			local remote = mockRemotes.createMockRemoteEvent("test")
			expect(remote).to.be.ok()
			expect(remote.Name).to.equal("test")
			expect(remote.OnClientEvent).to.be.ok()
			expect(remote.OnServerEvent).to.be.ok()
			expect(remote.FireClient).to.be.ok()
			expect(remote.FireAllClients).to.be.ok()
			expect(remote.FireServer).to.be.ok()
			expect(remote.Destroy).to.be.ok()
		end)

		it("should return the same object for the same name", function()
			local remote1 = mockRemotes.createMockRemoteEvent("test")
			local remote2 = mockRemotes.createMockRemoteEvent("test")
			expect(remote1).to.equal(remote2)
		end)

		it("should fire OnClientEvent listeners", function()
			local remote = mockRemotes.createMockRemoteEvent("test")
			local arguments1, arguments2

			remote.OnClientEvent:Connect(function(...)
				arguments1 = { ... }
			end)

			remote.OnClientEvent:Connect(function(...)
				arguments2 = { ... }
			end)

			remote:FireClient({} :: never, "test", 1)

			expect(arguments1).to.be.ok()
			expect(arguments1[1]).to.equal("test")
			expect(arguments1[2]).to.equal(1)

			expect(arguments2).to.be.ok()
			expect(arguments2[1]).to.equal("test")
			expect(arguments2[2]).to.equal(1)
		end)

		it("should fire OnServerEvent listeners", function()
			local remote = mockRemotes.createMockRemoteEvent("test")
			local arguments1, arguments2

			remote.OnServerEvent:Connect(function(player, ...)
				arguments1 = { player, ... }
			end)

			remote.OnServerEvent:Connect(function(player, ...)
				arguments2 = { player, ... }
			end)

			remote:FireServer("test", 1)

			expect(arguments1).to.be.ok()
			expect(arguments1[1]).to.be.ok()
			expect(arguments1[2]).to.equal("test")
			expect(arguments1[3]).to.equal(1)

			expect(arguments2).to.be.ok()
			expect(arguments1[1]).to.be.ok()
			expect(arguments2[2]).to.equal("test")
			expect(arguments2[3]).to.equal(1)
		end)

		it("should not fire disconnected listeners", function()
			local remote = mockRemotes.createMockRemoteEvent("test")
			local arguments1, arguments2

			local connection = remote.OnServerEvent:Connect(function(player, ...)
				arguments1 = { player, ... }
			end)

			remote.OnServerEvent:Connect(function(player, ...)
				arguments2 = { player, ... }
			end)

			connection:Disconnect()
			remote:FireServer("test", 1)

			expect(arguments1).to.never.be.ok()
			expect(arguments2).to.be.ok()
			expect(arguments2[1]).to.be.ok()
			expect(arguments2[2]).to.equal("test")
			expect(arguments2[3]).to.equal(1)
		end)

		it("should not fire after being destroyed", function()
			local remote = mockRemotes.createMockRemoteEvent("test")
			local arguments

			remote.OnServerEvent:Connect(function(player, ...)
				arguments = { player, ... }
			end)

			remote:Destroy()
			remote:FireServer("test", 1)

			expect(arguments).to.never.be.ok()
		end)

		it("should not fire the wrong listeners", function()
			local client = mockRemotes.createMockRemoteEvent("client")
			local server = mockRemotes.createMockRemoteEvent("server")
			local fired = false

			server.OnServerEvent:Connect(function()
				fired = true
			end)

			client.OnClientEvent:Connect(function()
				fired = true
			end)

			client:FireServer()
			server:FireClient({} :: never)

			expect(fired).to.equal(false)
		end)
	end)

	describe("createMockRemoteFunction", function()
		it("should return a RemoteFunction-like object", function()
			local remote = mockRemotes.createMockRemoteFunction("test")
			expect(remote).to.be.ok()
			expect(remote.Name).to.equal("test")
			expect(remote.OnClientInvoke).to.be.ok()
			expect(remote.OnServerInvoke).to.be.ok()
			expect(remote.InvokeClient).to.be.ok()
			expect(remote.InvokeServer).to.be.ok()
			expect(remote.Destroy).to.be.ok()
		end)

		it("should return the same object for the same name", function()
			local remote1 = mockRemotes.createMockRemoteFunction("test")
			local remote2 = mockRemotes.createMockRemoteFunction("test")
			expect(remote1).to.equal(remote2)
		end)

		it("should invoke the OnClientInvoke callback", function()
			local remote = mockRemotes.createMockRemoteFunction("test")
			local arguments

			function remote.OnClientInvoke(...)
				arguments = { ... }
				return "test"
			end

			local result = remote:InvokeClient({} :: never, 1)

			expect(arguments).to.be.ok()
			expect(arguments[1]).to.equal(1)
			expect(result).to.equal("test")
		end)

		it("should invoke the OnServerInvoke callback", function()
			local remote = mockRemotes.createMockRemoteFunction("test")
			local arguments

			function remote.OnServerInvoke(player, ...)
				arguments = { player, ... }
				return "test"
			end

			local result = remote:InvokeServer(1)

			expect(arguments).to.be.ok()
			expect(arguments[1]).to.be.ok()
			expect(arguments[2]).to.equal(1)
			expect(result).to.equal("test")
		end)

		it("should not invoke after being destroyed", function()
			local remote = mockRemotes.createMockRemoteFunction("test")
			local arguments

			function remote.OnServerInvoke(player, ...)
				arguments = { player, ... }
				return "test"
			end

			remote:Destroy()

			local result = remote:InvokeServer(1)

			expect(arguments).to.never.be.ok()
			expect(result).to.never.be.ok()
		end)

		it("should not invoke the wrong callback", function()
			local client = mockRemotes.createMockRemoteFunction("client")
			local server = mockRemotes.createMockRemoteFunction("server")
			local fired = false

			function server.OnServerInvoke()
				fired = true
			end

			function client.OnClientInvoke()
				fired = true
			end

			client:InvokeServer()
			server:InvokeClient({} :: never)

			expect(fired).to.equal(false)
		end)
	end)
end
