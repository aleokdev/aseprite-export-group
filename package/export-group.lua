-- This script exports each layer in the current group as a separate file.
-- The user can specify the directory, filename format, and export format.
-- The filename format can contain the following placeholders:
--   {groupname} - the name of the group
--   {layername} - the name of the layer
-- The export format can be any of the following (Supported aseprite formats from v1.3.13):
--   ase, aseprite, bmp, css, flc, fli, gif, ico, jpeg, jpg, pcx, pcc, png, qoi, svg, tga, webp
-- The user can also specify whether to trim each layer before exporting.

EXPORT_FORMATS = { 'ase', 'aseprite', 'bmp', 'css', 'flc', 'fli', 'gif', 'ico', 'jpeg', 'jpg', 'pcx', 'pcc', 'png', 'qoi',
  'svg', 'tga', 'webp' }

function init(plugin)
  plugin:newCommand {
    id = "ExportGroupAs",
    title = "Export As...",
    group = "layer_popup_properties",
    onclick = function()
      local dlg = Dialog {
        title = "Export Group As",
      }
      dlg:newrow { always = true }

      CHANGED_TO_PARENT_DIR = false
      dlg:file {
        id = "output_dir_path",
        label = "Directory to export to",
        save = true,
        filetypes = { '' },
        filename = plugin.preferences.export_dir or "Select directory",
        onchange = function()
          if CHANGED_TO_PARENT_DIR then return end

          -- Use the directory as the "filename" to show
          local filename = dlg.data.output_dir_path
          filename = filename:gsub("\\", "/")
          local parent_dir = filename:match("^(.+)/[^/]*$")
          if parent_dir then
            -- Prevent infinite loop (onchange is called when we modify the filename)
            CHANGED_TO_PARENT_DIR = true
            dlg:modify { id = "output_dir_path", filename = parent_dir }
            CHANGED_TO_PARENT_DIR = false
          end
        end
      }
      dlg:entry { id = "filename_format", label = "Filename format", text = plugin.preferences.export_filename_format or "{groupname}-{layername}" }
      dlg:combobox {
        id = 'export_format',
        label = 'Export format',
        option = plugin.preferences.export_format or 'png',
        options = EXPORT_FORMATS
      }
      dlg:check {
        id = "trim",
        label = "Trim each layer",
        selected = plugin.preferences.trim or false
      }
      dlg:button { id = "ok", text = "Export" }
      dlg:show { wait = true }

      if not dlg.data.ok then return 0 end

      local extension = dlg.data.export_format
      local directory = dlg.data.output_dir_path .. '/'
      local groupname = app.site.layer.name

      if dlg.data.output_dir_path then
        for i, layer in ipairs(app.site.layer.layers) do
          -- Obtain the name for this file
          local layername = layer.name
          local textureFilename = directory ..
              dlg.data.filename_format:gsub("{groupname}", groupname):gsub("{layername}", layername) .. '.' ..
              extension
          -- https://aseprite.org/api/command/ExportSpriteSheet#exportspritesheet
          print(layer)
          app.command.ExportSpriteSheet {
            ui = false,
            recent = false,
            layer = layer.name,
            trim = dlg.data.trim,
            textureFilename = textureFilename,
            dataFilename = ""
          }
        end

        plugin.preferences.export_dir = dlg.data.output_dir_path
        plugin.preferences.export_filename_format = dlg.data.filename_format
        plugin.preferences.export_format = dlg.data.export_format
        plugin.preferences.trim = dlg.data.trim
      end
    end,

    onenabled = function()
      -- Only enable the command if the user has a group selected
      return app.site.layer.layers ~= nil
    end
  }
end

function exit(plugin)
end
