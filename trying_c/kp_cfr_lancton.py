import numpy as np
from collections import OrderedDict


PASS=0
BET=1
NUM_ACTIONS=2
nodeMap=OrderedDict()


class Node(object):
    def __init__(self):
        self.infoSet = ""
        self.regretSum = [0] * NUM_ACTIONS
        self.strategy = [0] * NUM_ACTIONS
        self.strategySum = [0] * NUM_ACTIONS

    def getStrategy(self, realizationWeight):
        print("realization weights: ", str(realizationWeight))
        normalizingSum = 0
        print("strategy before: ", str(self.strategy))
        for a in range(NUM_ACTIONS):
            self.strategy[a] = max(self.regretSum[a], 0)
            normalizingSum += self.strategy[a]

        for a in range(NUM_ACTIONS):
            if normalizingSum > 0:
                self.strategy[a] /= normalizingSum
            else:
                self.strategy[a] = 1.0 / NUM_ACTIONS
            self.strategySum[a] += realizationWeight * self.strategy[a]
        print("strategy after: ", str(self.strategy))
        return self.strategy

    def getAvgStrategy(self):
        normalizingSum = np.sum(self.strategySum)
        avgStrategy = [0] * NUM_ACTIONS
        for a in range(NUM_ACTIONS):
            if normalizingSum > 0:
                avgStrategy[a] = self.strategySum[a] / normalizingSum
            else:
                avgStrategy[a] = 1.0 / NUM_ACTIONS
        return avgStrategy

    def __str__(self):

        return self.infoSet+" : "+str(self.getAvgStrategy())


class KhunTrainer(object):

    def shuffle(self):
        cards = [1, 2, 3]
        for c1 in range(len(cards)-1,0,-1):
            c2 = np.random.randint(c1+1)
            tmp=cards[c1]
            cards[c1]=cards[c2]
            cards[c2]=tmp
        return cards

    def train(self,iterations):
        util=0

        for i in range(iterations):
            cards = self.shuffle()
            print (cards)
            util+=self.cfr(cards,"",1,1)
            print ("util: "+str(util))
        print ("Average game value: ", util / iterations)

        sortedNodeMap = OrderedDict(sorted(nodeMap.items(), key=lambda x: x[0]))
        for n in sortedNodeMap.values():
            print (str(n))


    def cfr(self,cards,history,p0,p1):
        print ("starting history: " + str(history)+" p0: " + str(p0) + " p1 :"+ str(p1))
        plays = len(history)
        player = plays % 2
        print("player : ",player)
        opponent = 1 - player

        if plays>1:
            terminalPass = history[plays-1]=='p'
            #print(plays)
            #print (history)
            doubleBet = history[plays - 2: plays] == "bb";
            print ("cards: ",cards)
            isPlayerCardHigher=cards[player]>cards[opponent]
            if terminalPass:
                if history=="pp":
                    return 1 if isPlayerCardHigher else -1
                else:
                    return 1
            elif doubleBet:
                return 2 if isPlayerCardHigher else -2

        infoSet=str(cards[player])+history
        print ("infoSet: "+ infoSet)
        if infoSet in nodeMap.keys():
            node = nodeMap[infoSet]
        else:
            node = Node()
            node.infoSet=infoSet
            nodeMap[infoSet]=node


        #print (node.getStrategy(2))
        #print(node.strategy)
        strategy = node.getStrategy(p0 if player==0 else p1)
        print ("strategy generated: "+str(strategy))
        util = [0]*NUM_ACTIONS
        nodeUtil = 0
        for a in range(NUM_ACTIONS):
            nextHistory = history + ("p" if a==0 else "b")
            print("NEXT history: " + str(nextHistory))
            if player==0:
                print("enter player 0: ", cards)
                util[a]= - self.cfr(cards, nextHistory, p0 * strategy[a], p1)
                print("util 0 : ", util[a])
            else:
                print("enter player 1: ", p1 * strategy[a])
                util[a]= - self.cfr(cards, nextHistory, p0, p1 * strategy[a])
                print("util 1 : ", util[a])
            nodeUtil += strategy[a] * util[a]
            print ("nodeUtil : ",nodeUtil )

        for a in range(NUM_ACTIONS):
            regret = util[a] - nodeUtil
            print ("regret: ",regret)
            node.regretSum[a] += (p1 if player == 0 else p0)*regret

        return nodeUtil

iterations=1
kp=KhunTrainer()
kp.train(iterations)





