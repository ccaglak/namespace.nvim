local subcommand_tbl = {
  class = {
    impl = function()
      require("namespace").class()
    end,
  },
  classes = {
    impl = function()
      require("namespace").classes()
    end,
  },
  namespace = {
    impl = function()
      require("namespace").namespace()
    end,
  },
}

local function my_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommand_tbl[subcommand_key]
  if not subcommand then
    vim.notify("Php: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  subcommand.impl(args, opts)
end

vim.api.nvim_create_user_command("Php", my_cmd, {
  nargs = "+",
  desc = "PhpNamespace",
  complete = function(arg_lead, cmdline, _)
    local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Php[!]*%s(%S+)%s(.*)$")
    if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete then
      return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
    end
    if cmdline:match("^['<,'>]*Php[!]*%s+%w*$") then
      local subcommand_keys = vim.tbl_keys(subcommand_tbl)
      return vim
        .iter(subcommand_keys)
        :filter(function(key)
          return key:find(arg_lead) ~= nil
        end)
        :totable()
    end
  end,
  bang = true,
})
