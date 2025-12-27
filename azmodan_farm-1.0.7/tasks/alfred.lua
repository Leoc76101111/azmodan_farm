local plugin_label = 'azmodan_farm' 

local utils = require "core.utils"
local settings = require 'core.settings'
local loot_start = get_time_since_inject()
local loot_timeout = 3

-- Your specific safe teleport position
local safe_teleport_pos = vec3:new(-215.7539, 571.6552, 21.9052)

local status_enum = {
    IDLE = 'idle',
    WALKING_AWAY = 'walking to safe zone',
    WAITING = 'waiting for alfred to complete',
    LOOTING = 'looting stuff on floor'
}
local task = {
    name = 'alfred_running', 
    status = status_enum['IDLE']
}

local function floor_has_loot()
    return loot_manager.any_item_around(get_player_position(), 30, true, true)
end

local function reset()
    if AlfredTheButlerPlugin then
        AlfredTheButlerPlugin.pause(plugin_label)
    elseif PLUGIN_alfred_the_butler then
        PLUGIN_alfred_the_butler.pause(plugin_label)
    end
    
    if floor_has_loot() then
        loot_start = get_time_since_inject()
        task.status = status_enum['LOOTING']
    else
        task.status = status_enum['IDLE']
    end
end

function task.shouldExecute()
    local status = {enabled = false}
    if AlfredTheButlerPlugin then
        status = AlfredTheButlerPlugin.get_status()
        if (status.enabled and status.need_trigger) or
            task.status ~= status_enum['IDLE']
        then
            return true
        end
    elseif PLUGIN_alfred_the_butler then
        status = PLUGIN_alfred_the_butler.get_status()
        if status.enabled and (
            status.inventory_full or
            status.restock_count > 0 or
            status.need_repair or
            status.teleport or
            task.status ~= status_enum['IDLE']
        ) then
            return true
        end
    end
    return false
end

function task.Execute()
    -- STEP 1: If an Alfred task is needed, change state to walk away
    if task.status == status_enum['IDLE'] then
        task.status = status_enum['WALKING_AWAY']
    end

    -- STEP 2: Movement to your coordinates
    if task.status == status_enum['WALKING_AWAY'] then
        if utils.distance_to(safe_teleport_pos) > 3 then
            pathfinder.request_move(safe_teleport_pos)
            return
        else
            -- Arrived at the spot, now trigger the actual teleport
            if AlfredTheButlerPlugin then
                AlfredTheButlerPlugin.resume()
                AlfredTheButlerPlugin.trigger_tasks_with_teleport(plugin_label, reset)
            elseif PLUGIN_alfred_the_butler then
                PLUGIN_alfred_the_butler.resume()
                PLUGIN_alfred_the_butler.trigger_tasks_with_teleport(plugin_label, reset)
            end
            task.status = status_enum['WAITING']
        end
    
    -- STEP 3: Handle the teleportation cycle
    elseif task.status == status_enum['LOOTING'] and get_time_since_inject() > loot_start + loot_timeout then
        task.status = status_enum['IDLE']
    elseif task.status == status_enum['WAITING'] and
        not utils.player_in_zone("Scos_Cerrigar")
    then
        -- Standard backup teleport if the plugin state hangs
        teleport_to_waypoint(0x76D58)
    end
end

if settings.enabled and (AlfredTheButlerPlugin or PLUGIN_alfred_the_butler) then
    reset()
end

return task