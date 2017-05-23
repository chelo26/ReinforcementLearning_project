import numpy as np
import sys

# Global Variables

class Game(object):
    def __init__(self):
        self.player=1
        self.computer=2
        self.nul=0

        self.action=0
        self.winner=0

        self.u_loss = -1
        self.u_win = 1
        self.u_tie=0

        self.uMatrix=np.array([[[0,0],[-1,0],[1,0]],[[1,0],[0,0],[-1,1]],[[-1,0],[1,0],[0,0]]])


        self.ROCK = 0
        self.PAPER =1
        self.SCISSORS=2
        self.NUM_ACTIONS=3

        # regret = [R,P,S]
        self.regret=np.array([0,0,0])

    def play(self):
        self.action= int(input("R = 0 , P = 1, S = 2?: "))
        self.c_response = int(np.random.randint(0,2))
        print("you play : ", self.action)
        print ("computer: ",self.c_response)
        print ("winner: ", self.get_results())
        self.updateRegret()
        print ("regret: ", self.regret)


    def updateRegret(self):
        current_u = np.sum(self.uMatrix[self.action, self.c_response])
        for i in range(self.NUM_ACTIONS):
            self.regret[i]+= self.uMatrix[self.action,i]-current_u





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

    def get_regret(self):
        regret=[]
        for i in range(self.NUM_ACTIONS):
            regret.append()




class RPSTrainer(object):
    def __init__(self):
        # naming
        self.ROCK = 0
        self.PAPER =1
        self.SCISSORs=2
        # number of actions
        self.NUM_ACTIONS=3
        # Initialize
        self.regretSum=np.zeros(3)
        self.strategy=np.zeros(3)
        self.strategySum=np.zeros(3)

    def getStrategy(self, regret):
        sum_regret= np.sum(regret)
        if sum_regret>0:
            return regret / sum_regret
        else:
            return np.array([1/np.size(regret) for i in range(np.size(regret))])

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





game1=Game()
game1.play()

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




