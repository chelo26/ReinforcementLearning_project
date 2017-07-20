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
local builder = PokerTreeBuilder()

local params = {}

params.root_node = {}
params.root_node.board = card_to_string:string_to_board('')
params.root_node.street = 1
params.root_node.current_player = constants.players.P1
params.root_node.bets = arguments.Tensor{200, 200}
---params.root_node.limit_to_street = True
---print (params.root_node.bets[2])


local tree = builder:build_tree(params)
local game = TreeData(tree)

root = game.tree
---game:get_beting_history(root)

game:update_histories(root)

print(root.children[2].last_bet_history)


---game:set_last_bet_history_to_tree(node)
---game:set_beting_history_to_tree(node)

--[[

test_node = game.tree.children[2]
print(test_node.bet_history)

test_node2 = game.tree.children[2].children[2]
print(test_node2.bet_history)




local td = TreeData(tree)
td:update_histories(td.tree)
node_test=td.tree.children[2].children[2]

print(node_test.last_bet_history)

--- visualiser:
local visualiser = TreeVisualiser()

visualiser:graphviz(tree, "test_start6")
print(tree.current_player)





--[[

local visualiser = TreeVisualiser()

visualiser:graphviz(tree, "test_start3")
print(tree.current_player)


---str = td.tree.children[1].children[2].history
---print(str)
---print(td:get_node_data(str))





test = td.tree

for i =1,#test.children do
  print(test.children[i].history)
end








-- to test:
for i =1,#td.tree.children[1].children[3].children[3].children do
  print(td.tree.children[1].children[3].children[3].children[i].history)
end


module = nn.Padding(1, 2, 1, 0)
t= torch.Tensor(3,3):fill(1)
print(t)
t = module:forward(t)
print(t:t())
print(type(t:size(1)))



local td = TreeData()
td:get_training_set(tree,2)
---td:get_node_data(tree)

print(td.features_tensor)
print(td.features_tensor:size())


t= torch.Tensor(1,3):fill(1)
b= torch.Tensor(3,3):fill(0)
t = t:view(1,t:size(2)):expandAs(b)
print(t)
print(b)
print(b:cat(t))--]]
