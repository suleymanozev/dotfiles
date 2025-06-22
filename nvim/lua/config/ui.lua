-- config/ui.lua
-- Configs for UI-related plugins.

local M = {}

-- Experimental: highlight cmdline, messages in a real buffer.
-- See https://github.com/neovim/neovim/pull/27811 and :help vim._extui
function M.setup_extui()
  if vim.fn.has('nvim-0.12') == 0 then
    return false
  end

  require('vim._extui').enable {
    enable = true,
    msg = {
      pos = 'cmd',  -- for now I'm happy with 'cmd'; 'box' seems buggy
    },
  }
end

function M.setup_notify()
  vim.cmd [[
    command! -nargs=0 NotificationsPrint   :lua require('notify')._print_history()
    command! -nargs=0 PrintNotifications   :NotificationsPrint
    command! -nargs=0 Messages             :NotificationsPrint
  ]]
  vim.g.nvim_notify_winblend = 20

  -- :help notify.setup()
  -- :help notify.config
  ---@diagnostic disable-next-line: missing-fields
  require('notify').setup({
    stages = "slide",
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { focusable = false })
      vim.wo[win].winblend = vim.g.nvim_notify_winblend
    end,
    level = (function()
      local is_debug = #(os.getenv("DEBUG") or "") > 0 and os.getenv("DEBUG") ~= "0";
      if is_debug then
        vim.schedule(function() vim.notify("vim.notify threshold = DEBUG", vim.log.levels.DEBUG, { title = 'nvim-notify' }) end)
        return vim.log.levels.DEBUG
      else return vim.log.levels.INFO
      end
    end)(),
    timeout = 3000,
    fps = 60,
    background_colour = "#000000",
  })

  --- @class config.ui.notify.Config: notify.Config
  --- @field print? boolean If true, also do :echomsg (so that msg can be saved in :messages)
  --- @field echom? boolean Alias to print
  --- @field markdown? boolean If true, highlight the message window in markdown with treesitter.
  --- @field lang? string If given, highlight the message window in the given lang with treesitter.
  ---
  --- vim.notify with additional extensions on opts
  --- @param opts config.ui.notify.Config?
  vim.notify = function(msg, level, opts)
    opts = opts or {}
    if opts.print or opts.echom then
      local hlgroup = ({
        [vim.log.levels.WARN] = 'WarningMsg', ['warn'] = 'WarningMsg',
        [vim.log.levels.ERROR] = 'Error', ['error'] = 'Error',
      })[level] or 'Normal'
      vim.api.nvim_echo({{ msg, hlgroup }}, true, {})
    end

    if opts.markdown then
      opts.lang = 'markdown'
    end
    if opts.lang then
      local treesitter_on_open = vim.schedule_wrap(function(win)
        local buf = vim.api.nvim_win_get_buf(win)
        vim.wo[win].conceallevel = 2  -- do not show literally ```, etc.
        pcall(vim.treesitter.start, buf, opts.lang)
      end)
      opts.on_open = (function(on_open)
        return function(win)
          if on_open ~= nil then on_open(win) end
          treesitter_on_open(win)
        end
      end)(opts.on_open)
    end

    return require("notify")(msg, level, opts)
  end

  require("config.telescope").on_ready(function()
    require("telescope").load_extension("notify")
    vim.cmd [[ command! -nargs=0 Notifications  :Telescope notify ]]
  end)
end

function M.setup_dressing()
  -- Prettier vim.ui.select() and vim.ui.input()
  -- https://github.com/stevearc/dressing.nvim#configuration
  -- default config: $VIMPLUG/dressing.nvim/lua/dressing/config.lua
  require('dressing').setup {

    input = {
      -- the greater of 140 columns or 90% of the width
      prefer_width = 80,
      max_width = { 140, 0.9 },

      border = 'double',

      -- Allow per-instance dynamic option. See stevearc/dressing.nvim#71
      -- merge the current input config with the runtime dynamic opts
      get_config = function(opts)
        local current_opts = require("dressing.config").input
        return vim.tbl_deep_extend("force", current_opts, opts or {})
      end,
    },

    select = {
      -- Note: fzf_lua backend is buggy, does not trigger on_choice upon abort()
      backend = { "telescope", "builtin" },

      -- Allow per-instance dynamic option. See stevearc/dressing.nvim#71
      -- merge the current input config with the runtime dynamic opts
      get_config = function(opts)
        local current_opts = require("dressing.config").input
        return vim.tbl_deep_extend("force", current_opts, opts or {})
      end,
    },

  }
end

function M.init_quickui()
  -- Use unicode-style border (┌─┐) which is more pretty
  vim.g.quickui_border_style = 2

  -- Default preview window size (more lines and width)
  vim.g.quickui_preview_w = 100
  vim.g.quickui_preview_h = 25

  -- Customize color scheme
  vim.g.quickui_color_scheme = 'papercol light'
end

function M.setup_quickui()
  -- Quickui overrides highlight when colorscheme is set (when lazy loaded),
  -- so make sure this callback is executed AFTER plugin init
  -- to correctly override the highlight
  require "utils.rc_utils".RegisterHighlights(function()
    vim.cmd [[
      hi! QuickPreview guibg=#262d2d
    ]]
  end)
end

function M.setup_image()
  -- setup for image.nvim
  -- requirements: ImageMagick and kitty-graphics compatible terminal emulator
  local has_magick = vim.fn.executable('magick') == 1
  local is_compat_term = vim.iter and vim.iter({ 'tmux', 'kitty', 'ghostty', 'WezTerm' }):find(vim.env.TERM_PROGRAM)
  if not (has_magick and is_compat_term) then
    return false
  end

  -- see $VIMPLUG/image.nvim/lua/image/init.lua for default_options
  require('image').setup {
    backend = 'kitty',  -- kitty backend only for now (ghostty, kitty, and wezterm).
    processor = 'magick_cli',
    hijack_file_patterns = {
      "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg", "*.pdf",
      "*.webp", "*.avif",
    },
  }
end

-- Resourcing support
if ... == nil then
  M.setup_notify()
  M.setup_dressing()
  M.init_quickui()
  M.setup_quickui()
end

return M
