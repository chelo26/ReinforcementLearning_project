require 'nn'

local StrategyNN = torch.class('StrategyNN')

function StrategyNN:__init()
  self.model = self:create_model()
end

function StrategyNN:create_model()
  -----WORKING SEQUENCE
  layer1 = nn.ParallelTable()
  layer1:add(nn.Linear(30, 64):init('weight', nninit.xavier))
  layer1:add(nn.Identity)

  layer2 = nn.ParallelTable()
  layer2:add(nn.PReLU())
  layer2:add(nn.Identity)

  layer21 = nn.ParallelTable()
  layer21:add(nn.Linear(64,50):init('weight', nninit.xavier))
  layer21:add(nn.Identity)

  layer22 = nn.ParallelTable()
  layer22:add(nn.PReLU())
  layer22:add(nn.Identity)


  layer23 = nn.ParallelTable()
  layer23:add(nn.Linear(50,4):init('weight', nninit.xavier))
  layer23:add(nn.Identity)



  layer3 = nn.ParallelTable()
  layer3:add(nn.Reshape(4,1))
  layer3:add(nn.Reshape(4,1))

  layer4 = nn.CSubTable()
  layer5 = nn.Reshape(4)
  layer6 = nn.SoftMax()

  mlp = nn.Sequential()
  mlp:add(layer1)
  mlp:add(layer2)
  mlp:add(layer21)
  mlp:add(layer22)
  mlp:add(layer23)
  mlp:add(layer3)
  mlp:add(layer4)
  mlp:add(layer5)
  mlp:add(layer6)
  return mlp
end
