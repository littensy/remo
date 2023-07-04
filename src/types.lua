export type _Thenable<R> = {
	andThen: <U>(self: _Thenable<R>, onFulfill: (R) -> ...U, onReject: (error: any) -> ...U) -> (),
}

export type Thenable<R> = {
	andThen: <U>(
		self: Thenable<R>,
		onFulfill: (R) -> ...(_Thenable<U> | U),
		onReject: (error: any) -> ...(_Thenable<U> | U)
	) -> nil | _Thenable<U>,
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

export type ServerFunction<Returns = any, Args... = ...any> = {
	name: string,
	onInvoke: (
		self: ServerFunction<Returns, Args...>,
		callback: (player: Player, Args...) -> Returns | Thenable<Returns>
	) -> (),
	invoke: (self: ServerFunction<Returns, Args...>, player: Player, Args...) -> Thenable<Returns>,
	destroy: (self: ServerFunction<Returns, Args...>) -> (),
}

export type ClientFunction<Returns = any, Args... = ...any> = {
	name: string,
	onInvoke: (self: ClientFunction<Returns, Args...>, callback: (Args...) -> Returns | Thenable<Returns>) -> (),
	invoke: (self: ClientFunction<Returns, Args...>, Args...) -> Thenable<Returns>,
	destroy: (self: ClientFunction<Returns, Args...>) -> (),
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
