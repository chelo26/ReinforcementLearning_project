require "Player.continual_resolving"
local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local game_settings = require 'Settings.game_settings'
local card_tools = require 'Game.card_tools'
local card_to_string = require 'Game.card_to_string_conversion'
require "Tree.tree_values"
---local continual_resolving = ContinualResolving()

local builder = PokerTreeBuilder()

local params = {}

params.root_node = {}
params.root_node.board = card_to_string:string_to_board('Ks')
params.root_node.street = 2
params.root_node.current_player = constants.players.P1
params.root_node.bets = arguments.Tensor{300, 300}

local tree = builder:build_tree(params)

print("start")
print(tree.strategy)

--local tree_values = TreeValues()
---tree_values:compute_values(tree)
