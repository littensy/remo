import { Client, Server, createRemotes, loggerMiddleware, remote } from "@rbxts/remo";
import { t } from "@rbxts/t";

const todo = t.string;
const todoList = t.array(todo);

export const remotes = createRemotes(
	{
		// add a todo to the server
		addTodo: remote<Server, [name: string]>(todo),

		// remove a todo from the server
		removeTodo: remote<Server, [name: string]>(todo),

		// get all todos from the server
		getTodos: remote<Server, []>().returns<string[]>(todoList),

		// send new todos to clients
		todosChanged: remote<Client, [todos: string[]]>(),
	},
	loggerMiddleware,
);
