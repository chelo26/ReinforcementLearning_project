--- Gives allowed bets during a game.
-- Bets are restricted to be from a list of predefined fractions of the pot.
-- @classmod bet_sizing

require 'Game.bet_sizing'
local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local card_to_string = require 'Game.card_to_string_conversion'
local evaluator = require 'Game.Evaluation.evaluator'
local game_settings = require 'Settings.game_settings'
local card_tools = require 'Game.card_tools'
local tools = require 'tools'
require 'Nn.bucketer'



require 'TerminalEquity.terminal_equity'

b= BetSizing(torch.Tensor({1,2}))
local root_node = {}


root_node.board = card_to_string:string_to_board('Ks')
root_node.street = 1
root_node.current_player = constants.players.P1
root_node.bets = arguments.Tensor{200, 200}
---print(b:get_possible_bets(root_node))

local eval = require 'Game.Evaluation.evaluator'
board = torch.Tensor({3})
hand = torch.Tensor({1,2,3,4,5,6})
--print (hand[2])
--print(eval:evaluate_two_card_hand(hand))
e1= evaluator:batch_eval(board)
---print(e1)
---print (e1:view(1,-1))
---print (e1:size())
e2 = e1:view(game_settings.card_count, 1)
----print(e2)
---print(e2:size())

---print(evaluator:evaluate_two_card_hand(hand))
--print (card_to_string:card_to_rank(hand))

cached = TerminalEquity()
cached:set_board(board)
print(cached.equity_matrix)
print(cached.fold_matrix)
---print ("ranges: ")
ux=card_tools:get_uniform_range(board):view(1,-1)
---print(ux)
res = torch.mm(ux, cached.equity_matrix);
---print(res)

board = torch.Tensor({4})
print("last: ")
---print(card_tools.get_board_index(board))
---print(card_tools:get_board_index(board))
buck = Bucketer()
x = buck:compute_buckets(board)
print(x)

print("class_ids")
class_ids = torch.range(1, 36)

print(class_ids)
class_ids = class_ids:view(1, 36):expand(6,36)

print(class_ids)


card_buckets = x:view(6, 1):expand(6,36)

print("card_buckets")
print(card_buckets)

---print("x")
---print(x)


print("trying cfr:")
local children_ranges_absolute = torch.Tensor(2,3,2,3):fill(1)

print(children_ranges_absolute[{{},2,{}}])

---print (card_tools:get_second_round_boards())
---print(cached:get_last_round_call_matrix(board,cached.equity_matrix))
---print(board:size(1) == 1 )
---print (cached.equity_matrix)
---print (e1:view(game_settings.card_count,1):expandAs(cached.equity_matrix))
---print (e1:view(1, game_settings.card_count):expandAs(cached.equity_matrix))
-----------------------



--------------------

--[[
--- Generates the necessary data to train the neural network that will initialize the ranges
local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local game_settings = require 'Settings.game_settings'
local card_tools = require 'Game.card_tools'
require 'TerminalEquity.terminal_equity'
require 'nn'
local TreeData = torch.class('TreeData')



function TreeData:__init(tree)
  self.board = torch.Tensor()
  self.row = 1
  self.features_tensor = torch.Tensor()
  self.labels_tensor = torch.Tensor()
  self.tree = tree
  self.max_history_size = 3
  self.max_num_actions = 4
  self.history_size = self.max_history_size*self.max_num_actions


end

--- Running many iterations
function TreeData:get_training_set(root,num_iter)
  --- Constructing the histories for inner nodes:
  ---self.tree = self:update_histories(self.tree)
  self:update_histories(self.tree)
  --- Fixing some parameters:
  --- Iterating amongs nodes:

  for i = 1,num_iter do
    self:get_node_data(root)
  end
end


--- Recursive visiting the tree:
function TreeData:get_node_data(node)

  ---Verification:
  ---print ("number child")
  ---print(#node.children)
  --- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    ---print("here")
    ---print(node.current_player)
    --- Getting the board :
    local board_bucket = self:get_board_from_node(node)
    --- Getting the private card:
    local privatecard_bucket = self:get_private_card_from_node(node)
    --- Getting the history:
    local history_bucket = self:get_history(node)
    ---local size_private = torch.Tensor()

    --- Building each matrix:
    board_bucket = board_bucket:view(1,board_bucket:size(2)):expandAs(privatecard_bucket)
    history_bucket = history_bucket:view(1,history_bucket:size(2)):repeatTensor(game_settings.card_count,1)

    --- Concatenate columns:
    local features_bucket = board_bucket:cat(privatecard_bucket)
    features_bucket = features_bucket:cat(history_bucket)

    --- Get strategy:
    local strategy_bucket = self:get_strategy_from_node(node)


    --- Concatenate rows:
    self.features_tensor = self.features_tensor:cat(features_bucket,1)
    ----print(strategy_bucket)
    ----print(self.labels_tensor)
    self.labels_tensor = self.labels_tensor:cat(strategy_bucket,1)

    for i =1,#node.children do
      local child_node = node.children[i]
      self:get_node_data(child_node)
    end
  else

  for i =1,#node.children do
    local child_node = node.children[i]
    self:get_node_data(child_node)
  end

  end
end



--- Contructs the bucket for the board data in the node
function TreeData:get_board_from_node(node)
  local data = torch.Tensor(1,game_settings.card_count):zero()
  data[{1,node.board[1]}] = 1
  return data
end

--- Contructs the bucket for the private card info in the node
function TreeData:get_private_card_from_node(node)
  local data = torch.Tensor(game_settings.card_count,game_settings.card_count):zero()
  ---for i in 1,game_settings.card_count do
  for i = 1,node.strategy:size(2) do
    data[{i,i}] = 1
  end

  return data
end



--- function that gets the strategy for each node
--- @param: root of the tree
--- @return: updated tree
function TreeData:get_strategy_from_node(node)

  local strategy = node.strategy
  print("beofre")
  print(strategy:size())
  local size_strat = strategy:size(1)

  local num_zeros_to_add = self.max_num_actions-size_strat
  module = nn.Padding(1, num_zeros_to_add, 2, 0)
  strategy = module:forward(strategy)
  print("after")
  print(strategy:size())

  return strategy
end

--- function that gets the history for each node and transforms into vector
--- @param: node
--- @return: history vector
function TreeData:get_history(node)

if node.history == 0 then
  return torch.Tensor(1,self.history_size):zero()
else
  return self:transform_history_to_vec(node.history)
end

end

--- function that gets the history for each node and transforms into vector
--- @param: node
--- @return: history vector
function TreeData:transform_history_to_vec(history)
  --- Length of the history
  local history_lenght = string.len(history)
  --- initialize vector :
  history_vector = torch.Tensor(1,self.history_size):zero()
  --- iterate and assing buckets

  for i =1,history_lenght do
    local history_number = tonumber(string.sub(history,i,i))
    history_vector[{1,(i-1)*self.max_num_actions+history_number}] = 1
  end
  return history_vector
end



function TreeData:get_beting_history(node)
end


--- function that updates the histories for each inner node:
--- @param: root of the tree
--- @return: updated tree
function TreeData:update_histories(node)

  if (not node.terminal and node.current_player ~=0) then
    for i =1,#node.children do
      local children = node.children[i]
      if node.history ~= 0 then
      ---WORKING::node.children[i].history = node.history..node.history_vec[i]
        node.children[i].history = node.history..node.history_vec[i]
        node.children[i].last_history = node.history_vec[i]
        ---self:set_beting_tensor_to_node(node)
      else
        node.children[i].history = node.history_vec[i]
        node.children[i].last_history = node.history_vec[i]
        ---self:set_beting_tensor_to_node(node)
      end
      self:update_histories(children)

    end
  else
    if not node.terminal then
      for i  = 1,#node.children do
      self:update_histories(node.children[i])
      end
    end

  end


end


--- function that sets the beting tensor to each node
--- @param: root of the tree
--- @return: updated tree
function TreeData:set_beting_tensor_to_node(node)

  local num_players = constants.players_count
  local num_streets = constants.streets_count
  local num_actions = 4

  data_tensor = torch.Tensor(num_players,num_streets,num_actions):fill(0)

  local last_action = tonumber(node.last_history)

  if (last_action>0 and last_action <= num_actions) then

    data_tensor[{node.current_player,node.street,last_action}] = 1
    node.bet_tensor = data_tensor
  end

end

--[[
function TreeData:get_info_from_node(node)
  local data = torch.Tensor(1,6):zero()
  ---if node.board ~=0 then
  print(node.board)
  data[{1,node.board[1]}] = 1
  print(data)
  ---end
  return data
end


--]]
