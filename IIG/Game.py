from abc import ABCMeta, abstractmethod
from copy import deepcopy

#import gameSettings

class GameState(object):
    __metaclass__ = ABCMeta

    def __init__(self, name):
        self.name = name
        self.state = 0

    # return self.current_player which indicates who need to make a move
    @abstractmethod
    def get_current_player(self):
        raise NotImplementedError()
    #
    # @abstractmethod
    # def get_board(self):
    #     raise NotImplementedError
    #
    # @abstractmethod
    # def get_turn_number(self):
    #     raise NotImplementedError()
    #
    # @abstractmethod
    # def get_move_list(self):
    #     raise NotImplementedError()
    #
    # # return a list of moves which can be made in the current state
    # @abstractmethod
    # def get_legal_moves(self):
    #     raise NotImplementedError()
    #
    # # make a move on the internal state: update self.state and current_player
    # @abstractmethod
    # def make_move(self, move):
    #     raise NotImplementedError()
    #
    #




class GameTree(object):
    __metaclass__ = ABCMeta

    # Every game needs a name, a set of rules and a set of information sets, starts at root:
    def __init__(self,name, rules):
        self.rules = deepcopy(rules)
        self.information_sets = {}
        self.root = None


    # Assimilate the rules of the current game, update information sets
    @abstractmethod
    def build(self,rules):
        raise NotImplementedError()

# Rules of the game
class Rules(object):


    def __init__(self,settings):
        # Only the name and the number of players:
        self.name = settings.name
        self.players_count = settings.players_count

class Node(object):

    def __init__(self, parent, committed, holecards, board, deck, bet_history):
        self.committed = deepcopy(committed)
        self.holecards = deepcopy(holecards)
        self.board = deepcopy(board)
        self.deck = deepcopy(deck)
        self.bet_history = deepcopy(bet_history)
        if parent:
            self.parent = parent
            self.parent.add_child(self)

    def add_child(self, child):
        if self.children is None:
            self.children = [child]
        else:
            self.children.append(child)




# class RoundInfo(object):
#     __metaclass__ = ABCMeta
#
#     def __init__(self, name):
#         self.name = name
