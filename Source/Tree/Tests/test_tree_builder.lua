local arguments = require 'Settings.arguments'
local constants = require 'Settings.constants'
local card_to_string = require 'Game.card_to_string_conversion'
local card_tools = require 'Game.card_tools'
local game_settings = require 'Settings.game_settings'

require 'Tree.tree_builder'
require 'Tree.tree_visualiser'


local builder = PokerTreeBuilder()

local params = {}

params.root_node = {}
params.root_node.board = card_to_string:string_to_board('')
params.root_node.street = 1
params.root_node.current_player = constants.players.chance
params.root_node.bets = arguments.Tensor{200, 200}
---print (params.root_node.bets[2])
local tree = builder:build_tree(params)

print(tree.history)
for i =1,#tree.children[2].children do
  print(tree.children[2].children[i].history_vec)
end



---local visualiser = TreeVisualiser()

---visualiser:graphviz(tree, "test_history")
---print (params.root_node.current_player)
---print(tree.strategy)
---print(tree.children[2].strategy)

---print(tree.children[2].children[2].children[2].history)

--test = BetSizing(arguments.Tensor{1})
---print(test:get_possible_bets(params.root_node))
