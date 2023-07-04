local Promise = require(script.Parent.Promise)

export type Promise<T> = Promise.Promise<T>

export type PromiseConstructor = Promise.PromiseConstructor

-- Overloaded to satisfy 't' types and silence the linter
export type Validator = (<T>(value: T) -> boolean) & <T>(value: any) -> boolean

export type Cleanup = () -> ()

export type Middleware = (next: (...any) -> ...any, remote: AnyRemote) -> (...any) -> ...any

export type MiddlewareContext = {
	player: Player,
}

export type RemoteBuilder = {
	type: RemoteType,
	metadata: RemoteBuilderMetadata,
	returns: (...any) -> RemoteBuilder,
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

export type ClientToServer<Args... = ...any> = {
	name: string,
	type: "event",
	connect: (self: ClientToServer<Args...>, callback: (player: Player, Args...) -> ()) -> Cleanup,
	fire: (self: ClientToServer<Args...>, Args...) -> (),
	destroy: (self: ClientToServer<Args...>) -> (),
}

export type ServerToClient<Args... = ...any> = {
	name: string,
	type: "event",
	connect: (self: ServerToClient<Args...>, callback: (Args...) -> ()) -> Cleanup,
	fire: (self: ServerToClient<Args...>, player: Player, Args...) -> (),
	firePlayers: (self: ServerToClient<Args...>, players: { Player }, Args...) -> (),
	fireAll: (self: ServerToClient<Args...>, Args...) -> (),
	fireAllExcept: (self: ServerToClient<Args...>, player: Player, Args...) -> (),
	destroy: (self: ServerToClient<Args...>) -> (),
}

export type AsyncRemote<Returns = any, Args... = ...any> =
	ClientToServerAsync<Returns, Args...>
	& ServerToClientAsync<Returns, Args...>

export type ServerToClientAsync<Returns = any, Args... = ...any> = {
	name: string,
	type: "function",
	onRequest: (self: ServerToClientAsync<Returns, Args...>, callback: (Args...) -> Returns | Promise<Returns>) -> (),
	request: (self: ServerToClientAsync<Returns, Args...>, player: Player, Args...) -> Promise<Returns>,
	destroy: (self: ServerToClientAsync<Returns, Args...>) -> (),
}

export type ClientToServerAsync<Returns = any, Args... = ...any> = {
	name: string,
	type: "function",
	onRequest: (
		self: ClientToServerAsync<Returns, Args...>,
		callback: (player: Player, Args...) -> Returns | Promise<Returns>
	) -> (),
	request: (self: ClientToServerAsync<Returns, Args...>, Args...) -> Promise<Returns>,
	destroy: (self: ClientToServerAsync<Returns, Args...>) -> (),
}

export type Remotes<Map = RemoteMap> = Map & {
	destroy: (self: Remotes<Map>) -> (),
}

export type RemoteMap = {
	[string]: AnyRemote | RemoteMap,
}

return nil
