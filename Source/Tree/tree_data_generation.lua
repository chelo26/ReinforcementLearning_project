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
    ---local history_bucket = self:get_history(node)
    ---local size_private = torch.Tensor()
    --- Getting the betting history:
    history_bucket = self:get_beting_history(node)


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
  self:update_histories(node)
  self:set_last_bet_history_to_tree(node)
  self:set_beting_history_to_tree(node)
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


function TreeData:set_beting_history_to_tree(node)
  local children = node.children
  if node.parent ~= nil then
    for i =1,#node.children do
      node.bet_history = node.parent.bet_history + node.bet_history
    end
  end
end



function TreeData:set_last_bet_history_to_tree(node)
  local children = node.children
  for i =1,#node.children do
    self:set_beting_tensor_to_node(node)
    self:set_last_bet_history_to_tree(children[i])
  end
  --[[
  --- Check if the node has a parent, if it hasen't continue to children
  if node.parent == nil then
    local children = node.children
    for i =1,#node.children do
      self:set_beting_history_to_node(children[i])
    end
  else
    --- if it has a parent:
    self:set_beting_tensor_to_node(node)
  end--]]
end




--- function that sets the beting tensor to each node
--- @param: root of the tree
--- @return: updated tree
function TreeData:set_beting_tensor_to_node(node)
  --- Tensor dimensions
  local num_players = constants.players_count
  local num_streets = constants.streets_count
  local num_raises = #arguments.bet_sizing+2 ---Taking account for all in and call
  local num_actions = 2 --- Call and Raise
  local parent = node.parent
  --- History indexes
  local current_raise = 1
  local last_action = tonumber(node.last_history)
  local start_action = tonumber(node.last_history)
  ---print(last_action)
  data_tensor = torch.Tensor(num_players,num_streets,num_raises,num_actions):fill(0)

  ---- INTERESTING: CHECKS THE FIRST CONDITION AND IF IS TRUE DOESN'T CHECKS NEXT ONE
  if parent ~= nil  and parent.current_player ~= constants.players.chance then

    ---if node.current_player ~=0 then
    if last_action>num_actions then
      current_raise = last_action - current_raise
      last_action = 2
      ---current_raise = current_raise+last_action - num_actions
    else
      last_action = 1
    end

    if start_action > 1  then
      data_tensor[{parent.current_player,parent.street,current_raise,last_action}] = 1
    end
    ---end

  end
  node.bet_history = data_tensor

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
end--]]
