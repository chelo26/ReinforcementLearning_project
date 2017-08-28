--- Runs Counterfactual Regret Minimization (CFR) to approximately
-- solve a game represented by a complete game tree.
--
-- As this class does full solving from the root of the game with no
-- limited lookahead, it is not used in continual re-solving. It is provided
-- simply for convenience.
-- @classmod tree_cfr

local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local game_settings = require 'Settings.game_settings'
local card_tools = require 'Game.card_tools'
require 'TerminalEquity.terminal_equity'
require 'math'
require 'Tree.tree_values'
require 'Adversarials.exploitabilityVS'
local TreeCFR = torch.class('TreeCFR2')

--- Constructor
function TreeCFR:__init()
  --for ease of implementation, we use small epsilon rather than zero when working with regrets
  self.regret_epsilon = 1/1000000000
  self._cached_terminal_equities = {}
  self.strategies_tensor = torch.FloatTensor()
  self.total_strategies = {}
  self.exploitability_table = {}
  self.tree_values = TreeValues()
  self.number_of_explo_points = 5
  self.exploitability_vec = 0
  self.cfr_skip = 0
end

--- Gets an evaluator for player equities at a terminal node.
--
-- Caches the result to minimize creation of @{terminal_equity|TerminalEquity}
-- objects.
-- @param node the terminal node to evaluate
-- @return a @{terminal_equity|TerminalEquity} evaluator for the node
-- @local
function TreeCFR:_get_terminal_equity(node)
  local cached = self._cached_terminal_equities[node.board]
  if cached == nil then
    cached = TerminalEquity()
    cached:set_board(node.board)
    self._cached_terminal_equities[node.board] = cached
  end

  return cached
end

--- Recursively walks the tree, applying the CFR algorithm.
-- @param node the current node in the tree
-- @param iter the current iteration number
-- @local
function TreeCFR:cfrs_iter_dfs( node, iter )

  assert(node.current_player == constants.players.P1 or node.current_player == constants.players.P2 or node.current_player == constants.players.chance)

  local opponent_index = 3 - node.current_player

  --dimensions in tensor
  local action_dimension = 1
  local card_dimension = 2

  --compute values using terminal_equity in terminal nodes
  if(node.terminal) then


    local terminal_equity = self:_get_terminal_equity(node)

    local values = node.ranges_absolute:clone():fill(0)

    if(node.type == constants.node_types.terminal_fold) then
      terminal_equity:tree_node_fold_value(node.ranges_absolute, values, opponent_index)
    else
      terminal_equity:tree_node_call_value(node.ranges_absolute, values)
    end

    --multiply by the pot
    values = values * node.pot
    node.cf_values = values:viewAs(node.ranges_absolute)
    ---print(node.history_actions)
    ---print(values)
  else

    local actions_count = #node.children
    local current_strategy = nil

    if node.current_player == constants.players.chance then
      current_strategy = node.strategy
    else
      --we have to compute current strategy at the beginning of each iteraton

      --initialize regrets in the first iteration
      node.regrets = node.regrets or arguments.Tensor(actions_count, game_settings.card_count):fill(self.regret_epsilon) --[[actions_count x card_count]]
      node.possitive_regrets = node.possitive_regrets or arguments.Tensor(actions_count, game_settings.card_count):fill(self.regret_epsilon)

      --compute positive regrets so that we can compute the current strategy fromm them
      node.possitive_regrets:copy(node.regrets)
      node.possitive_regrets[torch.le(node.possitive_regrets, self.regret_epsilon)] = self.regret_epsilon

      --compute the current strategy
      local regrets_sum = node.possitive_regrets:sum(action_dimension)
      if iter ==1 then
        current_strategy = node.strategy
      else
        current_strategy = node.possitive_regrets:clone()
        current_strategy:cdiv(regrets_sum:expandAs(current_strategy))
      end
      ---print(current_strategy)
    end

	--current cfv [[actions, players, ranges]]
    local cf_values_allactions = arguments.Tensor(actions_count, constants.players_count, game_settings.card_count):fill(0)

    local children_ranges_absolute = {}

    if node.current_player == constants.players.chance then
      local ranges_mul_matrix = node.ranges_absolute[1]:repeatTensor(actions_count, 1)
      children_ranges_absolute[1] = torch.cmul(current_strategy, ranges_mul_matrix)
      ---print("ranges")
      ---print(ranges_mul_matrix)
      ---print("current ")
      ---print(current_strategy)
      ranges_mul_matrix = node.ranges_absolute[2]:repeatTensor(actions_count, 1)
      children_ranges_absolute[2] = torch.cmul(current_strategy, ranges_mul_matrix)
    else
      local ranges_mul_matrix = node.ranges_absolute[node.current_player]:repeatTensor(actions_count, 1)
      children_ranges_absolute[node.current_player] = torch.cmul(current_strategy, ranges_mul_matrix)

      children_ranges_absolute[opponent_index] = node.ranges_absolute[opponent_index]:repeatTensor(actions_count, 1):clone()
    end
    ---print(children_ranges_absolute[1])
    ---print(children_ranges_absolute[2])

    for i = 1,#node.children do
      local child_node = node.children[i]
      --set new absolute ranges (after the action) for the child
      child_node.ranges_absolute = node.ranges_absolute:clone()

      child_node.ranges_absolute[1]:copy(children_ranges_absolute[1][{i}])
      child_node.ranges_absolute[2]:copy(children_ranges_absolute[2][{i}])
      self:cfrs_iter_dfs(child_node, iter, card_count)
      cf_values_allactions[i] = child_node.cf_values
    end

    node.cf_values = arguments.Tensor(constants.players_count, game_settings.card_count):fill(0)

    if node.current_player ~= constants.players.chance then
      local strategy_mul_matrix = current_strategy:viewAs(arguments.Tensor(actions_count, game_settings.card_count))

      node.cf_values[node.current_player] = torch.cmul(strategy_mul_matrix, cf_values_allactions[{{}, node.current_player, {}}]):sum(1)
      node.cf_values[opponent_index] = (cf_values_allactions[{{}, opponent_index, {}}]):sum(1)
    else
      node.cf_values[1] = (cf_values_allactions[{{}, 1, {}}]):sum(1)
      node.cf_values[2] = (cf_values_allactions[{{}, 2, {}}]):sum(1)
    end

    if node.current_player ~= constants.players.chance then
      --computing regrets
      local current_regrets = cf_values_allactions[{{}, {node.current_player}, {}}]:reshape(actions_count, game_settings.card_count):clone()
      current_regrets:csub(node.cf_values[node.current_player]:view(1, game_settings.card_count):expandAs(current_regrets))

      self:update_regrets(node, current_regrets)

      --accumulating average strategy
      self:update_average_strategy(node, current_strategy, iter)
    end
  end
end

--- Update a node's total regrets with the current iteration regrets.
-- @param node the node to update
-- @param current_regrets the regrets from the current iteration of CFR
-- @local
function TreeCFR:update_regrets(node, current_regrets)
  --node.regrets:add(current_regrets)
  --local negative_regrets = node.regrets[node.regrets:lt(0)]
  --node.regrets[node.regrets:lt(0)] = negative_regrets
  node.regrets:add(current_regrets)
  node.regrets[torch.le(node.regrets, self.regret_epsilon)] = self.regret_epsilon
end

--- Update a node's average strategy with the current iteration strategy.
-- @param node the node to update
-- @param current_strategy the CFR strategy for the current iteration
-- @param iter the iteration number of the current CFR iteration
function TreeCFR:update_average_strategy(node, current_strategy, iter)
--- CHANGE HERE
  ---if iter >1 then
  if iter >0 then
    local iters_skiped = self.cfr_skip or arguments.cfr_skip_iters
    if iter > iters_skiped then
    ---if iter > arguments.cfr_skip_iters then
      node.strategy = node.strategy or arguments.Tensor(actions_count, game_settings.card_count):fill(0)
      node.iter_weight_sum = node.iter_weight_sum or arguments.Tensor(game_settings.card_count):fill(0)
      local iter_weight_contribution = node.ranges_absolute[node.current_player]:clone()
      iter_weight_contribution[torch.le(iter_weight_contribution, 0)] = self.regret_epsilon
      node.iter_weight_sum:add(iter_weight_contribution)
      ---print(iter_weight_contribution)
      local iter_weight = torch.cdiv(iter_weight_contribution, node.iter_weight_sum)
      ---print(iter_weight)
      local expanded_weight = iter_weight:view(1, game_settings.card_count):expandAs(node.strategy)
      ----print(expanded_weight)
      local old_strategy_scale = expanded_weight * (-1) + 1 --same as 1 - expanded weight
      ---print(old_strategy_scale)
      node.strategy:cmul(old_strategy_scale)
      local strategy_addition = current_strategy:cmul(expanded_weight)
      node.strategy:add(strategy_addition)
    end
  end
end

--- Run CFR to solve the given game tree.
-- @param root the root node of the tree to solve.
-- @param[opt] starting_ranges probability vectors over player private hands
-- at the root node (default uniform)
-- @param[opt] iter_count the number of iterations to run CFR for
-- (default @{arguments.cfr_iters})
function TreeCFR:run_cfr( root, starting_ranges, iter_count )

  assert(starting_ranges)
  local iter_count = iter_count or arguments.cfr_iters
  root.ranges_absolute =  starting_ranges

  local explo_counter = math.ceil(iter_count/self.number_of_explo_points)
  for iter = 1,iter_count do
    self:extract_strategies(root)
    table.insert(self.total_strategies,self.strategies_tensor)
    self:cfrs_iter_dfs(root, iter)
    --- Extract the strategies,insert then in the table
    --- and initializing the strategies tensor
    self.strategies_tensor = torch.FloatTensor()

    if iter%explo_counter == 0 or iter ==1 then

      self:normalize_strategies(root)
      ---print(iter)
      self:calculate_exploitability(root,starting_ranges)
    end
  end
  self.exploitability_vec = torch.FloatTensor(self.exploitability_table)

end

--- Extract all strategies
function TreeCFR:extract_strategies(root)
  local children = root.children
  if #children >0 then
    local extracted_strat = root.strategy:clone()

    self.strategies_tensor = self.strategies_tensor:cat(extracted_strat,1)

    for i = 1,#children do
      self:extract_strategies(children[i])
    end
  end
end

--- Normalize the tree's strategies
function TreeCFR:normalize_strategies(root)
  local children = root.children
  if #children >0 then
    local normalization_term = root.strategy:sum(1):repeatTensor(root.actions:size(1),1)
    root.strategy:cdiv(normalization_term)
    for i = 1,#children do
      self:normalize_strategies(children[i])
    end
  end
end

--- Function to add exploitability to the table
function TreeCFR:calculate_exploitability(root,starting_ranges)
  self.tree_values:compute_values(root,starting_ranges)
  local explo_root = root.exploitability
  table.insert(self.exploitability_table,explo_root)
end


---- EVALULATION
function TreeCFR:run_match_cfr(root, starting_ranges,second_tree ,iter_count, number_tests,number_games ,cfr_skip)

  assert(starting_ranges)
  local iter_count = iter_count or arguments.cfr_iters
  local cfr_skip = cfr_skip or self.cfr_skip
  root.ranges_absolute =  starting_ranges
  local intervals = math.ceil(iter_count/self.number_of_explo_points)
  ---local match_interval = torch.range(1,iter_count,intervals)
  ---local win_rate_tensor = torch.FloatTensor(1,match_interval:size(1)):fill(0)
  ---local pot_gain_tensor = torch.FloatTensor(1,match_interval:size(1)):fill(0)
  local win_rate_table = {}
  local pot_gain_table = {}
  ---print('match',match_interval)
  local num_element = 1
  for iter = 1,iter_count do

    if iter > cfr_skip then
      if iter%intervals == 0 or iter ==1 then
        ---local pot_gain,win_rate = get_returns(second_tree,root,number_games)
        local pot_gain_tensor,win_rate_tensor = self:get_tensor_returns(second_tree,root,number_tests,number_games)
        local avg_pot_gain = pot_gain_tensor:mean()
        local avg_win_rate = win_rate_tensor:mean()
        table.insert(pot_gain_table, avg_pot_gain)
        table.insert(win_rate_table, avg_win_rate)
      end
    end

    self:cfrs_iter_dfs(root, iter)
    ---if iter == match_interval[num_element] then
      ----print("iter, ",iter)
      ---print("match_interval, ",match_interval[num_element])
      ---print("element, ",num_element)

      ---num_element = num_element + 1
    ---end
    ---print("itersss ", iter)
    end

  return torch.FloatTensor(pot_gain_table),torch.FloatTensor(win_rate_table)
end


function TreeCFR:run_clean_cfr( root, starting_ranges, iter_count )

  assert(starting_ranges)
  local iter_count = iter_count or arguments.cfr_iters
  root.ranges_absolute =  starting_ranges

  for iter = 1,iter_count do

    self:cfrs_iter_dfs(root, iter)
    --- Extract the strategies,insert then in the table
    --- and initializing the strategies tensor
    ---self:normalize_strategies(root)
  end
end



function TreeCFR:get_returns(tree1,tree2,num_iter)
    local num_iter = num_iter or 100
    local evaluator = StrategyEvaluator(tree1,tree2)
    evaluator:play_all_combinations_n_times(tree1,tree2,num_iter)
    local win_rate = evaluator.A2_winning_rate
    local avg_gain= evaluator.A2_avg_pot_won
    return avg_gain,win_rate
end

function TreeCFR:get_tensor_returns(tree1,tree2,number_of_tests,num_iter)
    local num_iter = num_iter or 100
    local number_of_tests = number_of_tests or 10
    local avg_gain_tensor = torch.FloatTensor(1,number_of_tests)
    local win_rate_tensor = torch.FloatTensor(1,number_of_tests)

    for i =1,number_of_tests do
        local avg_gain,win_rate = self:get_returns(tree1,tree2,num_iter)
        avg_gain_tensor[{1,i}]= avg_gain
        win_rate_tensor[{1,i}]= win_rate

    end
    return avg_gain_tensor,win_rate_tensor
end
