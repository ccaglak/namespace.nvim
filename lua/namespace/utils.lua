-- dont use -- custom to get_filtered_classes()
-- remore when possible
function table.contains2(t, value) -- tobe removed in future
  for _, k in ipairs(t) do
    for _, v in pairs(k) do
      if v == value then
        return true
      end
    end
  end
  return false
end

-- dont use -- custom to get_filtered_classes()
-- remore when possible
function table.remove_duplicates(tbl) -- tobe removed in future
  local hash = {}
  local result = {}

  for _, v in ipairs(tbl) do
    if not hash[v.name] then
      hash[v.name] = true
      table.insert(result, v)
    end
  end

  return result
end
