return function()
	local types = require(script.Parent.Parent.types)
	local compose = require(script.Parent.compose)

	it("should combine the given middleware", function()
		local a, b, c

		local middleware: types.Middleware = function(next)
			return function(...)
				return next(...)
			end
		end

		local composed = compose({ middleware, middleware, middleware })(function(...): ()
			a, b, c = ...
			return 123
		end, {} :: never)

		expect(composed("foo", "bar", "baz")).to.equal(123)
		expect(a).to.equal("foo")
		expect(b).to.equal("bar")
		expect(c).to.equal("baz")
	end)

	it("should work with no middleware", function()
		local a, b, c

		local composed = compose({})(function(...): ()
			a, b, c = ...
			return 123
		end, {} :: never)

		expect(composed("foo", "bar", "baz")).to.equal(123)
		expect(a).to.equal("foo")
		expect(b).to.equal("bar")
		expect(c).to.equal("baz")
	end)

	it("should be cancellable", function()
		local calls = 0

		local middleware: types.Middleware = function(next)
			return function(cancel)
				return if cancel then nil else next()
			end
		end

		local composed = compose({ middleware })(function(): ()
			calls += 1
		end, {} :: never)

		composed(false)
		composed(true)
		composed(false)

		expect(calls).to.equal(2)
	end)

	it("should allow multiple return values", function()
		local middleware: types.Middleware = function(next)
			return function(...)
				return next(...)
			end
		end

		local composed = compose({ middleware, middleware, middleware })(function(...): (string, string, string)
			return "foo", "bar", "baz"
		end, {} :: never)

		local a, b, c = composed("foo", "bar", "baz")

		expect(a).to.equal("foo")
		expect(b).to.equal("bar")
		expect(c).to.equal("baz")
	end)
end
