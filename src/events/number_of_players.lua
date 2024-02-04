local number_of_players = {}

function number_of_players.get_number_of_players_playing()
    local number_of_players_playing = 0
    for i = 1, bj_MAX_PLAYERS do
        if (GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING) then
            number_of_players_playing = number_of_players_playing + 1
        end
    end
    return number_of_players_playing
end

function number_of_players.get_players_playing_indices()
    local players_playing_indices = {}
    for i = 1, bj_MAX_PLAYERS do
        if (GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING) then
            table.insert(players_playing_indices, i)
        end
    end
    return players_playing_indices
end

function number_of_players.trigger_number_of_players_playing_changes()
  local trig = CreateTrigger()
  TriggerRegisterTimerEventSingle(trig, 0.0)
  local players_playing_indices = number_of_players.get_players_playing_indices()
  for _, player_index in players_playing_indices do
    TriggerRegisterPlayerEvent(trig, Player(player_index), EVENT_PLAYER_LEAVE)
  end
  -- TODO Add actions
  -- Give players unit duplicators depending on the number of players
  -- Adjust game difficulty depending on the number of players
end


return number_of_players