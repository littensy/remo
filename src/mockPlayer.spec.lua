local mockPlayer = require(script.Parent.mockPlayer)

return function() 
    it("should create a mock player", function() 
        local mock = mockPlayer({ UserId = 1 })
        expect(mock).to.equal({ UserId = 1, __unique_player_identifier_do_not_use = true })
    end)
end