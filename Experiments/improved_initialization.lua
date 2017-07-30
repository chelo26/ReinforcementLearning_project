--- Libraries:
arguments = require 'Settings.arguments'
constants = require 'Settings.constants'
card_to_string = require 'Game.card_to_string_conversion'
card_tools = require 'Game.card_tools'
game_settings = require 'Settings.game_settings'
Plot = require 'itorch.Plot'
nninit = require 'nninit'
require 'torch'
require 'math'
require 'Tree.tree_builder'
require 'Tree.tree_data_generation'
require 'Tree.tree_visualiser'
require 'nn'
require 'Tree.tree_cfr'
require 'nngraph'
require 'optim'
require 'image'
require 'NN.strategy_net_builder'
require 'NN.strategy_net_trainer'



--- Create the tree
builder = PokerTreeBuilder()
--- Parameters for the tree
params = {}
params.root_node = {}
params.root_node.board = card_to_string:string_to_board('')
params.root_node.street = 1
params.root_node.current_player = constants.players.P1
params.root_node.bets = arguments.Tensor{200, 200}

--- BUild tree
tree = builder:build_tree(params)
--- build data
game = TreeData(tree)

--- CFR Solver
local starting_ranges = arguments.Tensor(constants.players_count, game_settings.card_count)
starting_ranges[1]:copy(card_tools:get_uniform_range(params.root_node.board))
starting_ranges[2]:copy(card_tools:get_uniform_range(params.root_node.board))
local tree_cfr = TreeCFR()
print("Solver")
tree_cfr:run_cfr(tree, starting_ranges)
print("geting training set")
game:get_training_set(tree,1)


--- Strategy improver Trainer:

-- Building the neural net model
strategy_nn = StrategyNN()
nn_model = strategy_nn.model
-- Building trainer:
nn_trainer = NNTrainer(game,nn_model)
-- Options:
opt = {}
opt.learningRate = 0.0001
opt.momentum = 0.95
opt.validate = true
