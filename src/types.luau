local Promise = require(script.Parent.Promise)

type Cleanup = () -> ()

type Promise<T...> = Promise.Promise<T...>

export type Validator = any

export type Middleware = (next: (...any) -> ...any, remote: AnyRemote) -> (...any) -> ...any

export type RemoteBuilder = {
	type: RemoteType,
	metadata: RemoteBuilderMetadata,
	returns: (...Validator) -> RemoteBuilder,
	middleware: (...Middleware) -> RemoteBuilder,
	unreliable: () -> RemoteBuilder,
}

export type RemoteBuilderMetadata = {
	parameters: { Validator },
	returns: { Validator },
	middleware: { Middleware },
	unreliable: boolean,
}

export type RemoteNamespace = {
	type: "namespace",
	remotes: RemoteBuilders,
}

export type RemoteBuilders = {
	[string]: RemoteBuilder | RemoteNamespace,
}

export type RemoteType = "event" | "function"

export type AnyRemote = Remote | AsyncRemote

export type Remotes<Map = RemoteMap> = Map & {
	destroy: (self: Remotes<Map>) -> (),
}

export type RemoteMap = {
	[string]: AnyRemote | RemoteMap,
}

export type Remote<Args... = ...any> = ClientToServer<Args...> & ServerToClient<Args...>

export type ClientToServer<Args... = ...any> = ((Args...) -> ()) & {
	name: string,
	type: "event",
	test: TestRemote<Args...>,
	connect: (self: ClientToServer<Args...>, callback: (player: Player, Args...) -> ()) -> Cleanup,
	promise: (
		self: ClientToServer<Args...>,
		predicate: ((player: Player, Args...) -> boolean)?,
		_mapper: ((player: Player, Args...) -> ...any)?
	) -> Promise<(Player, Args...)>,
	fire: (self: ClientToServer<Args...>, Args...) -> (),
	destroy: (self: ClientToServer<Args...>) -> (),
}

export type ServerToClient<Args... = ...any> = ((player: Player, Args...) -> ()) & {
	name: string,
	type: "event",
	test: TestRemote<Args...>,
	connect: (self: ServerToClient<Args...>, callback: (Args...) -> ()) -> Cleanup,
	promise: (
		self: ClientToServer<Args...>,
		predicate: ((Args...) -> boolean)?,
		_mapper: ((Args...) -> ...any)?
	) -> Promise<Args...>,
	fire: (self: ServerToClient<Args...>, player: Player, Args...) -> (),
	firePlayers: (self: ServerToClient<Args...>, players: { Player }, Args...) -> (),
	fireAll: (self: ServerToClient<Args...>, Args...) -> (),
	fireAllExcept: (self: ServerToClient<Args...>, player: Player, Args...) -> (),
	destroy: (self: ServerToClient<Args...>) -> (),
}

export type AsyncRemote<Args... = ...any, Returns... = ...any> =
	ServerAsync<Args..., Returns...>
	& ClientAsync<Args..., Returns...>

export type ServerAsync<Args... = ...any, Returns... = ...any> = ((Args...) -> Promise<Returns...>) & {
	name: string,
	type: "function",
	test: TestAsyncRemote<Args..., Returns...>,
	onRequest: (
		self: ServerAsync<Args..., Returns...>,
		callback: ((player: Player, Args...) -> Returns...) | (player: Player, Args...) -> Promise<Returns...>
	) -> (),
	request: (self: ServerAsync<Args..., Returns...>, Args...) -> Promise<Returns...>,
	destroy: (self: ServerAsync<Args..., Returns...>) -> (),
}

export type ClientAsync<Args... = ...any, Returns... = ...any> = ((player: Player, Args...) -> Promise<Returns...>) & {
	name: string,
	type: "function",
	test: TestAsyncRemote<Args..., Returns...>,
	onRequest: (
		self: ClientAsync<Args..., Returns...>,
		callback: ((Args...) -> Returns...) | (Args...) -> Promise<Returns...>
	) -> (),
	request: (self: ClientAsync<Args..., Returns...>, Args...) -> Promise<Returns...>,
	destroy: (self: ClientAsync<Args..., Returns...>) -> (),
}

export type TestRemote<Args... = ...any> = {
	_fire: (self: TestRemote<Args...>, Args...) -> (),
	onFire: (self: TestRemote<Args...>, callback: (Args...) -> ()) -> Cleanup,
	disconnectAll: (self: TestRemote<Args...>) -> (),
}

export type TestAsyncRemote<Args... = ...any, Returns... = ...any> = {
	_request: (self: TestAsyncRemote<Args..., Returns...>, Args...) -> Returns...,
	handleRequest: (
		self: TestAsyncRemote<Args..., Returns...>,
		callback: ((Args...) -> Returns...) | (Args...) -> Promise<Returns...>
	) -> (),
	hasRequestHandler: (self: TestAsyncRemote<Args..., Returns...>) -> boolean,
	disconnectAll: (self: TestAsyncRemote<Args..., Returns...>) -> (),
}

return nil
