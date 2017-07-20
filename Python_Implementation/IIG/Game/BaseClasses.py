class Players(object):
    def __init__(self,chance,p1,p2):
        self.chance=chance
        self.P1 = p1
        self.P2 = p2


class NodeTypes(object):
    def __init__(self,terminal_fold,terminal_call,check,chance_node,inner_node):
        self.terminal_fold =terminal_fold
        self.terminal_call = terminal_call
        self.check = check
        self.chance_node = chance_node
        self.inner_node = inner_node

class Actions(object):
    def __init__(self,fold,call):
        self.fold = fold
        self.call = call

