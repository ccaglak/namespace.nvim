local M = {}

-- Local functions for better performance
local function sort_lines(lines)
  table.sort(lines)
  return lines
end

local function sort_lines_case_insensitive(lines)
  table.sort(lines, function(a, b)
    return string.lower(a) < string.lower(b)
  end)
  return lines
end

local function sort_lines_reverse(lines)
  table.sort(lines, function(a, b)
    return a > b
  end)
  return lines
end

local function sort_lines_line_length(lines)
  table.sort(lines, function(a, b)
    return #a < #b
  end)
  return lines
end

local function sort_lines_line_length_reverse(lines)
  table.sort(lines, function(a, b)
    return #a > #b
  end)
  return lines
end

-- Optimized natural sort function
local function sort_lines_natural(lines)
  local function natural_compare(a, b)
    local function split_number(s)
      local num, alpha = s:match("^(%d*)(%D*)")
      return tonumber(num) or 0, alpha
    end

    local function compare_parts(numA, alphaA, numB, alphaB)
      if numA ~= numB then
        return numA < numB
      end
      return alphaA < alphaB
    end

    local numA, alphaA = split_number(a)
    local numB, alphaB = split_number(b)

    while numA or alphaA do
      if compare_parts(numA, alphaA, numB, alphaB) then
        return true
      end
      if compare_parts(numB, alphaB, numA, alphaA) then
        return false
      end

      a = a:sub(#tostring(numA) + #alphaA + 1)
      b = b:sub(#tostring(numB) + #alphaB + 1)
      numA, alphaA = split_number(a)
      numB, alphaB = split_number(b)
    end

    return #a < #b
  end

  table.sort(lines, natural_compare)
  return lines
end

-- More efficient unique line removal
local function remove_duplicate_lines(lines)
  local seen = {}
  local result = {}
  for i = 1, #lines do
    local line = lines[i]
    if not seen[line] then
      seen[line] = true
      result[#result + 1] = line
    end
  end
  return result
end

-- Lazy loading of sort functions
local sort_functions = {
  ascending = sort_lines,
  descending = sort_lines_reverse,
  length_asc = sort_lines_line_length,
  length_desc = sort_lines_line_length_reverse,
  natural = sort_lines_natural,
  case_insensitive = sort_lines_case_insensitive,
}

-- Get and sort use statements
function M.sortUseStatements(config, sort_type)
  local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
  local use_statements = vim.tbl_filter(function(line)
    return line:match("^use ")
  end, lines)

  local sort_function = sort_functions[sort_type or config.sort_type] or sort_lines
  use_statements = sort_function(use_statements)

  if config.remove_duplicates then
    use_statements = remove_duplicate_lines(use_statements)
  end

  -- Find the range of use statements in the original buffer
  local start_line, end_line
  for i, line in ipairs(lines) do
    if line:match("^use ") and not start_line then
      start_line = i - 1
    elseif start_line and not line:match("^use ") then
      end_line = i - 1
      break
    end
  end

  -- Replace the use statements in the buffer
  if start_line and end_line then
    vim.api.nvim_buf_set_lines(0, start_line, end_line, false, use_statements)
  end
end

return M

-- local sort = require('namespace.sort')
-- local config = {
--     sort_type = 'natural',
--     remove_duplicates = true
-- }
-- sort.sortUseStatements(config, 'ascending')  -- This will use 'ascending' sort instead of 'natural'
