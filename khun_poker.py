"""
This module is a simulation of khun poker that learns using CFR
"""

__version__ = '0.1'
__author__ = 'Marcelo Gutierrez'
import numpy as np
import itertools
import sys
import treelib



# Globals:
NUM_PLAYERS=2
GAME="Khun"
CARD_DICTIONARY={"J":1,"Q":2,"K":3}
ACTIONS_DICTIONARY={"PASS":0,"BET":1}


class DecisionTree(object):
    def __init__(self):
        self.depth=2











class Deck(object):
    # Here the cards are initilialized as a dictionary (card,value/index)
    def __init__(self,type_poker=GAME):
        if type_poker==GAME:
            self.cards=CARD_DICTIONARY
            self.states=[]

    def shuffle(self,number_players=NUM_PLAYERS):
        for i in itertools.permutations(self.cards,NUM_PLAYERS):
            self.states.append(i)


class Player(object):

    def __init__(self,name):
        self.name=name
        self.hand=0
        self.strategy=0
        self.card_values=CARD_DICTIONARY
        self.actions=ACTIONS_DICTIONARY
        self.strategy=0
        self.infoSet=[]

    def get_cards(self,cards):
        self.hand=cards

    def play(self):
        




    def __str__(self):
        return "player: {}, card: {}".format(self.name, self.hand)



class KhunGame(object):
    def __init__(self):
        self.num_players=NUM_PLAYERS
        self.player1= 0
        self.player2= 0
        self.all_players = 0
        self.cards=Deck()
        self.history=0

    def createPlayers(self):
        self.player1 = Player("1")
        self.player2 = Player("2")
        self.all_players = [self.player1, self.player2]

    def deal(self):
        self.cards.shuffle()
        random_hand = np.random.randint(0,len(self.cards.states))
        new_hand = self.cards.states[random_hand]
        for player,card in zip(self.all_players,new_hand):
            player.get_cards(card)

    def cfr(self, ):









kp=KhunGame()
kp.createPlayers()
kp.deal()
print(kp.player1)
