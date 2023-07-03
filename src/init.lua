local types = require(script.types)
local createRemotes = require(script.createRemotes)
local remote = require(script.remote)

export type Thenable<T> = types.Thenable<T>
export type Validator = types.Validator

export type Middleware = types.Middleware
export type MiddlewareContext = types.MiddlewareContext

export type RemoteBuilder = types.RemoteBuilder
export type RemoteBuilderMetadata = types.RemoteBuilderMetadata
export type RemoteBuilders = types.RemoteBuilders

export type Remotes = types.Remotes
export type ServerEvent<Args... = ...any> = types.ServerEvent<Args...>
export type ClientEvent<Args... = ...any> = types.ClientEvent<Args...>
export type ServerFunction<Value = any, Args... = ...any> = types.ServerFunction<Value, Args...>
export type ClientFunction<Value = any, Args... = ...any> = types.ClientFunction<Value, Args...>

return {
	remote = remote,
	createRemotes = createRemotes,
}
