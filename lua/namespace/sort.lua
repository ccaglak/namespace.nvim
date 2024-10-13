local M = {}
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


local sort_functions = {
  ascending = sort_lines,
  descending = sort_lines_reverse,
  length_asc = sort_lines_line_length,
  length_desc = sort_lines_line_length_reverse,
  natural = sort_lines_natural,
  case_insensitive = sort_lines_case_insensitive,
}

function M.sortUseStatements(sort)
  local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
  local use_statements = vim.tbl_filter(function(line)
    return vim.startswith(line, "use ")
  end, lines)

  local sort_function = sort_functions[sort.sort_type]
  use_statements = sort_function(use_statements)

  local start_line, end_line
  for i, line in ipairs(lines) do
    if vim.startswith(line, "use ") and not start_line then
      start_line = i - 1
    elseif start_line and not vim.startswith(line, "use ") then
      end_line = i - 1
      break
    end
  end

  if start_line and end_line then
    local sorted_slice = vim.list_slice(use_statements, 1, end_line - start_line)
    vim.api.nvim_buf_set_lines(0, start_line, end_line, false, sorted_slice)
  end
end

return M
