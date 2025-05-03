local Promise = require(script.Promise)
local types = require(script.types)
local createRemotes = require(script.createRemotes)
local builder = require(script.builder)
local getSender = require(script.getSender)
local loggerMiddleware = require(script.middleware.loggerMiddleware)
local throttleMiddleware = require(script.middleware.throttleMiddleware)

export type Promise<T> = Promise.Promise<T>
export type PromiseConstructor = Promise.PromiseConstructor

export type Middleware = types.Middleware

export type RemoteBuilder = types.RemoteBuilder
export type RemoteBuilderMetadata = types.RemoteBuilderMetadata
export type RemoteBuilders = types.RemoteBuilders

export type Remotes<Map> = types.Remotes<Map>
export type RemoteMap = types.RemoteMap
export type RemoteType = "event" | "function"

export type Remote<Args... = ...any> = types.Remote<Args...>
export type ClientToServer<Args... = ...any> = types.ClientToServer<Args...>
export type ServerToClient<Args... = ...any> = types.ServerToClient<Args...>

export type AsyncRemote<Args... = ...any, Returns... = ...any> = types.AsyncRemote<Args..., Returns...>
export type ServerAsync<Args... = ...any, Returns... = ...any> = types.ServerAsync<Args..., Returns...>
export type ClientAsync<Args... = ...any, Returns... = ...any> = types.ClientAsync<Args..., Returns...>

--- @deprecated 1.2, use `ServerAsync` instead.
export type ClientToServerAsync<Returns = any, Args... = ...any> = types.ServerAsync<Args..., (Returns)>

--- @deprecated 1.2, use `ClientAsync` instead.
export type ServerToClientAsync<Returns = any, Args... = ...any> = types.ClientAsync<Args..., (Returns)>

return {
	remote = builder.remote,
	namespace = builder.namespace,
	createRemotes = createRemotes,
	loggerMiddleware = loggerMiddleware,
	throttleMiddleware = throttleMiddleware,
	getSender = getSender,
}
