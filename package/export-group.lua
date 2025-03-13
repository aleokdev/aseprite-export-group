function init(plugin)
  plugin:newCommand {
    id = "ExportGroupAs",
    title = "Export As...",
    group = "layer_popup_properties",
    onclick = function()
      local dlg = Dialog {
        title = "Export Group As",
        hexpand = true
      }
      dlg:newrow { always = true }
      just_modified = false
      dlg:file {
        id = "file",
        label = "Directory to export to",
        save = true,
        filetypes = { '' },
        filename = plugin.preferences.export_dir or "Select directory",
        onchange = function()
          if just_modified then return end

          -- Use the directory as the "filename" to show
          local filename = dlg.data.file
          filename = filename:gsub("\\", "/")
          local parent_dir = filename:match("^(.+)/[^/]*$")
          if parent_dir then
            print("parent dir " .. parent_dir)
            -- Prevent infinite loop (onchange is called when we modify the filename)
            just_modified = true
            dlg:modify { id = "file", filename = parent_dir }
            just_modified = false
          end
        end
      }
      dlg:entry { id = "filename_format", label = "Filename format", text = plugin.preferences.export_filename_format or "{groupname}-{layername}" }
      dlg:combobox {
        id = 'format',
        label = 'Export format',
        option = plugin.preferences.export_format or 'png',
        options = { 'ase', 'aseprite', 'bmp', 'css', 'flc', 'fli', 'gif', 'ico', 'jpeg', 'jpg', 'pcx', 'pcc', 'png', 'qoi', 'svg', 'tga', 'webp' }
      }
      dlg:check {
        id = "trim",
        label = "Trim each layer",
        selected = plugin.preferences.trim or false
      }
      dlg:button { id = "ok", text = "Export" }
      dlg:show { wait = true }

      if not dlg.data.ok then return 0 end

      local extension = dlg.data.format
      local directory = dlg.data.file .. '/'
      local groupname = app.site.layer.name

      if dlg.data.file then
        for i, layer in ipairs(app.site.layer.layers) do
          -- Obtain the name for this file
          local layername = layer.name
          local textureFilename = directory ..
              dlg.data.filename_format:gsub("{groupname}", groupname):gsub("{layername}", layername) .. '.' ..
              extension
          -- https://aseprite.org/api/command/ExportSpriteSheet#exportspritesheet
          app.command.ExportSpriteSheet {
            ui = false,
            recent = false,
            listLayers = layer,
            trim = dlg.data.trim,
            textureFilename = textureFilename,
            dataFilename = ""
          }
        end

        plugin.preferences.export_dir = dlg.data.file
        plugin.preferences.export_filename_format = dlg.data.filename_format
        plugin.preferences.export_format = dlg.data.format
        plugin.preferences.trim = dlg.data.trim
      end
    end,
    onenabled = function()
      return app.site.layer.layers ~= nil
    end
  }
end

function exit(plugin)
end
