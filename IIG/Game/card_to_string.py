from Settings import card_settings
import numpy as np

suit_table = ['h', 's', 'c', 'd']

# All possible card ranks
# Only 3 are used for Leduc Poker
rank_table = ['A', 'K', 'Q', 'J',
              'T', '9', '8', '7',
              '6', '5', '4', '3', '2']



# Gets the suit of a card.
def card_to_suit(card):
    return int(card % card_settings.suit_count)

# Gets the rank of a card.
def card_to_rank(card):
    return int(np.floor((card -1) / card_settings.suit_count))

# Holds the dictionary : card, string value
card_to_string_table ={}

for card in range(1, card_settings.card_count+1):
    rank_name = rank_table[card_to_rank(card)]
    suit_name = suit_table[card_to_suit(card)]
    card_to_string_table[card] = rank_name+suit_name

# Holds the dictionary: string, card
string_to_card_table = {}
for card in range(1,card_settings.card_count+1):
    string_to_card_table[card_to_string_table[card]]=card


# Converts a card's numeric representation to its string representation.
def card_to_string(card):
    assert (card>0 and card<= card_settings.card_count),\
        "Card too big or too small for this game"
    return card_to_string_table[card]

# Converts several cards' numeric representations to their string
# representations.
def cards_to_string(cards):
    if len(cards)==0:
        return ""
    else:
        string_rep=[]
        for card in cards:
            string_rep.append(card_to_string_table[card])
    return string_rep







