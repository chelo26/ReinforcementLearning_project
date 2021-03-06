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
local TreeWarmStart = torch.class('TreeWarmStart')

--- Constructor
function TreeWarmStart:__init()
  --for ease of implementation, we use small epsilon rather than zero when working with regrets
  self.regret_epsilon = 1/1000000000
  self._cached_terminal_equities = {}
  self.strategies_tensor = torch.FloatTensor()
  self.T = 0
  self.Lambda = 0.0000000001
  ----self.total_strategies = {}
  ----self.exploitability_table = {}
  ----self.tree_values = TreeValues()
  ----self.number_of_explo_points = 15
  ----self.exploitability_vec = 0
end

--- Gets an evaluator for player equities at a terminal node.
--
-- Caches the result to minimize creation of @{terminal_equity|TerminalEquity}
-- objects.
-- @param node the terminal node to evaluate
-- @return a @{terminal_equity|TerminalEquity} evaluator for the node
-- @local
function TreeWarmStart:_get_terminal_equity(node)
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
function TreeWarmStart:warm_start_dfs( node)

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
    ---node.delta_u = torch.max(values,action_dimension)-torch.min(values,action_dimension)
    ---node.absA = node.actions:size(action_dimension)
    ---node.regrets2 = node.ranges_absolute*(node.absA*(node.delta_u^2)/self.T)

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
      self:warm_start_dfs(child_node)
      cf_values_allactions[i] = child_node.cf_values

    end

    node.cf_values = arguments.Tensor(constants.players_count, game_settings.card_count):fill(0)

    if node.current_player ~= constants.players.chance then
      local strategy_mul_matrix = current_strategy:viewAs(arguments.Tensor(actions_count, game_settings.card_count))

      node.cf_values[node.current_player] = torch.cmul(strategy_mul_matrix, cf_values_allactions[{{}, node.current_player, {}}]):sum(1)
      node.cf_values[opponent_index] = (cf_values_allactions[{{}, opponent_index, {}}]):sum(1)

      --- Calculating the regrets:
      local absA = node.actions:size(action_dimension)
      node.delta_u = torch.max(node.cf_values,action_dimension)-torch.min(node.cf_values,action_dimension)
      node.delta_u = node.delta_u:repeatTensor(absA,1)
      local proba_reach_infoset = node.ranges_absolute[node.current_player]:view(1,game_settings.card_count):repeatTensor(absA,1)
      node.regrets = torch.sqrt(proba_reach_infoset:cmul(absA*(torch.pow(node.delta_u,2)/self.T)))
      node.regrets = node.regrets/absA
      node.regrets = node.regrets*self.Lambda
    else
      node.cf_values[1] = (cf_values_allactions[{{}, 1, {}}]):sum(1)
      node.cf_values[2] = (cf_values_allactions[{{}, 2, {}}]):sum(1)

    end

    if node.current_player ~= constants.players.chance then
      --computing regrets
      local current_regrets = cf_values_allactions[{{}, {node.current_player}, {}}]:reshape(actions_count, game_settings.card_count):clone()
      current_regrets:csub(node.cf_values[node.current_player]:view(1, game_settings.card_count):expandAs(current_regrets))

      ---self:update_regrets(node, current_regrets)

      --accumulating average strategy
      ---self:update_average_strategy(node, current_strategy, iter)
    end
  end
end

--- Update a node's total regrets with the current iteration regrets.
-- @param node the node to update
-- @param current_regrets the regrets from the current iteration of CFR
-- @local
function TreeWarmStart:update_regrets(node, current_regrets)
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
function TreeWarmStart:update_average_strategy(node, current_strategy, iter)
  if iter > arguments.cfr_skip_iters then
    node.strategy = node.strategy or arguments.Tensor(actions_count, game_settings.card_count):fill(0)
    node.iter_weight_sum = node.iter_weight_sum or arguments.Tensor(game_settings.card_count):fill(0)
    local iter_weight_contribution = node.ranges_absolute[node.current_player]:clone()
    iter_weight_contribution[torch.le(iter_weight_contribution, 0)] = self.regret_epsilon
    node.iter_weight_sum:add(iter_weight_contribution)
    local iter_weight = torch.cdiv(iter_weight_contribution, node.iter_weight_sum)

    local expanded_weight = iter_weight:view(1, game_settings.card_count):expandAs(node.strategy)
    local old_strategy_scale = expanded_weight * (-1) + 1 --same as 1 - expanded weight
    node.strategy:cmul(old_strategy_scale)
    local strategy_addition = current_strategy:cmul(expanded_weight)
    node.strategy:add(strategy_addition)
  end
end

--- Run CFR to solve the given game tree.
-- @param root the root node of the tree to solve.
-- @param[opt] starting_ranges probability vectors over player private hands
-- at the root node (default uniform)
-- @param[opt] iter_count the number of iterations to run CFR for
-- (default @{arguments.cfr_iters})
function TreeWarmStart:run_warm_start( root, starting_ranges, number_of_iterations)

  assert(starting_ranges)
  self.T = number_of_iterations or arguments.iterations_warm_start

  root.ranges_absolute =  starting_ranges
  self:warm_start_dfs(root, iter)

end



--- Normalize the tree's strategies
function TreeWarmStart:normalize_strategies(root)
  local children = root.children
  if #children >0 then
    local normalization_term = root.strategy:sum(1):repeatTensor(root.actions:size(1),1)
    root.strategy:cdiv(normalization_term)
    for i = 1,#children do
      self:normalize_strategies(children[i])
    end
  end
end
