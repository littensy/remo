local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Shared.remotes)
local names = require(ReplicatedStorage.Shared.names)

local todos: { string } = {}

local function addTodo()
	remotes.addTodo:fire(names.getRandomName())
end

local function removeTodo()
	if #todos > 0 then
		remotes.removeTodo:fire(todos[math.random(#todos)])
	end
end

remotes.getTodos:request():andThen(function(serverTodos)
	todos = serverTodos
	print("New todos:", table.concat(todos, ", "))

	for _ = 1, 3 do
		addTodo()
	end
end)

remotes.todosChanged:connect(function(serverTodos)
	todos = serverTodos
	print("New todos:", table.concat(todos, ", "))
end)

while true do
	task.wait(math.random(1, 3))

	if math.random() > 0.5 then
		addTodo()
	else
		removeTodo()
	end
end
