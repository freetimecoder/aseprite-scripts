-- Export script that exports every group as a flattened png
-- Based on gsteigert's gist: https://gist.github.com/gsteigert
-- Useful for working on texture sheets that have base color, normal or orm layers.
-- 
-- The script works by hiding all groups, setting visibility on one by one and using 
-- the export sprite function. If the file is named "example" and the groups "bc" 
-- and "n", the resulting file names will be:
--    example_bc.png
--    example_n.png
--
-- If a group has the suffix _noexp it will be ignored


-- Make sure this script can run
local spr = app.activeSprite
if not spr then
  return app.alert "You should have a sprite opened"
end


-- Since groups can be nested, visibility gets toggled recursively
local function recursive_set_visibiliy(group, new_visibility)
  for i,layer in ipairs(group.layers) do
    if layer.isGroup then
      recursive_set_visibiliy(layer, new_visibility)
    else
      layer.isVisible = new_visibility
    end
  end
end


-- Main export function
local function exportGroups()
  local folder = app.fs.filePath(spr.filename) 
  local file_title = app.fs.fileTitle(spr.filename)

  -- Count how many groups exist first
  local group_count = 0
  for i,layer in ipairs(spr.layers) do
    if layer.isGroup then
      group_count = group_count + 1
    end
  end
  
  -- Iterate through all groups
  for group_id=0,group_count-1 do
  
    -- Export name for the sprite will be set based on group name
    local export_name = ""
    
    -- Wrap all modification to the document into a transaction that can be undo'd later
    app.transaction(function()
    
      -- Groups are not referenced directly, but by their position in the layer stack
      local group_index = 0
      for i,layer in ipairs(spr.layers) do
        -- If a group is encountered, toggle visibility and set export name if 
        -- index matches
        if layer.isGroup then
          if group_index == group_id then
            recursive_set_visibiliy(layer, true)
            export_name = layer.name
          else
            recursive_set_visibiliy(layer, false)
          end
          group_index = group_index + 1
        end
      end
    
    end)
  
    -- Ignore groups that have no export flag
    if string.find(export_name, "_noexp") ~= nil then
      goto continue
    end

    -- Export flattned sprite
    app.command.ExportSpriteSheet {
      splitLayers=false,
      ui=false,
      textureFilename= folder .. "/" .. file_title .. "_" .. export_name .. ".png"
    }
  
    ::continue::
    
    -- Reset changes in document
    app.undo()
  
  end
end


-- Strt the export 
exportGroups()