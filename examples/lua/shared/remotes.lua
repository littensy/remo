local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remo = require(ReplicatedStorage.Packages.Remo)
local t = require(ReplicatedStorage.DevPackages.t)

type Remotes = Remo.Remotes<{
	addTodo: Remo.ClientToServer<string>,
	removeTodo: Remo.ClientToServer<string>,
	getTodos: Remo.ClientToServerAsync<{ string }, ()>,
	todosChanged: Remo.ServerToClient<{ string }>,
}>

local validate = {
	todo = t.string,
	todos = t.array(t.string :: any),
}

local remotes: Remotes = Remo.createRemotes({
	addTodo = Remo.remote(validate.todo),
	removeTodo = Remo.remote(validate.todo),
	getTodos = Remo.remote().returns(validate.todos),
	todosChanged = Remo.remote(validate.todos),
}, Remo.loggerMiddleware)

return remotes
