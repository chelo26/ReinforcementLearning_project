require 'nn'
require 'math'
require 'optim'
nninit = require 'nninit'


local NeuralNetTrainer = torch.class('NNTrainer')

function NeuralNetTrainer:__init(game,model)---,criterion,opt)
  self.game = game
  self.features = self:get_features(game)
  self.masks = self:get_masks(game)
  self.targets = self:get_targets(game)
  self.all_data = self:build_data_object(self.features,self.masks,self.targets)
  self.train_data,self.test_data = self:generate_training_and_validation_sets()
  self.mlp = model.model
  self.model = model
  ---self.model = model
  ---self.criterion = criterion
  ---self.opt = opt
end

--- Function that initialize a new model
function NeuralNetTrainer:set_new_model()
  local new_model = StrategyNN()
  return new_model:create_model()
end

--- Function that gets the features from the game_tree_data
function NeuralNetTrainer:get_features(game)
  local input_tensor = self.game.input_tensor:clone()
  return input_tensor[{{},{1,30}}]
end

--- Function that gets the masks from the game_tree_data
function NeuralNetTrainer:get_masks(game)
  local input_tensor = self.game.input_tensor:clone()
  local legal_actions = input_tensor[{{},{31,34}}]
  local masks = self:convert_to_masks(legal_actions)
  return masks
end

--- Function that gets the targets from the game_tree_data
function NeuralNetTrainer:get_targets(game)
  local output_tensor = self.game.output_tensor:clone()
  return output_tensor
end

--- Function to get masks
function NeuralNetTrainer:convert_to_masks(actions_tensor)
    local masks_tensor = torch.Tensor(actions_tensor:size()):fill(0)
    for i =1, actions_tensor:size(1) do
        masks_tensor[{{i},{}}] = self:find_mask(actions_tensor[{{i},{}}])
    end
    return masks_tensor
end

--- Finds the mask:
function NeuralNetTrainer:find_mask(action)
    local mask = action:clone()
    for i= 1,action:size(2) do
        if mask[1][i] < 1 then
            mask[1][i] = math.huge
        else
            mask[1][i] = 0
        end
    end
    return mask
end

--- Creating the features, masks, targets structure
function NeuralNetTrainer:build_data_object(features,masks,targets)
  local data = {}
  data.features = features
  data.masks = masks
  data.targets = targets
  return data
end

--- Split the data into training and testing data:
function NeuralNetTrainer:split_data(dataset,percentage_train)
    local indexes = torch.randperm(dataset:size(1))
    local dataset_new_index = torch.Tensor(dataset:size()):fill(0)
    for i =1,indexes:size(1) do
        dataset_new_index[{{i},{}}]  = dataset[{{indexes[i]},{}}]
    end

    local percentage_train = percentage_train or 0.90
    local num_train = math.floor(dataset_new_index:size(1)*percentage_train)
    local data_train = dataset_new_index[{{1,num_train},{}}]:clone()
    local data_test = dataset_new_index[{{num_train+1,-1},{}}]:clone()
    return data_train,data_test
end

--- creates the training/ testing structure
function NeuralNetTrainer:generate_training_and_validation_sets()
    local input_tensor = self.game.input_tensor:clone()
    local output_tensor = self.game.output_tensor:clone()
    local targets = output_tensor

    -- Getting features and masks:
    ---local features = input_tensor[{{},{1,30}}]
    ---local legal_actions = input_tensor[{{},{31,34}}]
    ---local masks = self:convert_to_masks(legal_actions)
    local features,masks = self:convert_input_to_features_and_masks(input_tensor)

        -- Spliting in test and train :
    local features_train, features_test = self:split_data(features)
    local masks_train, masks_test = self:split_data(masks)
    local targets_train, targets_test = self:split_data(targets)

    -- Features and masks
    local train_data = self:build_data_object(features_train,masks_train,targets_train)
    local test_data = self:build_data_object(features_test,masks_test,targets_test)
    ---print(features_train:size())
    ---print(features_test:size())
    ---self.train_data = train_data
    ---self.test_data = test_data
    return train_data,test_data
end

function NeuralNetTrainer:convert_input_to_features_and_masks(input_tensor,max_legal_actions)
  local input_tensor = input_tensor:clone()
  local max_legal_actions = max_legal_actions or 4
  local input_total_size = input_tensor:size(2)
  local actions_size = max_legal_actions
  local features_size = input_total_size - actions_size

  local features = input_tensor[{{},{1,features_size}}]
  local legal_actions = input_tensor[{{},{features_size+1,input_total_size}}]
  local masks = self:convert_to_masks(legal_actions)
  return features,masks
end


--- Training NN
function NeuralNetTrainer:train(model,criterion,opt,epochs)
    --- Defining the parameters and the gradient
    local validate = opt.validate or false

    --- Data
    local data_train = self.all_data
    if validate == true then
      local data_train = self.train_data
    end
    local data_test = self.test_data

    --- Parameters
    local params, gradParameters = model:getParameters()
    --- Loss vectors
    local training_loss_tensor = {}
    local test_loss_tensor = {}
    local epochs = epochs or 5000

    --- Defining the function that gives back the loss and the gradient
    local train_loss = 0
    local test_loss = 0
    feval = function(params)
        --- Features:
        gradParameters:zero()

        -- Forward pass:
        model:forward({data_train.features,data_train.masks})
        local predictions = model.output

        -- Errors:
        local loss = criterion:forward(predictions, data_train.targets)
        --Backprop:
        local gradCriterion = criterion:backward(predictions, data_train.targets)
        model:backward({data_train.features,data_train.masks}, gradCriterion)

        return loss,gradParameters
    end

    -- Perform SGD step:
    sgdState = sgdState or {
    learningRate = opt.learningRate or 0.001,
    momentum = opt.momentum or 0,
    dampening = 0,
    nesterov = opt.nesterov or false,
    learningRateDecay = 5e-7}

    adamState = adamState or {
    learningRate = opt.learningRate or 0.001,
    learningRateDecay = opt.learningRateDecay or 0.9,
    weightDecay = opt.weightDecay or 0.999}

    for i = 1,epochs do
        optim.sgd(feval, params, sgdState)

        -- Training loss:
        train_loss = criterion:forward(model:forward({data_train.features,data_train.masks}), data_train.targets)
        table.insert(training_loss_tensor,train_loss)

        -- Test loss:
        if validate == true then
          test_loss = criterion:forward(model:forward({data_test.features,data_test.masks}), data_test.targets)
          table.insert(test_loss_tensor,test_loss)
        end
    end
    return torch.Tensor(training_loss_tensor),torch.Tensor(test_loss_tensor)
end

--- Inference
function NeuralNetTrainer:estimate_strategies(features,masks,model)
  local new_strategy = model:forward({features,masks}):t()
  return new_strategy
end





--[[

-- Recursive visiting the tree:
function NeuralNetTrainer:generate_new_initial_strategies(node,trainer,model)
--- Getting data for non terminal and non chance nodes:
  if (not node.terminal and node.current_player ~=0) then
    local child_node = node.children[i]
    local features,masks = self:generate_features_and_masks(node)
    local new_strategy = self:estimate_strategies(features,masks,model)
    node.strategy = new_strategy
  end
  if node.children ~= nil then
    for i =1,#node.children do
      local child_node = node.children[i]
      self:generate_new_initial_strategies(child_node)
    end
  end
end


function NeuralNetTrainer:generate_features_and_masks(node)
    --- Getting the board :
    local board_bucket = self.game:get_board_from_node(node)
    --- Getting the betting history
    local history_bucket = self.game:get_beting_history(node)
    --- Concatenating features
    local input = self.game:generate_features_and_actions(board_bucket,history_bucket,node)
    local features,masks = self:convert_input_to_features_and_masks(input)

    return features,masks
end

--]]
