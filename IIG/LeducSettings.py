# Globals:

# Name
name = "Leduc"

# the number of players in the game
players_count = 2

# the number of betting rounds in the game
streets_count = 2

# Players:
players = {}
players["chance"] = 0
players["P1"] = 1
players["P2"] = 2


# Actions:
# NUM_ACTIONS = 3
#
# # Card Dictionaries:
# CARD_TO_STRING = {1: "J", 2: "Q", 3: "K"}
# STRING_TO_CARD = {"J": 1, "Q": 2, "K": 3}
#
# # Action Dictionaries
# ACTION_TO_STRING = {0: "p", 1: "b"}
# STRING_TO_ACTION = {"p":0, "b":1}
#
# # Various constants used in DeepStack.
# # @module constants
#
#
#
#
#
#
# # IDs for each player and chance
# # @field chance `0`
# # @field P1 `1`
# # @field P2 `2`

#
# # IDs for terminal nodes (either after a fold or call action) and nodes that follow a check action
# # @field terminal_fold (terminal node following fold) `-2`
# # @field terminal_call (terminal node following call) `-1`
# # @field chance_node (node for the chance player) `0`
# # @field check (node following check) `-1`
# # @field inner_node (any other node) `2`
# node_types = {}
# node_types.terminal_fold = -2
# node_types.terminal_call = -1
# node_types.check = -1
# node_types.chance_node = 0
# node_types.inner_node = 1
#
# # IDs for fold and check/call actions
# # @field fold `-2`
# # @field ccall (check/call) `-1`
# actions = {}
# actions.fold = -2
# actions.call = -1
#
# # String representations for actions in the ACPC protocol
# # @field fold "`fold`"
# # @field ccall (check/call) "`ccall`"
# # @field raise "`raise`"
# acpc_actions = {}
# acpc_actions.fold = "fold"
# acpc_actions.ccall = "ccall"
# acpc_actions.raise = "raise"
#
# return constants
