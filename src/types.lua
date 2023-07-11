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
}

export type RemoteBuilderMetadata = {
	parameters: { Validator },
	returns: { Validator },
	middleware: { Middleware },
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

export type Remote<Args... = ...any> = ClientToServer<Args...> & ServerToClient<Args...>

export type Remotes<Map = RemoteMap> = Map & {
	destroy: (self: Remotes<Map>) -> (),
}

export type RemoteMap = {
	[string]: AnyRemote | RemoteMap,
}

export type ClientToServer<Args... = ...any> = {
	name: string,
	type: "event",
	test: TestRemote<Args...>,
	connect: (self: ClientToServer<Args...>, callback: (player: Player, Args...) -> ()) -> Cleanup,
	fire: (self: ClientToServer<Args...>, Args...) -> (),
	destroy: (self: ClientToServer<Args...>) -> (),
}

export type ServerToClient<Args... = ...any> = {
	name: string,
	type: "event",
	test: TestRemote<Args...>,
	connect: (self: ServerToClient<Args...>, callback: (Args...) -> ()) -> Cleanup,
	fire: (self: ServerToClient<Args...>, player: Player, Args...) -> (),
	firePlayers: (self: ServerToClient<Args...>, players: { Player }, Args...) -> (),
	fireAll: (self: ServerToClient<Args...>, Args...) -> (),
	fireAllExcept: (self: ServerToClient<Args...>, player: Player, Args...) -> (),
	destroy: (self: ServerToClient<Args...>) -> (),
}

export type AsyncRemote<Args... = ...any, Returns... = ...any> =
	ServerAsync<Args..., Returns...>
	& ClientAsync<Args..., Returns...>

export type ServerAsync<Args... = ...any, Returns... = ...any> =
	((Args...) -> Promise<Returns...>)
	& ServerAsyncApi<Args..., Returns...>

export type ClientAsync<Args... = ...any, Returns... = ...any> =
	((player: Player, Args...) -> Promise<Returns...>)
	& ClientAsyncApi<Args..., Returns...>

export type AsyncRemoteApi<Args... = ...any, Returns... = ...any> =
	ServerAsyncApi<Args..., Returns...>
	& ClientAsyncApi<Args..., Returns...>

export type ServerAsyncApi<Args..., Returns...> = {
	name: string,
	type: "function",
	test: TestAsyncRemote<Args..., Returns...>,
	onRequest: (
		self: ServerAsyncApi<Args..., Returns...>,
		callback: ((player: Player, Args...) -> Returns...) | (player: Player, Args...) -> Promise<Returns...>
	) -> (),
	request: (self: ServerAsyncApi<Args..., Returns...>, Args...) -> Promise<Returns...>,
	destroy: (self: ServerAsyncApi<Args..., Returns...>) -> (),
}

export type ClientAsyncApi<Args..., Returns...> = {
	name: string,
	type: "function",
	test: TestAsyncRemote<Args..., Returns...>,
	onRequest: (
		self: ClientAsyncApi<Args..., Returns...>,
		callback: ((Args...) -> Returns...) | (Args...) -> Promise<Returns...>
	) -> (),
	request: (self: ClientAsyncApi<Args..., Returns...>, Args...) -> Promise<Returns...>,
	destroy: (self: ClientAsyncApi<Args..., Returns...>) -> (),
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
