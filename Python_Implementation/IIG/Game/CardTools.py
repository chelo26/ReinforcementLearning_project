import numpy as np
from Settings import card_settings
from copy import deepcopy

# Gives whether a set of cards is valid.
# Returns "true" if the tensor contains valid cards and no card is repeated

class CardTools(object):
    def __init__(self):
        self.EMPTY_BOARD = ""
        
        # Importing attributes from Settings.self.
        self.suit_count = card_settings.suit_count
        self.card_count = card_settings.card_count
        self.board_card_count = card_settings.board_card_count
        self._board_index_table = self.init_board_index_table()

    def hand_is_possible(self,hand):
        assert (min(hand)>0 and max(hand)<=self.card_count),\
        "Illegal card in hand"
        # Change when using theano:
        used_cards = [0]*self.card_count
        for i in range(len(hand)):
            #print (i,hand[i])
            # Had to take one of in order to keep the indexes ok
            used_cards[hand[i]-1] += 1
        #print (used_cards)
        return max(used_cards)<2
    
    # Get an array with a 1 if the card is not on the board and 0 if it is
    def get_possible_hand_indexes(self,board):
        out = [0] * self.card_count
        # check if is  []
        if board == self.EMPTY_BOARD:
            # Tensor
            return np.array([1 for i in out])
        else:
            whole_hand = [board, None]
            for other_card in range(self.card_count):
                whole_hand[-1] = other_card+1
                #print(whole_hand)
                if self.hand_is_possible(whole_hand):
                    out[other_card]=1
            # Tensor
            return np.array(out)
    
    
    # Gives the private hands which are invalid with a given board.
    def get_impossible_hand_indexes(self,board):
        out = self.get_possible_hand_indexes(board)
        out = (out-1)*(-1)
        return out
    
    
    # Gives a range vector that has uniform probability on each hand which is
    # valid with a given board.
    def get_uniform_range(self,board):
        out = self.get_possible_hand_indexes(board)
        total = sum(out)
        return out/total
    
    # Generates a random range vector that is valid with a given board:
    def get_random_range(self,board,seed):
        np.random.seed(seed)
        # sample from uniform:
        # Tensors
        random_range = np.random.random(self.card_count)
        random_range = random_range*self.get_possible_hand_indexes(board)
        return random_range/sum(random_range)
    
    
    # Checks if a range vector is valid with a given board.
    
    def is_valid_range(self, range, board):
        check = deepcopy(range)
        only_possible_hands = sum(deepcopy(range)*self.get_impossible_hand_indexes(board)) == 0
        sums_to_one = np.abs(1.0 - sum(range)) < 0.0001
        return only_possible_hands and sums_to_one
    
    # Gives the current betting round based on a board vector.
    def board_to_street(self,board):
        if len(board) == 0:
            return 1
        else:
            return 2
    
    
    
    # Gives the number of possible boards.
    def get_boards_count(self):
        if self.board_card_count == 1:
            return int(self.card_count)
        elif self.board_card_count == 2:
            return int((self.card_count * (self.card_count - 1)) / 2)
        else:
            assert(false), 'unsupported board size'
    
    
    
    # Gives all possible sets of board cards for the game.
    # returns an NxK array, where N is the number of possible boards, and K is
    # the number of cards on each board
    def get_second_round_boards(self):
        board_counts =self.get_boards_count()
        if self.board_card_count == 1:
            out = np.zeros([board_counts,1])
            for card in range(1,self.card_count+1):
                out[card-1] = card
            return out
        elif self.board_card_count == 2:
            out = np.zeros([board_counts, 2])
            #print (out)
            board_idx = 0
            for card1 in range(1,self.card_count+1):
                for card2 in range(card1 + 1, self.card_count+1):
                    board_idx += 1
                    print (board_idx)
                    out[board_idx-1,0] = card1
                    out[board_idx-1,1] = card2
            assert (board_idx == board_counts), 'wrong boards count!'
            return out
        else:
            assert(false), 'unsupported board size'
    
    
    # Initializes the board index table.
    def init_board_index_table(self):
        if self.board_card_count == 1:
            _board_index_table = np.arange(1,self.card_count+1)
            return _board_index_table
        elif self.board_card_count == 2:
            _board_index_table = np.zeros([self.card_count,\
                                           self.card_count])
    
            _board_index_table.fill(-1)
            board_idx = 0
            #print(_board_index_table)
            for card1 in range(self.card_count):
                for card2 in range(card1+1, self.card_count):
                    board_idx += 1
                    #print (_board_index_table)
                    #print (card1,card2)
                    _board_index_table[card1][card2] = board_idx
                    _board_index_table[card2][card1] = board_idx
            return _board_index_table
        else:
            assert (false), "unsupported board size"

    # Gives a numerical index for a set of board cards.
    
    def get_board_index(self,board):
        index = deepcopy(self.init_board_index_table())
        for i in range(len(board)):
            print (index)
            index = index[i]
        assert (index >0), " not good index "
    
        return index
    
    
    # Normalizes a range vector over hands which are valid with a given board.
    
    def normalize_range(self,board, range):
        mask = get_possible_hand_indexes(board)
        out = deepcopy(range)*mask
        if sum(out)== 0:
            return 0
        else:
            return out/sum(out)
    
    





