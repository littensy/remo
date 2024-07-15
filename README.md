# ⚡️ Remo

Remo is a simple and type-safe remote library for Roblox.

It's easy to set up events and asynchronous functions that are ready for use.

---

## 🔥 Quick Start

Call `createRemotes` to initialize your remote objects.

Declare a remote by calling `remote`, or create a namespace by calling `namespace`.

```ts
// TypeScript
const remotes = createRemotes({
	// An event processed on the client
	event: remote<Client, [value: number]>(t.number),

	// A function whose value is processed by the server
	async: remote<Server, [value: number]>(t.number).returns<string>(t.string),

	// An event fired to a client, with logging
	logged: remote<Client, [value: number]>(t.number).middleware(loggerMiddleware),
});

remotes.event.connect((value) => print(value));

remotes.async.request(123).then((value) => print(value));
```

```lua
-- Luau
type Remotes = {
	-- An event processed on the client
	event: Remo.ServerToClient<number>,

	-- A function whose result, a string, is processed on the server
	async: Remo.ServerAsync<(number), (string)>,

	-- An event fired to a client, with logging
	logged: Remo.ServerToClient<number>,
}

local remotes: Remotes = Remo.createRemotes({
	event = Remo.remote(t.number),
	async = Remo.remote(t.number).returns(t.string),
	logged = Remo.remote(t.number).middleware(loggerMiddleware),
})

remotes.event:connect(print)

remotes.async:request(123):andThen(print)
```

---

## 📦 Installation

### Roblox-TS

[Take me to the NPM package →](https://www.npmjs.com/package/@rbxts/remo)

```bash
npm install @rbxts/remo
yarn add @rbxts/remo
pnpm add @rbxts/remo
```

### Wally

[Take me to the Wally package →](https://wally.run/package/littensy/remo)

```toml
[dependencies]
Remo = "littensy/remo@VERSION"
```

---

## ✨ Features

- 📚 Remote events and functions are fully type-checked and support Luau autocompletion.

- 🔐 Validate arguments and return values with [`t`](https://github.com/osyrisrblx/t).

- ⚛️ Declare your remotes in one place and use them anywhere.

- 🛟 Safe to use in Hoarcekat or other environments outside of a running Roblox game.

---

## 📖 Usage

See the [examples](examples) folder for more detailed examples.

### 🔌 Creating remotes

`createRemotes` is used to create a set of remotes. It receives the remote schema, which is an object that maps remote names to their definitions created by `remote`:

- `remote<Mode, Args>(...validators?)` creates a remote event with the given argument types. If validators are provided, they will be used to validate the arguments passed to the event.

- `remote(...).returns<Result>(...validators?)` creates a remote function with the given argument and return types. If validators are provided, the return value will be validated before the promise is resolved.

- `namespace(schema)` creates a nested namespace of remotes.

```ts
// TypeScript
const remotes = createRemotes({
	event: remote<Client, [value: number]>(t.number),
	async: remote<Server, [value: number]>(t.number).returns<string>(t.string),
	namespace: namespace({
		event: remote<Client, [value: number]>(t.number),
		async: remote<Server, [value: number]>(t.number).returns<string>(t.string),
	}),
});
```

```lua
-- Luau
local remotes: Remotes = Remo.createRemotes({
	event = Remo.remote(t.number),
	async = Remo.remote(t.number).returns(t.string),
	namespace = Remo.namespace({
		event = Remo.remote(t.number),
		async = Remo.remote(t.number).returns(t.string),
	}),
})
```

---

### 🛟 Type safety

#### TypeScript

In TypeScript, [`t`](https://github.com/osyrisrblx/t) is recommended to ensure remotes can only be called with the correct arguments, but it is optional.

`remote` receives either a `Client` or `Server` flag that is used to specify whether the remote is processed by the client or the server.

```ts
const remotes = createRemotes({
	// event processed on the client and fired by the server
	client: remote<Client, [value: number]>(t.number),

	// event processed on the server and fired by the client
	server: remote<Server, [value: number]>(t.number),
});
```

#### Luau

In Luau, for full type-checking in your editor, you will need to define a separate type for your remotes using the following types:

- `ClientToServer<Args...>`: A remote event that is fired by the client and processed by the server.

- `ServerToClient<Args...>`: A remote event that is fired by the server and processed by the client.

- `ServerAsync<Args..., Returns...>`: A remote function that is invoked by the client and processed by the server.

- ~~`ClientAsync<Args..., Returns...>`~~: A remote function that is invoked by the server and processed by the client. Not recommended, as requesting values from the client is unsafe.

```lua
type Remotes = {
	client: Remo.ServerToClient<number>,
	server: Remo.ClientToServer<number>,
	serverAsync: Remo.ServerAsync<(number), (string)>,
	namespace: {
		client: Remo.ServerToClient<number>,
		server: Remo.ClientToServer<number>,
	}
}

local remotes: Remotes = Remo.createRemotes({
	client = Remo.remote(t.number),
	server = Remo.remote(t.number),
	serverAsync = Remo.remote(t.number).returns(t.string),
	namespace = Remo.namespace({
		client = Remo.remote(t.number),
		server = Remo.remote(t.number),
	}),
})
```

Defining two-way remotes is not recommended in Luau, as it would require function overloads that may affect intellisense.

---

### 📡 Using remotes

#### 🟡 Events

`fire` is analogous to `FireServer` and `FireClient`. It sends the given arguments over the remote event to be processed on the other side.

```lua
-- client -> server
remotes.event:fire(...);

-- server -> client
remotes.event:fire(player, ...);
remotes.event:fireAll(...);
remotes.event:fireAllExcept(player, ...);
remotes.event:firePlayers(players, ...);
```

To listen for events, use `connect` to connect a callback to the remote event. If validators are provided, they must all pass before the listeners are called.

```lua
-- client -> server
local disconnect = remotes.event:connect(function(player, ...)
	print(player, ...)
end)

-- server -> client
local disconnect = remotes.event:connect(function(...)
	print(...)
end)
```

#### 🟣 Async functions

Similar to InvokeClient and InvokeServer, `request` is used to invoke a remote function. It sends the given arguments over the remote function to be processed on the other side, and returns a promise that resolves with the return value of the function.

Arguments are validated before the handler is called, and the return value is validated before the promise is resolved.

```lua
-- client -> server async
remotes.async:request(...):andThen(function(result)
	print(result)
end)

-- server -> client async
remotes.async:request(player, ...):andThen(function(result)
	print(result)
end)
```

To bind a handler to a remote function, use `onRequest`. If validators are provided, they must all pass before the handler is called.

The handler can return a value or a promise that resolves with a value. If the handler throws an error or the promise rejects, the caller will receive it as a promise rejection.

```lua
-- client -> server async
remotes.async:onRequest(function(player, ...)
	return result
end)

-- server -> client async
remotes.async:onRequest(function(...)
	return result
end)
```

Roblox-TS will automatically hide client- or server-only APIs based on whether you are using them on the client or on the server. However, this is not currently implemented in Luau, so take precautions to ensure you are calling `fire` or `connect` on the correct side.

---

### ⛓️ Middleware

Middleware can be used to intercept and modify arguments and return values before they are processed. This can be used to implement features such as logging, rate limiting, or more complex validation.

#### 📦 Built-in middleware

- `loggerMiddleware` creates detailed logs of the arguments and return value of a remote invocation.

- `throttleMiddleware(options?)` prevents a remote from being invoked more than once every `throttle` seconds.
  - If `trailing` is true, the last event will be fired again after the throttle period has passed. Does not apply to async functions.
  - If an async remote is throttled, or it is not done processing the last request, the promise will resolve with the result of the last invocation. If there is no previous value available, the promise will reject.

#### 🧱 Creating middleware

Middleware is defined as a function that receives the next middleware in the chain and the remote it was called for. It returns a function that will be called when the remote is invoked, and depending on how it invokes the next middleware, it can modify the arguments and return value.

Here's an example middleware function that logs the arguments and return value of a remote:

```ts
// TypeScript
const loggerMiddleware: RemoMiddleware = (next, remote) => {
	return (...args: unknown[]) => {
		if (remote.type === "event") {
			print(`${remote.name} fired with arguments:`, ...args);
			return next(...args);
		}

		print(`${remote.name} called with arguments:`, ...args);

		const result = next(...args);

		print(`${remote.name} returned:`, result);

		return result;
	};
};
```

```lua
-- Luau
local loggerMiddleware: Remo.Middleware = function(next, remote)
	return function(...)
		if remote.type == "event" then
			print(`{remote.name} fired with arguments:`, ...)
			return next(...)
		end

		print(`{remote.name} called with arguments:`, ...)

		local result = next(...)

		print(`{remote.name} returned:`, result)

		return result
	end
end
```

#### ⚙️ Using middleware

Middleware may be applied to a single remote, or to all remotes.

```ts
// TypeScript
const remotes = createRemotes(
	{
		event: remote<Client>(t.number).middleware(loggerMiddleware),
	},
	...middleware,
);
```

```lua
-- Luau
local remotes = Remo.createRemotes({
	event = Remo.remote(t.number).middleware(loggerMiddleware),
}, ...middleware)
```

Note that middleware is applied in the order it is defined. Additionally, middleware applied to all remotes will be applied _after_ middleware applied to a single remote.

---

## 📚 API

### `createRemotes(schema)`

Creates a set of remotes from a schema.

```ts
function createRemotes(schema: RemoteSchema, ...middleware: RemoMiddleware[]): Remotes;
```

#### Parameters

- `schema` - An object whose keys are the names of the remotes, and whose values are the remote declarations.

- `...middleware` - An optional list of middleware to apply to all remotes.

#### Returns

`createRemotes` returns a Remotes object, which contains the remotes defined in the schema.

You can access your remotes through this object, and it also has a `destroy` method that can be used to destroy all of the remotes.

---

### `remote(...validators?)`

Declares a remote to be used in the remote schema.

```ts
function remote<Mode, Args>(...validators: Validator[]): RemoteBuilder;
```

#### Parameters

- `...validators` - A list of validators to call before processing the remote.

#### Returns

`remote` returns a RemoteBuilder, which can be used to define a remote. It has the following functions:

- `remote.returns(validator)` - Declares that this is an async remote that returns a value of the given type.

- `remote.middleware(...middleware)` - Applies the given middleware to this remote.

- `remote.unreliable()` - Marks this remote as an [unreliable remote event](https://devforum.roblox.com/t/introducing-unreliableremoteevents/2724155).

---

### `namespace(schema)`

Declares a namespace to be used in the remote schema.

```ts
function namespace(schema: RemoteSchema): RemoteNamespace;
```

#### Parameters

- `schema` - An object whose keys are the names of the remotes, and whose values are the remote declarations.

#### Returns

`namespace` returns a RemoteNamespace, which declares a namespace of remotes. It does not have a public API.

---

### `getSender(...)`

Returns the player that sent the remote invocation using the arguments passed to the remote.

This is used for finding the `player` argument from a middleware called on the server.

```ts
function getSender(...args: unknown[]): Player | undefined;
```

#### Parameters

- `...args` - The arguments passed to the remote.

#### Returns

`getSender` returns the player that sent the remote invocation, or `undefined` if the remote was not invoked by a player.

---

### `loggerMiddleware`

Creates detailed logs of the arguments and return values of a remote invocation.

```ts
const loggerMiddleware: RemoMiddleware;
```

---

### `throttleMiddleware(options?)`

Prevents a remote from being invoked more than once every `throttle` seconds.

```ts
interface ThrottleMiddlewareOptions {
	throttle?: number;
	trailing?: boolean;
}

function throttleMiddleware(options?: ThrottleMiddlewareOptions): RemoMiddleware;

function throttleMiddleware(throttle?: number): RemoMiddleware;
```

#### Parameters

- `options` - An optional object with the following properties:
  - `throttle` - The number of seconds to throttle the remote for. Defaults to `0.1`.
  - `trailing` - If `true`, the last event will be fired again after the throttle period has passed. Does not apply to async functions. Defaults to `false`.

#### Returns

`throttleMiddleware` returns a middleware function that throttles the remote with the given options.

---

## 🪪 License

Remo is available under the MIT license. See the [LICENSE.md](LICENSE.md) file for more info.
