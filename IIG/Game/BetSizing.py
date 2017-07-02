from Settings import arguments
import numpy as np
from Tree.TreeTools import Node
from Settings import constants

class BetSizing(object):
    def __init__(self,pot_fractions):
        # Tensor
        self.pot_fractions = pot_fractions

    def get_possible_bets(self, node):
        current_player= node.current_player-1
        assert (current_player == 0 or current_player == 1),\
            'Wrong player for bet size computation'
        # indexing !
        opponent = 2 - node.current_player
        opponent_bet = node.bets[opponent]
        assert (node.bets[current_player] <= opponent_bet),\
            "new bet should be higher than last previous bet "
        max_raise_size = arguments.stack - opponent_bet
        #print ("max: ", max_raise_size)
        min_raise_size = opponent_bet - node.bets[current_player]
        min_raise_size = max(min_raise_size, arguments.ante)
        min_raise_size = min(max_raise_size, min_raise_size)
        if min_raise_size == 0:
            # Tensor
            return np.array([])
        elif min_raise_size == max_raise_size:
            out = np.zeros([1,2])
            out.fill(opponent_bet)
            out[0,current_player] = opponent_bet + min_raise_size
            return out
        else:
            # All in:
            max_possible_bets_count = len(self.pot_fractions)+1
            out = np.zeros([max_possible_bets_count,2])
            out.fill(opponent_bet)

            pot = opponent_bet*2
            #print("pot :",pot)
            used_bets_count = 0
            for pot_fraction in self.pot_fractions:
                raise_size = pot * pot_fraction
                #print( "raise: ",raise_size)
                if raise_size >= min_raise_size and raise_size <max_raise_size:
                    used_bets_count += 1
                    out[used_bets_count-1,current_player-1] = opponent_bet + raise_size



            used_bets_count += 1
            #print("out 1 ", out)
            assert (used_bets_count <= max_possible_bets_count),"bet bigger that max possible bet"
            out[used_bets_count-1,current_player-1] = opponent_bet + max_raise_size
            #print("out 2: ",out)
            return out[:used_bets_count]



# test= BetSizing([1,2])
# params = Node(1,[200,200],constants.players.P2,1)
# test.get_possible_bets(params)