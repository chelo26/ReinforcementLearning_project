from Settings import constants
from collections import defaultdict
#from Game.BetSizing import BetSizing
from Settings import arguments


class Node(object):
    def __init__(self, street, bets,current_player,board):
        # Rounds:
        self.street = street
        # Bets:
        self.bets = bets
        # Current player:
        self.current_player = current_player
        # Board state
        self.board = board
        # Children:
        self.children = None
        self.pot = None
        self.terminal = False
        self.node_type = None
        self.parent_node = None
        self.board_string = None
        self.children = None
        self.actions = []
        self.depth = 0
        self.strategy = []

    def fill_additional_attributes(self,node):
        self.pot = min(node.bets)

    def convert_to_terminal_node(self):
        self.terminal = True

    def set_node_type(self,node_type):
        self.node_type = node_type

    def set_parent_node(self,parent_node):
        self.parent_node = parent_node

    def set_board_string(self,board_string):
        self.board_string = board_string

    def set_children(self,children):
        self.children = children







#params = Node(1,[200,200],constants.players.P2,1)

class Params(Node):
    def __init__(self,street, bets,current_player,board,\
                 limit_to_street,bet_sizing = 0):
        super().__init__(street, bets,current_player,board)
        self.limit_to_street = limit_to_street
        self.bet_sizing = bet_sizing

    def set_bet_sizing(self,new_bet_sizing):
        if self.bet_sizing is None:
            self.bet_sizing = new_bet_sizing

node = Node(1,[200,200],constants.players.P2,1)
params= Params(1,[200,200],constants.players.P2,1,1)
