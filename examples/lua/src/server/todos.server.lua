local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remotes = require(ReplicatedStorage.Shared.remotes)

local todos: { string } = { "Milk", "Eggs" }
local changed = false

remotes.addTodo:connect(function(player, todo)
	table.insert(todos, todo)
	changed = true
end)

remotes.removeTodo:connect(function(player, todo)
	table.remove(todos, table.find(todos, todo) or -1)
	changed = true
end)

remotes.getTodos:onRequest(function(player)
	return todos
end)

RunService.Heartbeat:Connect(function()
	if changed then
		changed = false
		remotes.todosChanged:fireAll(todos)
		print("New todos:", table.concat(todos, ", "))
	end
end)
