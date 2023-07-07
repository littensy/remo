import { RunService } from "@rbxts/services";
import { remotes } from "shared/remotes";

const todos: string[] = ["Milk", "Eggs"];
let changed = false;

remotes.addTodo.connect((player, todo) => {
	todos.push(todo);
	changed = true;
});

remotes.removeTodo.connect((player, todo) => {
	todos.remove(todos.indexOf(todo));
	changed = true;
});

remotes.getTodos.onRequest((player) => {
	return todos;
});

RunService.Heartbeat.Connect(() => {
	if (changed) {
		changed = false;
		remotes.todosChanged.fireAll(todos);
		print(`New todos: ${todos.join(", ")}`);
	}
});
