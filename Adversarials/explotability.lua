--- Libraries:
arguments = require 'Settings.arguments'
constants = require 'Settings.constants'
card_to_string = require 'Game.card_to_string_conversion'
card_tools = require 'Game.card_tools'
game_settings = require 'Settings.game_settings'

require 'torch'
require 'math'
require 'Tree.tree_builder'
require 'Tree.tree_data_generation'
require 'Tree.tree_visualiser'

require 'Tree.tree_cfr'
require 'TerminalEquity.terminal_equity'


local StrategyEvaluator = torch.class('StrategyEvaluator')

function StrategyEvaluator:__init(tree)
  self.player = tree
  self.card1_range = torch.FloatTensor(1,game_settings.card_count):fill(0)
  self.card2_range = torch.FloatTensor(1,game_settings.card_count):fill(0)
  self.terminal_equity = TerminalEquity()
  self.card1 = 0
  self.card2 = 0
  self.board = 0
  self:initialize_cards()
  self.P1 = 1
  self.P2 = 2
  self.chance = 0
  self.P1_pot = 0
  self.P2_pot = 0
  self.history_actions ={}
  self.terminal_equity:set_board(torch.FloatTensor({self.board}))
end

function StrategyEvaluator:compare_Strategy()
  local dealer = torch.random(0,1)
  if dealer ==1 then
  end
end

function StrategyEvaluator:play_game(starting_player,next_player)
  local player1_index = starting_player.id
  local player2_index = next_player.id
end



function StrategyEvaluator:play_action_on_node(node)
  local current_player = node.current_player
  local opponent = 3 - node.current_player
  local num_children = #node.children
  local children = node.children
  local winner = 0



  if num_children > 0 then
    --- recurse with the children
    local action_index = self:generate_action(node)
    table.insert(self.history_actions,action_index)
    self:play_action_on_node(children[action_index])
  else
    print("winner")
    winner = self:compute_winner(node)
    print(winner)
    self:update_pot(winner,node)
    self:initialize_cards()
  end



end

--- Calculates the winner of the round
function StrategyEvaluator:compute_winner(node)
  local current_player = node.current_player
  local opponent = 3-node.current_player

  if node.last_history == 1 then
    return current_player
  else
    local player1_result = self.terminal_equity.equity_matrix[self.card2][self.card1]
    if player1_result > 0 then
      return 1
    elseif player1_result < 0 then
      return 2
    else
      return 0
    end
  end

end


----Increases winner pot, decreases loosers pot
function StrategyEvaluator:update_pot(winner,node)

  if winner == 1 then
    self.P1_pot = self.P1_pot + node.pot
    self.P2_pot = self.P2_pot - node.pot
  elseif winner ==2 then
    self.P1_pot = self.P1_pot - node.pot
    self.P2_pot = self.P2_pot + node.pot
  end

end






--- Receives a node and generates an action_dimension
function StrategyEvaluator:generate_action(node)
  --- Set who is the player
  local card = 0
  if node.current_player == self.P1 then
    --- print("card1")
    card = self.card1
  elseif node.current_player == self.P2 then
    ---print("card2")
    card = self.card2
  else
    ---print("board")
    return self.board
  end
  --- Generate an action according to the strategy_indexes
  ---print(card)
  ---print(node.strategy)
  local strategy = node.strategy[{{},card}]:clone()
  local action = torch.multinomial(strategy, 1)[1]
  return action
end



function StrategyEvaluator:initialize_cards()
  local cards = torch.randperm(game_settings.card_count)
  local card1 = cards[1]
  local card2 = cards[2]
  local board = cards[3]
  self.card1 = card1
  self.card2 = card2
  self.board = board
  self.card1_range[1][card1] = 1
  self.card2_range[1][card2] = 1
  self.terminal_equity:set_board(torch.FloatTensor({board}))

end
