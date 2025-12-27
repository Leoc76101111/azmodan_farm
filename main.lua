local plugin_label = 'azmodan_farm'

local gui          = require 'gui'
local settings     = require 'core.settings'
local task_manager = require 'core.task_manager'
local tracker      = require 'core.tracker'

local local_player, player_position
local debounce_time = nil
local debounce_timeout = 1

local function update_locals()
    local_player = get_local_player()
    player_position = local_player and local_player:get_position()
end

local function main_pulse()
    if not local_player then return end
    if gui.elements.drop_sigil_keybind:get_state() == 1 then
        if debounce_time ~= nil and debounce_time + debounce_timeout > get_time_since_inject() then return end
        gui.elements.drop_sigil_keybind:set(false)
        tracker.drop_sigils = true
        task_manager.execute_tasks()
    end

    settings:update_settings()
    if (not settings.enabled or not settings.get_keybind_state()) and not tracker.drop_sigils then return end

    if local_player:is_dead() then
        revive_at_checkpoint()
    else
        task_manager.execute_tasks()
    end
end

local function render_pulse()
    -- Only show any overlay if the master module is powered on
    if not local_player or not settings.enabled then return end

    -- Determine screen width for positioning
    local screen_width = 1920 
    if graphics.get_screen_width then 
        screen_width = graphics.get_screen_width() 
    end
    
    -- Positioning: 1/4 from the left, top corner area
    local status_pos = vec2:new(screen_width / 4, 25)

    -- Status Overlay Logic
    local is_running = settings.get_keybind_state()
    if is_running then
        graphics.text_2d("AZMODAN BOT: RUNNING", status_pos, 18, color_green(255))
        
        -- Display the current task above the player's head
        local current_task = task_manager.get_current_task()
        if current_task then
            local px, py, pz = player_position:x(), player_position:y(), player_position:z()
            graphics.text_3d("Current Task: " .. current_task.name, vec3:new(px, py - 2, pz + 3), 14, color_white(255))
        end
    else
        graphics.text_2d("AZMODAN BOT: STANDBY", status_pos, 18, color_yellow(255))
    end
end

on_update(function()
    update_locals()
    main_pulse()
end)

on_render_menu(function ()
    gui.render()
end)
on_render(render_pulse)
