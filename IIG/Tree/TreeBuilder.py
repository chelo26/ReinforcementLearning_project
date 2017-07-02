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
from copy import deepcopy

card_tools = CardTools()
card_to_string = CardStringConverter


class PokerTreeBuilder(object):
    def __init__(self):
        self.bet_sizing = None


    def get_children_nodes_transition_call(self,parent_node):
        chance_node = Node(parent_node.street,deepcopy(parent_node.bets),\
                           constants.players.chance, parent_node.board)
        chance_node.set_board_string(parent_node.board_string)
        chance_node.set_node_type(constants.node_types.chance_node)
        return chance_node

    def get_children_nodes_chance_node(self,parent_node):
        assert (parent_node.current_player == constants.players.chance), "player is not chance"

        if self.limit_to_street:
            return {}
        next_boards = card_tools.get_second_round_boards()
        next_boards_count = next_boards.shape[0]

        subtree_height = -1
        children = []

        for i in range(next_boards_count):
            next_board = next_boards[i]
            next_board_string = card_tools.card_to_string(next_board)
            # Creating children:
            child = Node(parent_node.street,deepcopy(parent_node.bets),\
                         constants.players.chance, parent_node.board)
            child.set_node_type(constants.node_types.inner_node)
            child.set_parent(parent_node)
            child.set_board_string(parent_node.board_string)
            children.append(child)
        return children


    def get_children_player_node(self,parent_node):
        assert (parent_node.current_player != constants.players.chance),\
                "parent node is a chance node"
        children = []

        # Fold Action:
        fold_node =  Node(parent_node.street,deepcopy(parent_node.bets),\
                         constants.players.chance, parent_node.board)
        fold_node.set_node_type(constants.node_types.terminal_fold)
        fold_node.convert_to_terminal_node()
        fold_node.current_player = 3 - parent_node.current_player
        fold_node.set_board_string(parent_node.board_string)
        children.append(fold_node)

        # Check Action:
        # If the current player is player 1 and the bets are equal:
        if (parent_node.current_player == constants.players.P1 and \
                parent_node.bets[0] == parent_node.bets[1]):
            check_node = Node(parent_node.street,deepcopy(parent_node.bets),\
                              3-parent_node.current_player,parent_node.board)
            check_node.set_node_type(constants.node_types.check)
            check_node.set_board_string(deepcopy(parent_node.bets))
            children.append(check_node)

        # Transition Call
        # if the current player is player 2 and, the bets are equal and
        # the bets are equal or the bets are different and the maximla bet is
        # smaller that the stack:
        elif parent_node.street == 1 and\
            ((parent_node.current_player == constants.players.P2 and \
            parent_node.bets[0] == parent_node.bets[1]) or \
            (parent_node.bets[0] != parent_node.bets[1] and \
                max(parent_node.bets) < arguments.stack)):
            chance_node = Node(parent_node.street,deepcopy(parent_node.bets),\
                               3-parent_node.current_player,parent_node.board)
            chance_node.set_board_string(parent_node.board_string)
            chance_node.set_node_type(constants.node_types.chance_node)
            children.append(chance_node)
        else:
            terminal_call_node = Node(parent_node.street,deepcopy(parent_node.bets),\
                                      3-parent_node.current_player,parent_node.board)
            terminal_call_node.set_node_type(constants.node_types.terminal_call)
            terminal_call_node.set_board_string(parent_node.board_string)
            children.append(terminal_call_node)

        # Possible bet actions:
        possible_bets = self.bet_sizing.get_possible_bets(parent_node)

        if len(possible_bets) != 0:
            assert (possible_bets.shape[1] == 2), "bad size of possible bets"

            for i in range(possible_bets.shape[0]):
                child = Node(parent_node.street,possible_bets[i],\
                             3-parent_node.current_player,parent_node.board)
                child.set_board_string(parent_node.board_string)
                child.set_parent_node(parent_node)
                children.append(child)
        return children






    def get_children_nodes(self,parent_node):
        call_is_transit = parent_node.current_player == constants.players.P2 and\
                          parent_node.bets[0] == parent_node.bets[1] and\
                          parent_node.street < constants.streets_count

        chance_node = parent_node.current_player == constants.players.chance

        if parent_node.terminal:
            return []
        elif chance_node:
            return self.get_children_nodes_chance_node(parent_node)
        else:
            return self.get_children_player_node(parent_node)

        assert(False), "Problems"






    def build_tree_dfs(self,current_node):
        # add bets:
        current_node.fill_additional_attributes(current_node)

        # getting children and adding them:
        children = self.get_children_nodes(current_node)
        current_node.set_children(children)

        depth = 0

        current_node.actions = [0]*len(children)
        for i in range(len(children)):
            children[i].parent = current_node
            self.build_tree(children[i])
            depth = max(depth, children[i].depth)
            if i ==0:
                current_node.actions[i] = constants.actions.fold
            elif i == 1:
                current_node.actions[i] = constants.actions.call
            else:
                current_node.actions[i] = max(children[i].bets)
        current_node.depth = depth +1
        return current_node


    def build_tree(self,params):
        # initialize root
        root = Node(params.street,params.bets,\
                    params.current_player,params.board)

        #print ("params ",params.bet_sizing)

        if not hasattr(params,'bet_sizing'):
            self.bet_sizing = BetSizing(arguments.bet_sizing)
        #params.set_bet_sizing(BetSizing(arguments.bet_sizing))

        print (self.bet_sizing)
        assert (self.bet_sizing), "no bet sizing"
        #self.bet_sizing = params.bet_sizing
        self.limit_to_street = params.limit_to_street

        # recursively build the tree
        self.build_tree_dfs(root)

        #strategy_filling = StrategyFilling()
        #strategy_filling.fill_uniform(root)
        return root

# Passing parameters:
params= Params(1,[200,200],constants.players.P1,1,True)
print("bet: ",params.bet_sizing is None)

#p1 = PokerTreeBuilder()

#root = p1.build_tree(params)

