local function mockPlayer(mock: { UserId: number }): Player
    return {
        UserId = mock.UserId,
        __unique_player_identifier_do_not_use = true
    } :: any
end

return mockPlayer