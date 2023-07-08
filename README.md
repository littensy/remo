# 🔌 Remo

Remo is a simple remote event and function abstraction library for Roblox. Easily set up type-checked events and asynchronous functions that can be called from the client and server.

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
Remo = "littensy/remo@1.0.0"
```

## ✨ Features

- 📚 Remote events and functions are fully type-checked and support Luau autocompletion.

- 🔐 Validate arguments and return values with [`t`](https://github.com/osyrisrblx/t).

- ⚛️ Declare your remotes in one place and use them anywhere.

- 🛟 Safe to use in Hoarcekat or other environments outside of a running Roblox game.

## 📖 Usage

See the [examples](examples) folder for more detailed examples.

### 🔌 Creating remotes

`createRemotes` is used to create a set of remotes. It receives the remote schema, which is an object that maps remote names to their definitions.

- `remote<Args>(...validators?)` creates a remote event with the given argument types. If validators are provided, they will be used to validate the arguments passed to the event.

- `remote().returns<Result>(...validators?)` creates a remote function with the given argument and return types. If validators are provided, they will be asserted against the arguments passed to the function and the return value of the function.

- `namespace(schema)` creates a nested namespace of remotes.

```ts
// TypeScript
const remotes = createRemotes({
	event: remote<[value: number]>(t.number),
	async: remote<[value: number]>(t.number).returns<string>(t.string),
	namespace: namespace({
		event2: remote<[value: number]>(t.number),
		async2: remote<[value: number]>(t.number).returns<string>(t.string),
	}),
});
```

```lua
-- Luau
local remotes: Remotes = Remo.createRemotes({
    event = Remo.remote(t.number),
    async = Remo.remote(t.number).returns(t.string),
    namespace = Remo.namespace({
        event2 = Remo.remote(t.number),
        async2 = Remo.remote(t.number).returns(t.string),
    }),
})
```

### 🛟 Type safety

#### TypeScript

In TypeScript, [`t`](https://github.com/osyrisrblx/t) is recommended to ensure remotes can only be called with the correct arguments, but it is optional.

To further narrow your types, `remote` receives an optional `Mode` generic that can be used to specify whether the remote is processed by the client or the server. By default, remotes are `TwoWay`, meaning they can be called from both the client and the server.

This is mainly for narrowing types, as this does not change the behavior of the remote.

```ts
const remotes = createRemotes({
	// event processed on the client and fired by the server
	client: remote<Client, [value: number]>(t.number),

	// event processed on the server and fired by the client
	server: remote<Server, [value: number]>(t.number),

	// event processed on both the client and server
	twoWay: remote<TwoWay, [value: number]>(t.number),
});
```

#### Luau

In Luau, for full type-checking in your editor, you will need to define a separate type for your remotes using the following types:

- `ClientToServer<Args...>`: A remote event that is fired by the client and processed by the server.

- `ServerToClient<Args...>`: A remote event that is fired by the server and processed by the client.

- `ClientToServerAsync<Result, (Args...)>`: A remote function that is invoked by the client and processed by the server.

- ~~`ServerToClientAsync<Result, (Args...)>`~~: A remote function that is invoked by the server and processed by the client. Not recommended, as requesting values from the client is unsafe.

```lua
type Remotes = {
    client: Remo.ServerToClient<number>,
    server: Remo.ClientToServer<number>,
    clientAsync: Remo.ServerToClientAsync<string, (number)>, -- unsafe
    serverAsync: Remo.ClientToServerAsync<string, (number)>,
}

local remotes: Remotes = Remo.createRemotes({
    client = Remo.remote(t.number),
    server = Remo.remote(t.number),
    clientAsync = Remo.remote(t.number).returns(t.string),
    serverAsync = Remo.remote(t.number).returns(t.string),
})
```

Defining two-way remotes is not recommended in Luau, as it would require function overloads that may affect intellisense.

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
    print(...)
end)

-- server -> client
local disconnect = remotes.event:connect(function(...)
    print(player, ...)
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
    print(player, result)
end)
```

To bind a handler to a remote function, use `onRequest`. If validators are provided, they must all pass before the handler is called.

The handler can return a value or a promise that resolves with a value. If the handler throws an error or the promise rejects, the caller will receive it as a promise rejection.

```lua
-- client -> server async
remotes.async:onRequest(function(player, ...)
    return ...
end)

-- server -> client async
remotes.async:onRequest(function(...)
    return ...
end)
```

Roblox-TS will automatically hide client- or server-only APIs based on whether you are using them on the client or on the server. However, this is not currently implemented in Luau, so take precautions to ensure you are calling `fire` or `connect` on the correct side.

### ⛓️ Middleware

Middleware can be used to intercept and modify arguments and return values before they are processed. This can be used to implement features such as logging, rate limiting, or more complex validation.

#### 📦 Built-in middleware

- `loggerMiddleware` creates detailed logs of the arguments and return value of a remote invocation.

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
		event: remote(t.number).middleware(loggerMiddleware),
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

## 🪪 License

Remo is available under the MIT license. See the [LICENSE.md](LICENSE.md) file for more info.
