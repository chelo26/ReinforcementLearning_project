import numpy as np
import sys

# Global Variables

class AIPlayer(object):
    def __init__(self):
        self.action = np.random.randint(0, 2)
        self.dict_actions={"R":0,"P":1,"S":2}
        





class Game(object):
    def __init__(self):
        self.player=1
        self.computer=2
        self.nul=0

        self.action=np.random.randint(0,2)
        self.winner=0

        self.u_loss = -1
        self.u_win = 1
        self.u_tie=0

        self.uMatrix=np.array([[[0,0],[-1,1],[1,-1]],[[1,-1],[0,0],[-1,1]],[[-1,1],[1,-1],[0,0]]])


        self.ROCK = 0
        self.PAPER =1
        self.SCISSORS=2
        self.NUM_ACTIONS=3

        # regret = [R,P,S]
        self.regret=np.array([0,0,0])
        self.strategy=np.array([0,0,0])
        self.strategy_sum=np.array([0.,0.,0.])
        self.c_strategy=np.array([1,0,0])
        self.regretS=0
        self.iterations=100

    def play(self):
        self.action= int(input("R = 0 , P = 1, S = 2?: "))
        self.c_response = int(np.random.randint(0,2))
        print("you play : ", self.action)
        print ("computer: ",self.c_response)
        print ("winner: ", self.get_results())
        self.updateRegret()
        print ("regret: ", self.regret)
        self.updateStrategy()
        print("strategy: ", self.strategy)

    def updateRegret(self):
        current_u = self.uMatrix[self.action, self.c_response][0]
        #current_u = self.uMatrix[self.c_response, self.action][0]
        print("regret beforee: ", self.regret)
        for i in range(self.NUM_ACTIONS):
            self.regret[i]+= self.uMatrix[i,self.c_response][0]-current_u
        print("regret after: ", self.regret)

    def updateStrategy(self):
        #self.regret=[max(0,int(i)) for i in self.regret]
        self.regretS = [max(0, int(i)) for i in self.regret]
        sum_regret= np.sum(self.regretS)
        #print("strategy before : ", self.strategy)
        if sum_regret>0:
            self.strategy= self.regretS / sum_regret
        else:
            self.strategy = np.array([1/np.size(self.regretS) for i in range(np.size(self.regretS))])
        #print("strategy after : ", self.strategy)
        self.strategy_sum+=self.strategy

    def train(self):
        for i in range(self.iterations):
            self.c_response = self.getAction(self.c_strategy)
            print ("player c : ",self.c_response)
            print("player 2 : ",self.action)
            self.updateRegret()
            #print ("regret: ", self.regret)
            self.updateStrategy()
            #print("strategy: ", self.strategy)
            self.action=self.getAction(self.strategy)
        print ("stragey: ",self.strategy)
        print("avg strategy: ", self.getAvgStrategy())


    def getAvgStrategy(self):
        sum_strat = np.sum(self.strategy_sum)
        if sum_strat>0:
            return self.strategy_sum / sum_strat
        else:
            return np.array([1/np.size(self.strategy_sum) for i in range(np.size(self.strategy_sum))])


    def get_results(self):
        if self.action == self.ROCK:
            if self.c_response == self.PAPER:

                return self.computer
            elif self.c_response == self.ROCK:
                return self.nul
            elif self.c_response == self.SCISSORS:
                self.self.u_tie
                return self.player

        if self.action == self.PAPER:
            if self.c_response == self.PAPER:
                return self.nul
            elif self.c_response == self.ROCK:
                return self.player
            elif self.c_response == self.SCISSORS:
                return self.computer

        if self.action == self.SCISSORS:
            if self.c_response == self.SCISSORS:
                return self.nul
            elif self.c_response == self.PAPER:
                return self.player
            elif self.c_response == self.ROCK:
                return self.computer

    def getAction(self, strategy):
        r=np.random.rand()
        a=0
        cumProb=0
        while(a<self.NUM_ACTIONS-1):
            cumProb+=strategy[a]
            if r<cumProb:
                break
            a+=1
        return a



np.set_printoptions(suppress=True)
game1=Game()
game1.train()

a=[]
for i in range(10000):
    a.append(game1.getAction(game1.strategy))




# Main:
#
# oppStrategy=np.array([0.4,0.3,0.3])
#
# regret=np.array([0,1,2])
#
# # Getting the strat:
# strat=getStrategy(regret)
# print ("strat = ", strat)
#
#
# # Getting action:
# myAction=getAction(strat)
# print ("action = ", myAction)




