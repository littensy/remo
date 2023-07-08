local types = require(script.types)
local createRemotes = require(script.createRemotes)
local builder = require(script.builder)
local getSender = require(script.getSender)
local loggerMiddleware = require(script.middleware.loggerMiddleware)
local throttleMiddleware = require(script.middleware.throttleMiddleware)

export type Promise<T> = types.Promise<T>
export type PromiseConstructor = types.PromiseConstructor
export type Validator = types.Validator

export type Middleware = types.Middleware
export type MiddlewareContext = types.MiddlewareContext

export type RemoteBuilder = types.RemoteBuilder
export type RemoteBuilderMetadata = types.RemoteBuilderMetadata
export type RemoteBuilders = types.RemoteBuilders

export type Remotes<Map> = types.Remotes<Map>
export type RemoteMap = types.RemoteMap
export type RemoteType = "event" | "function"

export type Remote<Args... = ...any> = types.Remote<Args...>
export type ClientToServer<Args... = ...any> = types.ClientToServer<Args...>
export type ServerToClient<Args... = ...any> = types.ServerToClient<Args...>

export type AsyncRemote<Returns = any, Args... = ...any> = types.AsyncRemote<Returns, Args...>
export type ClientToServerAsync<Returns = any, Args... = ...any> = types.ClientToServerAsync<Returns, Args...>
export type ServerToClientAsync<Returns = any, Args... = ...any> = types.ServerToClientAsync<Returns, Args...>

return {
	remote = builder.remote,
	namespace = builder.namespace,
	createRemotes = createRemotes,
	loggerMiddleware = loggerMiddleware,
	throttleMiddleware = throttleMiddleware,
	getSender = getSender,
}
