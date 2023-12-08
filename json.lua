local com = vim.fn.readfile("composer.json")

local co = vim.fn.json_decode(com)

local tc = co["autoload"]["psr-4"]

P(tc)
