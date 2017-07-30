local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local card_to_string = require 'Game.card_to_string_conversion'
local card_tools = require 'Game.card_tools'
local game_settings = require 'Settings.game_settings'
local bet_sizing = require 'Game.bet_sizing'

require 'math'
require 'Tree.tree_builder'
require 'Tree.tree_data_generation'
require 'Tree.tree_visualiser'
require 'nn'
require 'Tree.tree_cfr'
require 'NN.strategy_net_builder'
require 'NN.strategy_net_trainer'

--- Game Tree Builder:
local builder = PokerTreeBuilder()

--- Root node:
local params = {}
params.root_node = {}
params.root_node.board = card_to_string:string_to_board('')
params.root_node.street = 2
params.root_node.current_player = constants.players.P1
params.root_node.bets = arguments.Tensor{200, 200}

--- Build tree
local tree = builder:build_tree(params)

--- Build game
local game = TreeData(tree)

--- setting training_set
game:get_training_set(tree,1)

--- CFR Solver
local starting_ranges = arguments.Tensor(constants.players_count, game_settings.card_count)
starting_ranges[1]:copy(card_tools:get_uniform_range(params.root_node.board))
starting_ranges[2]:copy(card_tools:get_uniform_range(params.root_node.board))
local tree_cfr = TreeCFR()
print("start solver")
tree_cfr:run_cfr(tree, starting_ranges)


print(game.output_tensor:size())
print(game.input_tensor:size())

-- Building the neural net model
strategy_nn = StrategyNN()
nn_model = strategy_nn.model

-- Building trainer:
nn_trainer = NNTrainer(game,nn_model)

-- Criterion definition:
criterion =nn.MSECriterion()
local train_data = nn_trainer.training_data

loss_x = criterion:forward(nn_model:forward({train_data.features,train_data.masks}), train_data.targets)
print(loss_x)
---print(nn_model:getParameters())

-- Options:
opt = {}
opt.learningRate = 0.001
opt.momentum = 0

---Training:
train_loss= nn_trainer:train(nn_model,criterion,opt)

loss_x = criterion:forward(nn_model:forward({train_data.features,train_data.masks}), train_data.targets)

print(loss_x)








--[[
--- CFR Solver
local starting_ranges = arguments.Tensor(constants.players_count, game_settings.card_count)
starting_ranges[1]:copy(card_tools:get_uniform_range(params.root_node.board))
starting_ranges[2]:copy(card_tools:get_uniform_range(params.root_node.board))
local tree_cfr = TreeCFR()
print("start solver")
tree_cfr:run_cfr(tree, starting_ranges)

--- visualiser:
local visualiser = TreeVisualiser()
visualiser:graphviz(tree, "test_start5a")
print(tree.current_player)


--]]
