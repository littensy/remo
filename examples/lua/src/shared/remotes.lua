local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remo = require(ReplicatedStorage.Packages.Remo)
local t = require(ReplicatedStorage.Packages.t)

type Remotes = Remo.Remotes<{
	addTodo: Remo.ClientToServer<string>,
	removeTodo: Remo.ClientToServer<string>,
	getTodos: Remo.ServerAsync<(), ({ string })>,
	todosChanged: Remo.ServerToClient<{ string }>,
}>

local todo = t.string
local todoList = t.array(todo :: any)

local remotes: Remotes = Remo.createRemotes({
	addTodo = Remo.remote(todo),
	removeTodo = Remo.remote(todo),
	getTodos = Remo.remote().returns(todoList),
	todosChanged = Remo.remote(todoList),
}, Remo.loggerMiddleware)

return remotes
