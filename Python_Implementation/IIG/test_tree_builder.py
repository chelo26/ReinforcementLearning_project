import numpy as np
from Settings import arguments
from Settings import constants
from Settings import card_settings
from Game.CardTools import CardTools
from Game.CardStringConverter import CardStringConverter
from Game.BetSizing import BetSizing
from Settings import arguments
from Tree.TreeTools import Node
from Tree.TreeTools import Params
from Tree.StrategyFilling import StrategyFilling
from copy import deepcopy

card_tools = CardTools()
card_to_string = CardStringConverter()

# Passing parameters:
params= Params(1,[200,200],constants.players.P2,4,False)
#print("bet: ",params.bet_sizing is None)

p1 = PokerTreeBuilder()
root = p1.build_tree(params)

root.strategy
root.children[1].strategy


