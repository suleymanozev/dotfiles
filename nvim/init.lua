-- Neovim init config
-- ~/.config/nvim/init.lua
--
-- Jongwook Choi (@wookayin)
-- https://dotfiles.wook.kr


-- The global namespace for config-related stuffs.
-- e.g., config.lsp should be the same as require("config.lsp")
config = config or setmetatable({}, {
  __index = function(self, key)
    local modname = 'config.' .. key
    if package.loaded[modname] then
      return require(modname)
    else
      return nil
    end
  end
})
_G.config = config

-- require a lua module, but force reload it (RC files can be re-sourced)
function _require(name)
  package.loaded[name] = nil
  return require(name)
end

-- Lua profiling startup time. Make sure lazy.nvim plugins are already installed.
-- Use `NVIM_LUA_PROFILING=1 nvim` to enable.
-- Use `NVIM_LUA_PROFILING=2 nvim` to include lazy-loaded plugins as well.
if vim.env.NVIM_LUA_PROFILING then
  package.path = string.format("%s;%s/lua/?.lua", package.path, vim.fn.expand("~/.vim/plugged/nvim-profiler"))
  require('profiler').reload_builtin_modules()
  require('profiler').start()
  _G._stop_profiling = function()
    require('profiler').stop()
    require('profiler').open_result()
  end
  if vim.env.NVIM_LUA_PROFILING == '2' then
    _G._stop_profiling = vim.schedule_wrap(_G._stop_profiling)
  end
end

-- This is the home folder of NVIM config files.
vim.env.DOTVIM = vim.fn.expand('~/.config/nvim')

-- Configure neovim python host.
-- This can be executed lazily after entering vim, to save startup time.
vim.schedule(function() require 'config.pynvim' end)
require 'config.fixfnkeys'
require 'config.compat'

-- Source plain vimrc for basic settings.
-- This should precede plugin loading via lazy.nvim.
vim.cmd [[
  source ~/.vimrc
]]

-- Check neovim version
if vim.fn.has('nvim-0.9.2') == 0 then
  vim.cmd [[
    echohl WarningMsg | echom 'This version of neovim is unsupported. Please upgrade to Neovim 0.9.2+ or higher.' | echohl None
  ]]
  vim.cmd [[ filetype plugin off ]]
  vim.o.loadplugins = false
  vim.o.swapfile = false
  vim.o.shadafile = "NONE"
  return

elseif vim.fn.has('nvim-0.10') == 0 then
  ---@type string  e.g. "NVIM v0.10.0"
  local nvim_version = vim.split(vim.api.nvim_exec2('version', { output = true }).output, '\n', { trimempty = true })[1]
  local show_warning = function()
    local like_false = function(x) return x == nil or x == "0" or x == "" end
    if not like_false(vim.env.DOTFILES_SUPPRESS_NEOVIM_VERSION_WARNING) then return end
    local msg = 'Please upgrade to a recent version of neovim (0.10+).\n'
    msg = msg .. 'Support for old neovim will be dropped soon.'
    msg = msg .. '\n\n' .. string.format('Try: $ %s install neovim', vim.fn.has('mac') > 0 and 'brew' or 'dotfiles')
    msg = msg .. '\n\n' .. ('If you cannot upgrade yet but want to suppress this warning,\n'
                            .. 'use `export DOTFILES_SUPPRESS_NEOVIM_VERSION_WARNING=1`.')
    vim.notify(msg, vim.log.levels.ERROR, { title = 'Deprecation Warning', timeout = 5000 })
    vim.g.DOTFILES_DEPRECATION_CACHE = { version = nvim_version, timestamp = os.time() }
  end
  vim.defer_fn(function()
    local cache = vim.g.DOTFILES_DEPRECATION_CACHE or {}
    if cache.version ~= nvim_version or os.time() - cache.timestamp > 3600 then
      show_warning()  -- show warning only once per hour.
    end
  end, 100)
end

-- "vim --noplugin" would disable all plugins
local noplugin = not vim.o.loadplugins
if not noplugin then
  -- Load all the plugins (lazy.nvim, requires nvim 0.8+)
  -- Note: lazy.nvim alters &loadplugins by design
  require 'config.plugins'
end

do
  -- Colorscheme needs to be called AFTER plugins are loaded,
  -- because of the different plugin loading mechanism and order.
  -- NOTE: while we can simply do 'colorscheme xoria256-wook', this will trigger lazy.nvim to
  -- invoke a ColorschemePre event and wastes ~10ms. But we still need to trigger 'Colorscheme'.
  vim.cmd [[
   noautocmd colorscheme xoria256-wook
   doautocmd ColorScheme xoria256-wook
  ]]
end

if noplugin then
  return
end

-- Source some individual rc files on startup, manually in sequence.
-- Note that many other config modules are called upon plugin loading.
-- (see each plugin spec, e.g. 'plugins/ui' and 'config/ui')
-- See nvim/lua/config/commands/init.lua
_require 'config.keymap'
_require 'config.commands'
_require 'config.statuscolumn'

require 'config.folding'

-- Neovim 0.12+, :help vim._extui
require('config.ui').setup_extui()

-- Source local-only lua configs (not git tracked)
if vim.fn.filereadable(vim.fn.expand('~/.config/nvim/lua/config/local.lua')) > 0 then
  require 'config.local'
end


if vim.env.NVIM_LUA_PROFILING then
  vim.api.nvim_create_autocmd('VimEnter', { pattern = '*', callback = _G._stop_profiling })
end
