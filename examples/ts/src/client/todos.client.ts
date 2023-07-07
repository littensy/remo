import { getRandomName } from "shared/names";
import { remotes } from "shared/remotes";

let todos: readonly string[] = [];

function addTodo() {
	remotes.addTodo.fire(getRandomName());
}

function removeTodo() {
	if (!todos.isEmpty()) {
		const index = math.random(0, todos.size() - 1);
		remotes.removeTodo.fire(todos[index]);
	}
}

remotes.getTodos.request().then((newTodos) => {
	todos = newTodos;
	print(`New todos: ${newTodos.join(", ")}`);

	for (const _ of $range(1, 3)) {
		addTodo();
	}
});

remotes.todosChanged.connect((newTodos) => {
	todos = newTodos;
	print(`New todos: ${newTodos.join(", ")}`);
});

// eslint-disable-next-line no-constant-condition
while (true) {
	task.wait(math.random(1, 3));

	if (math.random() > 0.5) {
		addTodo();
	} else {
		removeTodo();
	}
}
