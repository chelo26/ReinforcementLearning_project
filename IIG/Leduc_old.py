from copy import deepcopy
from Game import CardTools
from Game import GameState
from Game import GameTree
from Game import Node
from Game import Rules
from Settings import LeducSettings


# Importing the settings for Leduc Poker
settings = LeducSettings

class LeducState(GameState):
    def __init__(self,name,rules):
        super().__init__(name)


    def get_current_player(self):
        return


class LeducTree(GameTree):
    def __init__(self,settings,rules):
        # Rules of the game
        self.name = settings.name
        self.rules = deepcopy(rules)

    def buildTree(self,params):
        current_player = params.current_player

class LeducRules(Rules):

    def __init__(self,settings):
        super().__init__(settings)
        assert (settings.players_count == 2), "Too many players, max supported : 2"
        assert (settings.deck != None), "No deck, insert deck"
        assert (settings.rounds != None), "no rounds, insert Rounds"
        self.deck = settings.deck
        self.roundinfo = settings.rounds




class TerminalNode(Node):
    def __init__(self, parent, committed, holecards, board, deck, bet_history, payoffs, players_in):
        Node.__init__(self, parent, committed, holecards, board, deck, bet_history)
        self.payoffs = payoffs
        self.players_in = deepcopy(players_in)

class HolecardChanceNode(Node):
    def __init__(self, parent, committed, holecards, board, deck, bet_history, todeal):
        Node.__init__(self, parent, committed, holecards, board, deck, bet_history)
        self.todeal = todeal
        self.children = []

class BoardcardChanceNode(Node):
    def __init__(self, parent, committed, holecards, board, deck, bet_history, todeal):
        Node.__init__(self, parent, committed, holecards, board, deck, bet_history)
        self.todeal = todeal
        self.children = []

class ActionNode(Node):
    def __init__(self, parent, committed, holecards, board, deck, bet_history, player, infoset_format):
        Node.__init__(self, parent, committed, holecards, board, deck, bet_history)
        self.player = player
        self.children = []
        self.raise_action = None
        self.call_action = None
        self.fold_action = None
        self.player_view = infoset_format(player, holecards[player], board, bet_history)

    def valid(self, action):
        if action == FOLD:
            return self.fold_action
        if action == CALL:
            return self.call_action
        if action == RAISE:
            return self.raise_action
        raise Exception("Unknown action {0}. Action must be FOLD, CALL, or RAISE".format(action))

    def get_child(self, action):
        return self.valid(action)



leduc_rules = LeducRules(settings)

lgt = LeducTree(settings,leduc_rules)


