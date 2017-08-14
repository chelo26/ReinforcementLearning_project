--- Generates the necessary data to train the neural network that will initialize the ranges
local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local game_settings = require 'Settings.game_settings'
local card_tools = require 'Game.card_tools'
local card_to_string = require 'Game.card_to_string_conversion'

require 'TerminalEquity.terminal_equity'
require 'nn'
local TreeData = torch.class('TreeData')

function TreeData:__init(tree)
  self.board = torch.Tensor()
  self.row = 1
  self.input_tensor = torch.Tensor()
  self.output_tensor = torch.Tensor()
  self.tree = tree
  self.max_num_actions = 3 + #arguments.bet_sizing

end

--- Running many iterations
function TreeData:get_training_set(root,num_iter)
  --- Constructing the histories for inner nodes:
  ---self.tree = self:update_histories(self.tree)
  self:set_beting_history(self.tree)
  --- Fixing some parameters:
  --- Iterating amongs nodes:

  for i = 1,num_iter do
    self:get_node_data(root)
  end
end


-- Recursive visiting the tree:
function TreeData:get_node_data(node)
--- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    --- Getting the board :
    local board_bucket = self:get_board_from_node(node)
    --- Getting the private card:
    ---local privatecard_bucket = self:get_private_card_from_node(node)
    --- Getting the betting history:
    local history_bucket = self:get_beting_history(node)
    --- Concatenating features

    local features_bucket,strategy_bucket = self:generate_features_and_strategy(board_bucket,history_bucket,node)

    ---local features_bucket = board_bucket:cat(history_bucket)
    self.input_tensor = self.input_tensor:cat(features_bucket,1)
    self.output_tensor =  self.output_tensor:cat(strategy_bucket,1)
  end
  if node.children ~= nil then
    for i =1,#node.children do
      local child_node = node.children[i]
      self:get_node_data(child_node)
    end
  end

end




function TreeData:get_possible_actions_and_strategy_indexes(root_actions,node_actions)

  local action_indexes = {}
  local strategy_indexes = {}

  for i = 1,root_actions:nElement() do
      for j = 1,node_actions:nElement() do
          if root_actions[i] == node_actions[j] then
              action_indexes[i] = i
              strategy_indexes[j]= j
              break
          else
              action_indexes[i] = 0
          end
      end

  end
  action_indexes = torch.Tensor(action_indexes)
  strategy_indexes = torch.Tensor(strategy_indexes)
  return action_indexes,strategy_indexes
end


--- Contructs the bucket for the private card info in the node
function TreeData:generate_features_and_strategy(board_tensor,beting_tensor,node)
  --- Initialize
  local input_tensor = torch.Tensor()
  local output_tensor = torch.Tensor()
  --- board
  local board = 0
  if node.board:nDimension() ~= 0 then
    board = node.board[1]
  end
  ---private
  ---local private_card_matrix = self:get_private_card_from_node()
  local possible_private_cards = torch.range(1,game_settings.card_count)
  --- together
  local strategy,actions_tensor = self:get_strategy_from_node(node)

  local used_hands_dictionary = self:generate_empty_used_hands_dictionary()

  for i=1,game_settings.card_count do
    -- Input
    local private_card = possible_private_cards[i]
    local private_card_tensor = self:convert_card_to_rank_tensor(private_card)
    -- Output
    local strategy_row = strategy[i]
    -- used:
    local rank = card_to_string:card_to_rank(i)

    strategy_row = strategy_row:reshape(1,strategy_row:nElement())
    if i ~=board and not used_hands_dictionary[rank] then
      local input_row = board_tensor:cat(private_card_tensor):cat(beting_tensor):cat(actions_tensor)
      input_tensor = input_tensor:cat(input_row,1)
      output_tensor = output_tensor:cat(strategy_row,1)
      used_hands_dictionary[rank] = true
    end
  end
  return input_tensor,output_tensor
end


--- Contructs the bucket for the board data in the node
function TreeData:get_board_from_node(node)
  local board_tensor = torch.Tensor(1,game_settings.rank_count):zero()
  if node.board:nDimension() ~=0 then
    local rank_position = card_to_string:card_to_rank(node.board[1])
    board_tensor[{1,rank_position}] = 1
  end
  return board_tensor
end

--- Contructs the bucket for the private card info in the node
--- @param:
--- @return: identity matrix 6x6
function TreeData:get_private_card_from_node()
  local data = torch.Tensor(game_settings.card_count,game_settings.card_count):zero()
  ---for i in 1,game_settings.card_count do
  for i = 1,data:size(1) do
    data[{i,i}] = 1
  end

  return data
end

--- Contructs the bucket for the private card info in the node
--- @param:
--- @return: identity matrix 6x6
function TreeData:convert_card_to_rank_tensor(card)
  local rank_tensor = torch.Tensor(1,game_settings.rank_count):zero()
  local rank_position = card_to_string:card_to_rank(card)
  rank_tensor[{1,rank_position}] = 1
  return rank_tensor
end

--- Generates a dictionary of used hands
--- @param:
--- @return: identity matrix 6x6
function TreeData:generate_empty_used_hands_dictionary(card)
  used_hands ={}
  used_hands[1]=false
  used_hands[2]=false
  used_hands[3]=false
  return used_hands
end





--- function that gets the strategy for each node
--- @param: root of the tree
--- @return: strategy, actions
function TreeData:get_strategy_from_node(node)
  local root = self.tree
  local root_actions = root.actions
  local node_actions = node.actions

  local action_indexes,strategy_indexes = self:get_possible_actions_and_strategy_indexes(root_actions,node_actions)

  local zero_rows= torch.Tensor(1,root.strategy:size(2)):fill(0)
  local strategy = torch.Tensor()
  local row_to_add = 0
  local counter = 1
  for i =1,action_indexes:size(1) do
    if action_indexes[i] >0 then
      local strategy_row = node.strategy[counter]
      row_to_add = strategy_row:view(1,strategy_row:nElement()):clone()
      counter = counter +1
    else
        row_to_add = zero_rows
    end
    strategy = strategy:cat(row_to_add,1)
  end
return strategy:t(),action_indexes:view(1,action_indexes:nElement())
end


--- function that gets the betting history for a given node
--- @param: root of the tree
--- @return: updated tree
function TreeData:get_beting_history(node)
  local node_beting_history = node.bet_history
  ---print(node_beting_history:nElement())
  node_beting_history = node_beting_history:view(1,node_beting_history:nElement())
  return node_beting_history
end



--- function that sets the betting history for each node
--- @param: root of the tree
--- @return: updated tree
function TreeData:set_beting_history(node)
  ----self:set_beting_tensor_to_node(node)
  self:update_histories(node)
  self:set_last_bet_history_to_tree(node)
  self:set_beting_history_to_tree(node)
end


--- function that updates the histories  with the last action
--- and the vector all previous actions for each inner node:
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

--- function sets the beting tensor to each node in the tree
--- @param: root of the tree
--- @return: updated tree
function TreeData:set_last_bet_history_to_tree(node)
  local children = node.children
  for i =1,#node.children do
    self:set_beting_tensor_to_node(node)
    self:set_last_bet_history_to_tree(children[i])
  end
end

--- function that sets the beting history for each node in the tree
--- @param: root of the tree
--- @return: updated tree
function TreeData:set_beting_history_to_tree(node)
  for i =1,#node.children do
    if not node.terminal and node.children[i].bet_history ~= nil then
      node.children[i].bet_history = node.children[i].bet_history + node.bet_history
      self:set_beting_history_to_tree(node.children[i])
    end
  end
end



--- function that sets the beting tensor as a tensor:
--- [num_players, num_streets, num_raises, num_actions] to each node
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
  local start_action = tonumber(node.last_history) -- Only to verify we not in the root
  ---print(last_action)
  local data_tensor = torch.Tensor(num_players,num_streets,num_raises,num_actions):fill(0)

  ---- INTERESTING: CHECKS THE FIRST CONDITION AND IF IS TRUE DOESN'T CHECKS NEXT ONE
  if parent ~= nil  and node.current_player ~= constants.players.chance then

    ---if node.current_player ~=0 then
    if last_action>num_actions then
      current_raise = last_action - current_raise
      last_action = 2
    else
      last_action = 1
    end

    if start_action > 1  then
      data_tensor[{parent.current_player,parent.street,current_raise,last_action}] = 1
    end
  end
  node.bet_history = data_tensor
end


--- Function that gets the features and acions correspoding to each node
function TreeData:generate_features_and_actions(board_tensor,beting_tensor,node)
  --- Initialize
  local input_tensor = torch.Tensor()
  local output_tensor = torch.Tensor()

  --- board
  local board = 0
  if node.board:nDimension() ~= 0 then
    board = node.board[1]
  end
  local possible_private_cards = torch.range(1,game_settings.card_count)

  --- Getting actions
  local _,actions_tensor = self:get_strategy_from_node(node)

  for i=1,game_settings.card_count do
    -- Input
    local private_card = possible_private_cards[i]
    local private_card_tensor = self:convert_card_to_rank_tensor(private_card)
    local input_row = board_tensor:cat(private_card_tensor):cat(beting_tensor):cat(actions_tensor)
    input_tensor = input_tensor:cat(input_row,1)
  end
  return input_tensor
end


function TreeData:generate_features_and_masks(node,nn_trainer)
    --- Getting the board :
    local board_bucket = self:get_board_from_node(node)

    --- Getting the betting history
    local history_bucket = self:get_beting_history(node)

    --- Concatenating features
    local input = self:generate_features_and_actions(board_bucket,history_bucket,node)
    ---print(input)
    local features,masks = nn_trainer:convert_input_to_features_and_masks(input)

    return features,masks
end


function get_legal_actions_index(legal_actions)
  local legal_actions = legal_actions:long():view(legal_actions:nElement())
  local legal_actions_table = {}
  for i =1,legal_actions:size(1) do
    if legal_actions[i]>0 then
      table.insert(legal_actions_table,legal_actions[i])
    end
  end
  local legal_actions_index = torch.LongTensor(legal_actions_table)

  return legal_actions_index
end


-- Recursive visiting the tree:
function TreeData:generate_new_initial_strategies(node,nn_trainer)
--- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    ---local child_node = node.children[i]
    local features,masks = self:generate_features_and_masks(node,nn_trainer)
    local _,legal_actions = self:get_strategy_from_node(node)
    local new_strategy = nn_trainer:estimate_strategies(features,masks,nn_trainer.model)
    legal_actions = get_legal_actions_index(legal_actions)
    new_strategy = new_strategy:index(1,legal_actions)
    ---print(node.strategy)
    node.strategy = new_strategy
    ---print(new_strategy)
  end
  if node.children ~= nil then
    for i =1,#node.children do
      local child_node = node.children[i]
      self:generate_new_initial_strategies(child_node,nn_trainer)
    end
  end
end



function TreeData:warm_start_targets_and_regrets(node,nodeWS)
--- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    ---local features,masks = self:generate_features_and_masks(node,nn_trainer)
    ---local strategy,legal_actions = self:get_strategy_from_node(node)
    ---local new_strategy = nn_trainer:estimate_strategies(features,masks,nn_trainer.model)
    ---legal_actions = get_legal_actions_index(legal_actions)
    ---new_strategy = new_strategy:index(1,legal_actions)
    ---print(node.strategy)
    node.strategy = nodeWS.strategy:clone()
    ---node.cf_values = nodeWS.cf_values:clone()
    node.regrets = nodeWS.regrets:clone()---:fill(1e-9)
    ---print(new_strategy)
  end
  if node.children ~= nil then
    for i =1,#node.children do
      local child_node = node.children[i]
      local child_nodeWS = nodeWS.children[i]
      self:warm_start_targets_and_regrets(child_node,child_nodeWS)
    end
  end
end

function TreeData:warm_start_regrets(node,nodeWS)
--- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    ---local features,masks = self:generate_features_and_masks(node,nn_trainer)
    ---local strategy,legal_actions = self:get_strategy_from_node(node)
    ---local new_strategy = nn_trainer:estimate_strategies(features,masks,nn_trainer.model)
    ---legal_actions = get_legal_actions_index(legal_actions)
    ---new_strategy = new_strategy:index(1,legal_actions)
    ---print(node.strategy)
    ---node.strategy = nodeWS.strategy:clone()
    ---node.cf_values = nodeWS.cf_values:clone()
    node.regrets = nodeWS.regrets:clone()---:fill(1e-9)
    ---print(new_strategy)
  end
  if node.children ~= nil then
    for i =1,#node.children do
      local child_node = node.children[i]
      local child_nodeWS = nodeWS.children[i]
      self:warm_start_regrets(child_node,child_nodeWS)
    end
  end
end

function TreeData:warm_start_targets(node,nodeWS)
--- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    ---local features,masks = self:generate_features_and_masks(node,nn_trainer)
    ---local strategy,legal_actions = self:get_strategy_from_node(node)
    ---local new_strategy = nn_trainer:estimate_strategies(features,masks,nn_trainer.model)
    ---legal_actions = get_legal_actions_index(legal_actions)
    ---new_strategy = new_strategy:index(1,legal_actions)
    ---print(node.strategy)
    node.strategy = nodeWS.strategy:clone()
    ---node.cf_values = nodeWS.cf_values:clone()
    ---node.regrets = nodeWS.regrets:clone()---:fill(1e-9)
    ---print(new_strategy)
  end
  if node.children ~= nil then
    for i =1,#node.children do
      local child_node = node.children[i]
      local child_nodeWS = nodeWS.children[i]
      self:warm_start_targets(child_node,child_nodeWS)
    end
  end
end
