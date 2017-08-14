local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local card_to_string = require 'Game.card_to_string_conversion'
require 'Tree.tree_builder'
require 'Tree.tree_visualiser'
require 'Tree.tree_cfr'
require 'Tree.tree_values'
local game_settings = require 'Settings.game_settings'
local card_tools = require 'Game.card_tools'




local builder = PokerTreeBuilder()

local params = {}

params.root_node = {}
params.root_node.board = card_to_string:string_to_board('')
params.root_node.street = 1
params.root_node.current_player = constants.players.P1
params.root_node.bets = arguments.Tensor({200,200})


local tree = builder:build_tree(params)

local visualiser = TreeVisualiser()

visualiser:graphviz(tree, "P1_start")
print(tree.current_player)






--[[

--- VALUES:
tree_value = TreeValues()
starting_ranges = arguments.Tensor(constants.players_count, game_settings.card_count)
starting_ranges[1]:copy(card_tools:get_uniform_range(params.root_node.board))
starting_ranges[2]:copy(card_tools:get_uniform_range(params.root_node.board))
tree_value:compute_values(tree,starting_ranges)




local starting_ranges = arguments.Tensor(constants.players_count, game_settings.card_count)

starting_ranges[1]:copy(card_tools:get_uniform_range(params.root_node.board))
starting_ranges[2]:copy(card_tools:get_uniform_range(params.root_node.board))
--starting_ranges[1]:copy(card_tools:get_random_range(params.root_node.board, 2))
--starting_ranges[2]:copy(card_tools:get_random_range(params.root_node.board, 4))

local tree_cfr = TreeCFR()
print (tree.strategy)
print("start solver")
tree_cfr:run_cfr(tree, starting_ranges)
--]]
