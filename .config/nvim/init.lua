-- ~/.config/nvim/init.lua
-- Minimal Neovim config: mirrors the basics from ~/.vimrc, plus in-buffer
-- markdown rendering via render-markdown.nvim (Lua/treesitter, no browser).

-- ── Basic settings (ported from ~/.vimrc) ──────────────────────────────────
vim.opt.showcmd = true          -- show partial command in the last line
vim.opt.cursorline = true       -- highlight the current line
vim.opt.number = true           -- line numbers
vim.opt.laststatus = 2          -- always show the status line
vim.opt.tabstop = 4             -- a <Tab> counts for 4 spaces
vim.opt.shiftwidth = 4          -- 4 spaces per (auto)indent step
vim.opt.expandtab = true        -- use spaces instead of tabs
-- (syntax + filetype plugin/indent are on by default in Neovim)

-- Markdown reads better soft-wrapped, and conceal lets the renderer hide markers.
vim.opt.conceallevel = 2        -- render-markdown needs this to hide **, #, etc.
vim.opt.concealcursor = ""      -- but reveal raw markdown on the cursor's line
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true   -- wrap at word boundaries, not mid-word
  end,
})

-- ── Bootstrap lazy.nvim (plugin manager) ───────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ────────────────────────────────────────────────────────────────
require("lazy").setup({
  -- Theme parity with your vim (kanagawa)
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    config = function()
      pcall(vim.cmd.colorscheme, "kanagawa")
    end,
  },

  -- Treesitter: provides the markdown parsers render-markdown needs
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",              -- classic API; the default `main` branch dropped configs.setup
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = { "markdown", "markdown_inline", "lua", "vim", "vimdoc" },
      highlight = { enable = true },
    },
  },

  -- The renderer: styles headings, code blocks, tables, checkboxes, bullets
  -- in-buffer. Shows raw markdown on the line you're editing; re-renders when
  -- you leave it. Toggle with :RenderMarkdown toggle
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      render_modes = { "n", "c" },   -- render in normal/command mode; raw in insert
      heading = { sign = false },
      code = { sign = false, width = "block" },
    },
  },
}, {
  -- lazy.nvim UI/behavior options
  change_detection = { notify = false },
})

-- Quick toggle for raw vs rendered markdown
vim.keymap.set("n", "<leader>m", "<cmd>RenderMarkdown toggle<cr>",
  { desc = "Toggle markdown rendering" })
