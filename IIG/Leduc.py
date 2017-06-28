from Game import GameTree
from Game import GameState
from Game import Rules
import LeducSettings

# Importing the settings for Leduc Poker
settings = LeducSettings

class LeducState(GameState):
    def __init__(self,name,rules):
        super().__init__(name)


    def get_current_player(self):
        return


class LeducGame(GameTree):
    def __init__(self,name,rules):
        # Rules of the game
        self.name = settings.name
        self.rules = rules





class LeducRules(Rules):

    def __init__(self,settings):
        super().__init__(settings)


        assert (players == settings.players_count), "Too many players, max supported : 2"
        assert (deck != None), "No deck, insert deck"
        assert (rounds != None), "no rounds, insert Rounds"


        self.deck = settings.deck
        self.roundinfo = rounds


class RoundInfo(object):
    def __init__(self, holecards, boardcards, betsize, maxbets):
        self.holecards = holecards
        self.boardcards = boardcards
        self.betsize = betsize
        self.maxbets = maxbets


kp1=LeducRules(settings)




