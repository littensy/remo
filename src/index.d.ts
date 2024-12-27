type Validator<T = unknown> = (value: unknown) => value is T;

type InferValidator<T extends Validator> = T extends Validator<infer U> ? U : never;

type InferValidators<T extends Validator[]> = {
	[K in keyof T]: T[K] extends Validator<infer U> ? U : never;
};

type Validators<T extends unknown[]> = {
	[K in keyof T]: Validator<T[K]>;
};

type Cleanup = () => void;

export = Remo;
export as namespace Remo;

declare namespace Remo {
	/**
	 * Declares a two-way remote that is invoked with the arguments passed to the
	 * template. Returns a remote builder that can be used to further configure
	 * the remote.
	 *
	 * To declare a Client or Server remote, pass the Client or Server type as
	 * the first type parameter before the arguments.
	 *
	 * @template Args The arguments that the remote accepts.
	 */
	export function remote<Args extends unknown[]>(
		...validators: Partial<Validators<Args>>
	): RemoteBuilder<(...args: Args) => void>;

	/**
	 * Declares a remote that is invoked with the arguments passed to the
	 * template. Returns a remote builder that can be used to further configure
	 * the remote.
	 *
	 * You can pass three remote modes:
	 * - `Client` - processed on the client and invoked by the server
	 * - `Server` - processed on the server and invoked by the client
	 * - `TwoWay` - both the client and server have full access to the remote
	 *
	 * @template Mode Whether the remote is processed by the client, the server,
	 * or both.
	 * @template Args The arguments that the remote accepts.
	 */
	export function remote<Mode extends RemoteMode, Args extends unknown[] = []>(
		...validators: Partial<Validators<Args>>
	): RemoteBuilder<(...args: Args) => void, Mode>;

	/**
	 * Declares a two-way remote with a signature inferred from the validators.
	 * Returns a remote builder that can be used to further configure the remote.
	 *
	 * You may instead pass a type parameter to explicitly define the arguments
	 * for the remote.
	 */
	export function remote<T extends Validator[]>(...validators: T): RemoteBuilder<(...args: InferValidators<T>) => void>;

	/**
	 * Declares a namespace that can contain other remotes and namespaces.
	 */
	export function namespace<T extends RemoteSchema>(schema: T): RemoteNamespace<T>;

	/**
	 * Creates the remotes and namespaces as defined by the schema. Returns an
	 * object containing the remotes and namespaces in the same shape as the
	 * schema.
	 */
	export function createRemotes<T extends RemoteSchema>(schema: T, ...middleware: RemoteMiddleware[]): Remotes<T>;

	/**
	 * Returns the player who invoked the remote given the first argument passed
	 * to the remote. If the first argument is an instance or a table with a
	 * `ClassName` property set to `"Player"`, it will be returned.
	 */
	export function getSender(...args: unknown[]): Player | undefined;

	interface ThrottleMiddlewareOptions {
		/**
		 * The number of seconds to wait before the remote can be invoked again.
		 *
		 * @default 0.1
		 */
		readonly throttle?: number;
		/**
		 * Whether to fire the remote one more time after the throttle period has
		 * passed. This only applies to events, and not async remotes.
		 *
		 * @default false
		 */
		readonly trailing?: boolean;
	}

	/**
	 * Prints detailed messages to the console when the remote is fired or invoked.
	 */
	export const loggerMiddleware: RemoteMiddleware;

	/**
	 * Throttles the remote so that it can only be invoked once every `throttle`
	 * seconds. If you want more control over the throttle behavior, pass an
	 * `options` object instead.
	 *
	 * If applied to an async remote, the remote will try to resolve with the
	 * previous result if it is invoked during the throttle period.
	 */
	export function throttleMiddleware(throttle: number): RemoteMiddleware;
	/**
	 * Throttles the remote so that it can only be invoked once every `throttle`
	 * seconds. If `trailing` is true, the remote will fire one more time after
	 * the throttle period has passed.
	 *
	 * If applied to an async remote, the remote will try to resolve with the
	 * previous result if it is invoked during the throttle period. Otherwise,
	 * the remote will reject with an error.
	 */
	export function throttleMiddleware(options?: ThrottleMiddlewareOptions): RemoteMiddleware;
}

declare namespace Remo {
	/**
	 * This remote will be processed by the server and is invoked by the client.
	 */
	export interface Server {
		readonly __brand: unique symbol;
	}

	/**
	 * This remote will be processed by the client and is invoked by the server.
	 */
	export interface Client {
		readonly __brand: unique symbol;
	}

	/**
	 * This remote will be processed by both the client and the server and can be
	 * invoked by either.
	 *
	 * @deprecated As of 1.2, prefer `Server` or `Client` instead.
	 */
	export interface TwoWay {
		readonly __brand: unique symbol;
	}

	/**
	 * The remote mode determines whether the remote is processed on the client,
	 * the server, or both.
	 */
	export type RemoteMode = Server | Client | TwoWay;

	/**
	 * A container for the remotes and namespaces as defined by the schema.
	 */
	export type Remotes<Schema extends RemoteSchema> = {
		[K in keyof Schema]: Schema[K] extends RemoteNamespace<infer NestedSchema>
			? Remotes<NestedSchema>
			: Schema[K] extends RemoteBuilder
			? InferRemoteFromBuilder<Schema[K]>
			: never;
	};

	type InferRemoteFromBuilder<T extends RemoteBuilder> = T extends RemoteBuilder<infer Signature, infer Mode>
		? Signature extends (...args: infer Args) => infer Returns
			? [Returns] extends [void]
				? Mode extends Server
					? ServerRemote<Args>
					: Mode extends Client
					? ClientRemote<Args>
					: ServerRemote<Args> | ClientRemote<Args>
				: Mode extends Server
				? ServerAsyncRemote<Args, Returns>
				: Mode extends Client
				? ClientAsyncRemote<Args, Returns>
				: ServerAsyncRemote<Args, Returns> | ClientAsyncRemote<Args, Returns>
			: never
		: never;

	/**
	 * Declares the structure of the remotes and namespaces that will be created
	 * by `createRemotes`.
	 */
	export interface RemoteSchema {
		[remoteName: string]: RemoteBuilder | RemoteNamespace;
	}

	/**
	 * A namespace is a container for other remotes and namespaces.
	 */
	export interface RemoteNamespace<Schema extends RemoteSchema = RemoteSchema> {
		readonly remotes: Schema;
	}

	/**
	 * Declares the mode and signature of a remote. The mode determines whether
	 * the remote is processed on the client, the server, or both. The signature
	 * determines the arguments and optional return value of the remote.
	 *
	 * @template Signature The function signature of the remote.
	 */
	export interface RemoteBuilder<Signature extends Callback = Callback, Mode extends RemoteMode = TwoWay> {
		/**
		 * @deprecated This is used internally for nominal typing.
		 */
		readonly __signature: Signature;
		/**
		 * Declares that the remote has a return value, and will create an async
		 * remote when passed to `createRemotes`.
		 */
		readonly returns: {
			/**
			 * Declares that the remote has a return value, and will create an async
			 * remote when passed to `createRemotes`.
			 *
			 * The type of the return value is inferred from the validator. You may
			 * instead pass a type parameter to explicitly declare the return type.
			 */
			<T extends Validator>(validator: T): RemoteBuilder<
				Signature extends (...args: infer Args) => void ? (...args: Args) => InferValidator<T> : never,
				Mode
			>;
			/**
			 * Declares that the remote has a return value, and will create an async
			 * remote when passed to `createRemotes`.
			 *
			 * Accepts a type parameter to explicitly declare the return type.
			 * Validators are optional.
			 *
			 * @template T The type of the return value.
			 */
			<T>(validator?: Validator<T>): RemoteBuilder<
				Signature extends (...args: infer Args) => void ? (...args: Args) => T : never,
				Mode
			>;
		};
		/**
		 * Applies middleware to the remote once it is created by `createRemotes`.
		 *
		 * Middleware declared here will be applied before any middleware declared
		 * through a namespace or the `createRemotes` function.
		 */
		readonly middleware: (...middleware: RemoteMiddleware[]) => RemoteBuilder<Signature, Mode>;
		/**
		 * Marks the remote as an unreliable remote. Uses an `UnreliableRemoteEvent`
		 * internally if the remote is an event.
		 *
		 * @see https://devforum.roblox.com/t/introducing-unreliableremoteevents/2724155
		 */
		readonly unreliable: () => RemoteBuilder<Signature, Mode>;
	}

	/**
	 * A middleware function that can be applied to modify the behavior of a
	 * remote. Returns a function that is called when the remote is invoked.
	 *
	 * @param next The next middleware function in the chain.
	 * @param remote The remote that is being invoked.
	 * @returns A function that is called when the remote is invoked.
	 */
	export type RemoteMiddleware = (next: Callback, remote: AnyRemote) => (...args: unknown[]) => unknown;
}

declare namespace Remo {
	/**
	 * The type of a remote. Either `"event"` for a RemoteEvent or `"function"`
	 * for a RemoteFunction.
	 */
	export const enum RemoteType {
		Event = "event",
		Function = "function",
	}

	interface BaseRemote<T extends RemoteType = RemoteType> {
		/**
		 * The type of the remote. Either `"event"` if this is a remote event or
		 * `"function"` if this is an async remote.
		 */
		readonly type: T;
		/**
		 * The name of the remote, as defined in the schema.
		 */
		readonly name: string;
		/**
		 * Destroys the remote. If called on the client, this will disconnect all
		 * listeners from the remote. If called on the server, this will destroy
		 * the instance.
		 */
		destroy(): void;
	}

	export type AnyRemote<Args extends unknown[] = unknown[], Returns = unknown> =
		| ServerRemote<Args>
		| ClientRemote<Args>
		| ServerAsyncRemote<Args, Returns>
		| ClientAsyncRemote<Args, Returns>;

	/**
	 * A two-way remote event that runs the connected listeners when it is fired.
	 * It can be fired and connected to on both the client and the server.
	 *
	 * @deprecated Use a client or server remote instead.
	 */
	export interface Remote<Args extends unknown[] = unknown[]> extends ServerRemote<Args>, ClientRemote<Args> {
		/**
		 * Fires the remote for the player to process. Calls the player's listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 */
		fire(player: Player, ...args: Args): void;
		/**
		 * Fires the remote for the server to process. Calls the listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the server before they are processed.
		 *
		 * @client
		 */
		fire(...args: Args): void;
		/**
		 * Connects a server-side listener to the remote. When a player fires
		 * the remote, the listener will be invoked with the arguments passed to
		 * the remote.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the listener.
		 *
		 * @server
		 */
		connect(listener: (player: Player, ...args: Args) => void): Cleanup;
		/**
		 * Connects a client-side listener to the remote. When the server fires
		 * the remote, the listener will be invoked with the arguments passed to
		 * the remote.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the listener.
		 *
		 * @client
		 */
		connect(listener: (...args: Args) => void): Cleanup;
		/**
		 * Returns a Promise that resolves when the remote is fired by a player.
		 * If `predicate` is provided, the Promise will only resolve if the
		 * predicate returns true.
		 *
		 * NOTE: Promises in Roblox-TS do not support tuples. Use the `mapper`
		 * argument to map the tuple to a consumable value.
		 *
		 * @server
		 */
		promise<T = Player>(
			predicate?: (player: Player, ...args: Args) => boolean,
			mapper?: (player: Player, ...args: Args) => T,
		): Promise<T>;
		/**
		 * Returns a Promise that resolves when the remote is fired by the server.
		 * If `predicate` is provided, the Promise will only resolve if the
		 * predicate returns true.
		 *
		 * NOTE: Promises in Roblox-TS do not support tuples. Use the `mapper`
		 * argument to map the tuple to a consumable value.
		 *
		 * @client
		 */
		promise<T = Args[0]>(predicate?: (...args: Args) => boolean, mapper?: (...args: Args) => T): Promise<T>;
	}

	/**
	 * A server-side remote event that runs the connected listeners when it is
	 * fired. It is fired by the client and events are processed by the server.
	 */
	export interface ServerRemote<Args extends unknown[]> extends BaseRemote<RemoteType.Event> {
		/**
		 * Fires the remote for the server to process. Calls the listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the server before they are processed.
		 *
		 * @client
		 */
		(...args: Args): void;
		/**
		 * Provides an interface to subscribe to or intercept this remote's own
		 * outgoing events. Useful for mocking a client or server's response.
		 */
		readonly test: RemoteTester<Args>;
		/**
		 * Fires the remote for the server to process. Calls the listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the server before they are processed.
		 *
		 * @client
		 */
		fire(...args: Args): void;
		/**
		 * Connects a server-side listener to the remote. When a player fires
		 * the remote, the listener will be invoked with the arguments passed to
		 * the remote.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the listener.
		 *
		 * @server
		 */
		connect(listener: (player: Player, ...args: Args) => void): Cleanup;
		/**
		 * Returns a Promise that resolves when the remote is fired by a player.
		 * If `predicate` is provided, the Promise will only resolve if the
		 * predicate returns true.
		 *
		 * NOTE: Promises in Roblox-TS do not support tuples. Use the `mapper`
		 * argument to map the tuple to a consumable value.
		 *
		 * @server
		 */
		promise<T = Player>(
			predicate?: (player: Player, ...args: Args) => boolean,
			mapper?: (player: Player, ...args: Args) => T,
		): Promise<T>;
	}

	/**
	 * A client-side remote event that runs the connected listeners when it is
	 * fired. It is fired by the server and events are processed by the client.
	 */
	export interface ClientRemote<Args extends unknown[]> extends BaseRemote<RemoteType.Event> {
		/**
		 * Fires the remote for the player to process. Calls the player's listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 */
		(player: Player, ...args: Args): void;
		/**
		 * Provides an interface to subscribe to or intercept this remote's own
		 * outgoing events. Useful for mocking a client or server's response.
		 */
		readonly test: RemoteTester<Args>;
		/**
		 * Fires the remote for the player to process. Calls the player's listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 */
		fire(player: Player, ...args: Args): void;
		/**
		 * Fires the remote for the given players to process. Calls the players'
		 * listeners connected to the same remote.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 */
		firePlayers(players: readonly Player[], ...args: Args): void;
		/**
		 * Fires the remote for all players to process. Calls all players' listeners
		 * connected to the same remote.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 */
		fireAll(...args: Args): void;
		/**
		 * Fires the remote for all players except the given player to process.
		 * Calls all players' listeners connected to the same remote.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 */
		fireAllExcept(player: Player, ...args: Args): void;
		/**
		 * Connects a client-side listener to the remote. When the server fires
		 * the remote, the listener will be invoked with the arguments passed to
		 * the remote.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the listener.
		 *
		 * @client
		 */
		connect(listener: (...args: Args) => void): Cleanup;
		/**
		 * Returns a Promise that resolves when the remote is fired by the server.
		 * If `predicate` is provided, the Promise will only resolve if the
		 * predicate returns true.
		 *
		 * NOTE: Promises in Roblox-TS do not support tuples. Use the `mapper`
		 * argument to map the tuple to a consumable value.
		 *
		 * @client
		 */
		promise<T = Args[0]>(predicate?: (...args: Args) => boolean, mapper?: (...args: Args) => T): Promise<T>;
	}

	/**
	 * A two-way remote function that runs the handler when it is invoked. It can
	 * be invoked and processed on both the client and the server.
	 *
	 * @deprecated Use a client or server async remote instead.
	 */
	export interface AsyncRemote<Args extends unknown[] = unknown[], Returns = unknown>
		extends ServerAsyncRemote<Args, Returns>,
			ClientAsyncRemote<Args, Returns> {
		/**
		 * Sends a request for a player to process. Returns a Promise that resolves
		 * with the value returned by the handler.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 * @deprecated Requesting values from players is unsafe.
		 */
		request(player: Player, ...args: Args): Promise<Returns>;
		/**
		 * Sends a request for the server to process. Returns a Promise that resolves
		 * with the return value of the server handler.
		 *
		 * Arguments are validated on the server before they are processed.
		 *
		 * @client
		 */
		request(...args: Args): Promise<Returns>;
		/**
		 * Binds a server-side handler to the remote. When a player makes a request,
		 * the handler will be invoked with the arguments passed, and the return
		 * value will be sent back to the player.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the handler. Otherwise, the
		 * request will be rejected.
		 *
		 * @server
		 */
		onRequest(handler: (player: Player, ...args: Args) => Promise<Returns> | Returns): void;
		/**
		 * Binds a client-side handler to the remote. When the server makes a
		 * request, the handler will be invoked with the arguments passed, and the
		 * return value will be sent back to the server.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the handler. Otherwise, the
		 * request will be rejected.
		 *
		 * @client
		 * @deprecated Requesting values from players is unsafe.
		 */
		onRequest(handler: (...args: Args) => Promise<Returns> | Returns): void;
	}

	/**
	 * A server-side remote function that runs the handler when it is invoked. It
	 * is invoked by the client and requests are processed by the server.
	 */
	export interface ServerAsyncRemote<Args extends unknown[], Returns> extends BaseRemote<RemoteType.Function> {
		/**
		 * Sends a request for the server to process. Returns a Promise that resolves
		 * with the return value of the server handler.
		 *
		 * Arguments are validated on the server before they are processed.
		 *
		 * @client
		 */
		(...args: Args): Promise<Returns>;
		/**
		 * Provides an interface to mock a response to a remote request. Useful for
		 * intercepting a request to the server or client.
		 */
		readonly test: AsyncRemoteTester<Args, Returns>;
		/**
		 * Sends a request for the server to process. Returns a Promise that resolves
		 * with the return value of the server handler.
		 *
		 * Arguments are validated on the server before they are processed.
		 *
		 * @client
		 */
		request(...args: Args): Promise<Returns>;
		/**
		 * Binds a server-side handler to the remote. When a player makes a request,
		 * the handler will be invoked with the arguments passed, and the return
		 * value will be sent back to the player.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the handler. Otherwise, the
		 * request will be rejected.
		 *
		 * @server
		 */
		onRequest(handler: (player: Player, ...args: Args) => Promise<Returns> | Returns): void;
	}

	/**
	 * A client-side remote function that runs the handler when it is invoked. It
	 * is invoked by the server and requests are processed by the client.
	 */
	export interface ClientAsyncRemote<Args extends unknown[], Returns> extends BaseRemote<RemoteType.Function> {
		/**
		 * Sends a request for a player to process. Returns a Promise that resolves
		 * with the value returned by the handler.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 * @deprecated Requesting values from players is unsafe.
		 */
		(player: Player, ...args: Args): Promise<Returns>;
		/**
		 * Provides an interface to mock a response to a remote request. Useful for
		 * intercepting a request to the server or client.
		 */
		readonly test: AsyncRemoteTester<Args, Returns>;
		/**
		 * Sends a request for a player to process. Returns a Promise that resolves
		 * with the value returned by the handler.
		 *
		 * Arguments are validated on the client before they are processed.
		 *
		 * @server
		 * @deprecated Requesting values from players is unsafe.
		 */
		request(player: Player, ...args: Args): Promise<Returns>;
		/**
		 * Binds a client-side handler to the remote. When the server makes a
		 * request, the handler will be invoked with the arguments passed, and the
		 * return value will be sent back to the server.
		 *
		 * Arguments passed to the remote must first pass the validators defined
		 * in the schema before they are passed to the handler. Otherwise, the
		 * request will be rejected.
		 *
		 * @client
		 * @deprecated Requesting values from players is unsafe.
		 */
		onRequest(handler: (...args: Args) => Promise<Returns> | Returns): void;
	}

	/**
	 * Provides an interface to subscribe to or intercept this remote's own
	 * outgoing events. Useful for mocking a client or server's response.
	 */
	export interface RemoteTester<Args extends unknown[]> {
		/**
		 * Subscribes to an outgoing event originating from this side of the client/
		 * server boundary. The listener will be invoked with the arguments passed
		 * to `remote.fire`, minus any player argument.
		 *
		 * This is _not_ a replacement for `connect`, and will not intercept events
		 * sent by the other side of the client/server boundary.
		 *
		 * **Note:** Remember to clean up your listeners when you are done testing!
		 */
		onFire(listener: (...args: Args) => void): Cleanup;
		/**
		 * Disconnects all listeners from this test remote.
		 */
		disconnectAll(): void;
	}

	/**
	 * Provides an interface to mock a response to a remote request. Useful for
	 * intercepting a request to the server or client.
	 */
	export interface AsyncRemoteTester<Args extends unknown[], Returns> {
		/**
		 * Forces `request` to call this handler instead of the handler registered
		 * by the recipient. The handler will be invoked with the arguments passed
		 * to `remote.request`, minus any player argument.
		 *
		 * This is _not_ a replacement for `onRequest`, and will not intercept
		 * requests sent by the other side of the client/server boundary.
		 *
		 * **Note:** Remember to call `disconnectAll` when you are done testing!
		 */
		handleRequest(handler: (...args: Args) => Promise<Returns> | Returns): void;
		/**
		 * Returns whether this remote has a handler registered.
		 */
		hasRequestHandler(): boolean;
		/**
		 * Removes the handler registered by `handleRequest`.
		 */
		disconnectAll(): void;
	}
}
