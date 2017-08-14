--- Computes a cross_entropy loss for neural net training and evaluation.

require 'nn'
local arguments = require 'Settings.arguments'

local StrategyLoss = torch.class('StrategyLoss')

--- Constructor
function StrategyLoss:__init()
  self.criterion = nn.SmoothL1Criterion()
end

--- Computes the loss over a batch of neural net outputs and targets.
--
-- @param outputs an NxM tensor containing N vectors of values over buckets,
-- output by the neural net
-- @param targets an NxM tensor containing N vectors of actual values over
-- buckets, produced by @{data_generation_call}
-- @param mask an NxM tensor containing N mask vectors generated with
-- @{bucket_conversion.get_possible_bucket_mask}
-- @return the sum of Huber loss applied elementwise on `outputs` and `targets`,
-- masked so that only valid buckets are included
function StrategyLoss:forward(outputs, targets)
  local number_of_points= outputs:size(1)
  --1.0 zero out the outputs/target so that the error does not depend on these
  local mask = outputs:clone():eq(0):float()
  new_outputs = outputs + mask
  new_outputs:log()
  local new_targets = targets:clone()
  local new_loss = new_targets:cmul(new_outputs)
  loss = -torch.sum(new_loss)/number_of_points

  return loss
end

--- Computes the gradient of the loss function @{forward} with
-- arguments `outputs`, `targets`, and `mask`.
--
-- Must be called after a @{forward} call with the same arguments.
--
-- @param outputs an NxM tensor containing N vectors of values over buckets,
-- output by the neural net
-- @param targets an NxM tensor containing N vectors of actual values over
-- buckets, produced by @{data_generation_call}
-- @param mask an NxM tensor containing N mask vectors generated with
-- @{bucket_conversion.get_possible_bucket_mask}
-- @return the gradient of @{forward} applied to the arguments
function StrategyLoss:backward(outputs, targets)
  local number_of_points= outputs:size(1)
  ---local dloss_doutput = self.criterion:backward(outputs, targets)

  --we use the multiplier computed with the mask during forward call
  --dloss_doutput:cdiv(self.mask_multiplier:expandAs(dloss_doutput))
  local mask = outputs:clone():eq(0):float()
  new_outputs = outputs + mask

  local dloss_doutput = targets:clone()
  dloss_doutput:cdiv(new_outputs)


  return -dloss_doutput/number_of_points
end
