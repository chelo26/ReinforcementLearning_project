from Settings import arguments
from Settings import constants
from Settings import card_settings
from Game.CardTools import CardTools
import numpy as np
from Tree.TreeTools import Node

card_tools = CardTools()

class StrategyFilling(object):


    def fill_chance(self,node):
        assert (not node.terminal), "terminal node doesn't have strategy"
        node.strategy = np.zeros([len(node.children),card_settings.card_count])
        for i in range(len(node.children)):
            child_node = node.children[i]
            #print("here")
            mask = card_tools.get_possible_hand_indexes(child_node.board)
            mask = [True if i ==1 else False for i in mask]
            #print (mask)
            node.strategy[i].fill(0)
            node.strategy[i,mask] = 1.0/(card_settings.card_count-2)

    def fill_uniformly(self,node):
        assert (node.current_player == constants.players.P1 or \
                node.current_player == constants.players.P2)
        if node.terminal :
            return
        else:
            node.strategy = np.zeros([len(node.children),card_settings.card_count])
            node.strategy.fill(1.0/len(node.children))

    def fill_uniform_dfs(self,node):
        if node.current_player == constants.players.chance:
            self.fill_chance(node)
        else:
            self.fill_uniformly(node)
        for i in range(len(node.children)):
            self.fill_uniform_dfs(node.children[i])

    def fill_uniform(self,tree):
        self.fill_uniform_dfs(tree)


#params= Node(2,[200,200],constants.players.chance,1)
#sf = StrategyFilling()
#sf.fill_uniform(params)
