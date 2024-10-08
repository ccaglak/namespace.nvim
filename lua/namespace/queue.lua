local Queue = {}
Queue.__index = Queue

function Queue.new()
  local self = setmetatable({}, Queue)
  self.first = 0
  self.last = -1
  return self
end

function Queue:push(value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function Queue:pop()
  local first = self.first
  if first > self.last then
    return nil
  end
  local value = self[first]
  self[first] = nil
  self.first = first + 1
  return value
end

function Queue:is_empty()
  return self.first > self.last
end

return Queue
