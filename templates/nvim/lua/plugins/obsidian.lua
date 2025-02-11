return {
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest
    lazy = true,
    ft = "markdown",
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "Second Brain",
          path = "~/SecondBrain",
        },
      },
      notes_subdir = "inbox",
      new_notes_location = "notes_subdir",

      disable_formatter = true,
      templates = {
        subdir = "templates",
        template = "note.md",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M:%S",
        substitutions = {},
      },
      -- note_frontmatter_func = function(note)
      --   -- Add the title of the note as an alias.
      --   if note.title then
      --     note:add_alias(note.title)
      --   end
      --
      --   local out = {
      --     id = note.id,
      --     aliases = note.aliases,
      --     tags = note.tags,
      --   }
      --   -- `note.metadata` contains any manually added fields in the frontmatter.
      --   -- So here we just make sure those fields are kept in the frontmatter.
      --   if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
      --     for k, v in pairs(note.metadata) do
      --       out[k] = v
      --     end
      --   end
      --
      --   return out
      -- end,

      -- key mappings, below are the defaults
      mappings = {
        --overrides the 'gf' mapping to work on markdown/wiki links within your vault
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
      },
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
      ui = {
        -- disable theses
        checkboxes = {},
        bullets = {},
      },

      attachments = {
        -- The default folder to place images in via `:ObsidianPasteImg`.
        -- If this is a relative path it will be interpreted as relative to the vault root.
        -- You can always override this per image by passing a full path to the command instead of just a filename.
        img_folder = "assets/imgs", -- This is the default
        -- A function that determines the text to insert in the note when pasting an image.
        -- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
        -- This is the default implementation.
        ---@param client obsidian.Client
        ---@param path obsidian.Path the absolute path to the image file
        ---@return string
        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format("![%s](%s)", path.name, path)
        end,
      },
    },
  },
}
