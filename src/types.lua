export type Thenable<T> = {
	andThen: (self: Thenable<T>, callback: (value: T) -> any, rejected: ((error: unknown) -> any)?) -> Thenable<T>,
	catch: (self: Thenable<T>, callback: (error: unknown) -> any) -> Thenable<T>,
	cancel: (self: Thenable<T>) -> (),
	expect: (self: Thenable<T>) -> T,
}

-- Overloaded to satisfy 't' types and silence the linter
export type Validator = (<T>(value: T) -> boolean) & <T>(value: any) -> boolean

export type Cleanup = () -> ()

export type Middleware = (next: (...any) -> any, remote: AnyRemote) -> (...any) -> any

export type MiddlewareContext = {
	player: Player,
}

export type RemoteBuilder = {
	type: "remote",
	metadata: RemoteBuilderMetadata,
	returns: (...any) -> RemoteBuilder,
	middleware: (...Middleware) -> RemoteBuilder,
}

export type RemoteBuilderMetadata = {
	parameters: { Validator },
	returns: Validator?,
	middleware: { Middleware },
}

export type RemoteNamespace = {
	type: "namespace",
	remotes: RemoteBuilders,
}

export type RemoteBuilders = {
	[string]: RemoteBuilder | RemoteNamespace,
}

export type AnyRemote = ClientEvent | ClientFunction | ServerEvent | ServerFunction

export type ServerEvent<Args... = ...any> = {
	name: string,
	connect: (self: ServerEvent<Args...>, callback: (Args...) -> ()) -> Cleanup,
	fire: (self: ServerEvent<Args...>, player: Player, Args...) -> (),
	fireExcept: (self: ServerEvent<Args...>, player: Player, Args...) -> (),
	firePlayers: (self: ServerEvent<Args...>, players: { Player }, Args...) -> (),
	fireAll: (self: ServerEvent<Args...>, Args...) -> (),
	destroy: (self: ServerEvent<Args...>) -> (),
}

export type ClientEvent<Args... = ...any> = {
	name: string,
	connect: (self: ClientEvent<Args...>, callback: (Args...) -> ()) -> Cleanup,
	fire: (self: ClientEvent<Args...>, Args...) -> (),
	destroy: (self: ClientEvent<Args...>) -> (),
}

export type ServerFunction<Value = any, Args... = ...any> = {
	name: string,
	onInvoke: (self: ServerFunction<Value, Args...>, callback: (player: Player, Args...) -> Value) -> (),
	invoke: (self: ServerFunction<Value, Args...>, player: Player, Args...) -> Thenable<Value>,
	destroy: (self: ServerFunction<Value, Args...>) -> (),
}

export type ClientFunction<Value = any, Args... = ...any> = {
	name: string,
	onInvoke: (self: ClientFunction<Value, Args...>, callback: (Args...) -> Value) -> (),
	invoke: (self: ClientFunction<Value, Args...>, Args...) -> Thenable<Value>,
	destroy: (self: ClientFunction<Value, Args...>) -> (),
}

export type Remotes<Client = ClientRemotes, Server = ServerRemotes> = {
	client: Client,
	server: Server,
	destroy: (self: Remotes<Client, Server>) -> (),
}

export type ClientRemotes = {
	[string]: ClientEvent | ClientFunction | ClientRemotes,
}

export type ServerRemotes = {
	[string]: ServerEvent | ServerFunction | ServerRemotes,
}

return nil
