import numpy as np
from anytree import Node,NodeMixin, RenderTree
from anytree.dotexport import RenderTreeGraph



class Node(object):
    def __init__(self,name="Chance",actions=["Pass","Bet"],probabilities=[0.5,0.5]):
        self.name=name
        self.actions = actions
        self.probabilities = probabilities
        self.num_actions=len(actions)
        self.strategy = self.set_dictionary()

    def set_dictionary(self):
        dictio={}
        for i,j in zip(self.actions,self.probabilities):
            dictio[i]=j
        return dictio

    def __repr__(self):
        return "Node: %s has %s actions" % (self.name, self.num_actions)


class GameTree(Node,NodeMixin):  # Add Node feature

    def __init__(self,name="Chance",actions=["Pass","Bet"],probabilities=[0.5,0.5] ,parent=None):
        super(GameTree, self).__init__(name=name,actions=actions,probabilities=probabilities)
        self.name = name
        self.parent = parent

    def __str__(self):
        return self.name

    def __repr__(self):
        return str(self.name)

hands = ["JQ","JK","QJ","QK","KJ","KQ"]
hands_probas = [1./6,1./6,1./6,1./6,1./6,1./6]
chance = GameTree('chance', hands, hands_probas)

for i in hands:
    i = GameTree(i,parent=chance)
    print (i)








