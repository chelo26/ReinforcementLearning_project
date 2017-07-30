import numpy as np
from collections import OrderedDict


class Node(object):
    def __init__(self):
        self.infoSet = ""
        self.regretSum = [0] * NUM_ACTIONS
        self.strategy = [0] * NUM_ACTIONS
        self.strategySum = [0] * NUM_ACTIONS

    def getStrategy(self, realizationWeight):
        #print("realization weights: ", str(realizationWeight))
        normalizingSum = 0
        #print("strategy before: ", str(self.strategy))
        for a in range(NUM_ACTIONS):
            self.strategy[a] = max(self.regretSum[a], 0)
            normalizingSum += self.strategy[a]

        for a in range(NUM_ACTIONS):
            if normalizingSum > 0:
                self.strategy[a] /= normalizingSum
            else:
                self.strategy[a] = 1.0 / NUM_ACTIONS
            self.strategySum[a] += realizationWeight * self.strategy[a]
        #print("strategy after: ", str(self.strategy))
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




