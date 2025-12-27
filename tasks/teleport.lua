local plugin_label = 'azmodan_farm'
local utils = require "core.utils"

local task = {
    name = 'teleport',
    status = 'idle'
}

function task.shouldExecute()
    local fight_center = vec3:new(-217.6220, 616.8730, 22)
    
    -- Only teleport if we are NOT in town AND NOT in the boss zone
    -- And we must be far enough (>150 units) that walking back isn't feasible
    return not utils.player_in_zone('Hawe_WorldBoss') and 
           not utils.player_in_zone('Hawe_Zarbinzet') and
           utils.distance_to(fight_center) > 150
end

function task.Execute()
    console.print("Player lost. Teleporting to Zarbinzet to restart path.")
    teleport_to_waypoint(0xA46E5)
end

return task
