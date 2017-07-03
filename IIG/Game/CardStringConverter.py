from Settings import card_settings
import numpy as np


class CardStringConverter(object):
    def __init__(self):
        self.suit_table = ['h', 's', 'c', 'd']
        # All possible card ranks
        # Only 3 are used for Leduc Poker
        self.rank_table = ['A', 'K', 'Q', 'J',\
                           'T', '9', '8', '7',\
                           '6', '5', '4', '3', '2']
        self.suit_count = card_settings.suit_count
        self.card_count = card_settings.card_count

        self.card_to_string_table = self.get_card_to_string_dictionary()
        self.string_to_card_table = self.get_string_to_card_dictionary()

        # Importing attributes from Settings.Card_settings:


    # Gets the suit of a card.
    def card_to_suit(self,card):
        return int(card % self.suit_count)

    # Gets the rank of a card.
    def card_to_rank(self,card):
        return int(np.floor((card -1) / self.suit_count))

    # Holds the dictionary : card, string value

    def get_card_to_string_dictionary(self):
        card_to_string_table = {}
        for card in range(1, self.card_count+1):
            rank_name = self.rank_table[self.card_to_rank(card)]
            suit_name = self.suit_table[self.card_to_suit(card)]
            card_to_string_table[card] = rank_name+suit_name
        return card_to_string_table

    # Holds the dictionary: string, car
    def get_string_to_card_dictionary(self):
        string_to_card_table = {}
        for card in range(1,self.card_count+1):
            string_to_card_table[self.card_to_string_table[card]]=card
        return string_to_card_table


    # Converts a card's numeric representation to its string representation.
    def card_to_string(self,card):
        assert (card>0 and card<= self.card_count),\
            "Card too big or too small for this game"
        return self.card_to_string_table[card]

    # Converts several cards' numeric representations to their string
    # representations.
    def cards_to_string(self,cards):
        if len(cards)==0:
            return ""
        else:
            string_rep=[]
            for card in cards:
                string_rep.append(self.card_to_string_table[card])
            return string_rep

    # Converts a card's string representation to its numeric representation.
    def string_to_card(self,card_string):
        card = self.string_to_card_table[card_string]
        assert (card > 0 and card <= self.card_count), \
            "Card too big or too small for this game"
        return card


    # Converts a string representing zero or one board cards to a
    # vector of numeric representations.
    # !!!!! ----------> using numpy?
    # Tensor
    def string_to_board(self,card_string):
        assert (card_string), "add card string"
        if card_string == "":
            return np.array([])
        else:
            return np.array([self.string_to_card(card_string)])




card_to_string = CardStringConverter()
card_to_string.get_card_to_string_dictionary()