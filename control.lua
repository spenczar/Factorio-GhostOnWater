local constants = require('modules/constants')
local Event = require('__stdlib__/stdlib/event/event')
local util = require('util')
local table = require('__stdlib__/stdlib/utils/table')
local Inventory = require('__stdlib__/stdlib/entity/inventory')

--function to check if a dummy entity prototype exists
function dummyEntityPrototypeExists(entityName)
    --check if the dummy entity prototype exists
    local dummyEntityPrototype = game.entity_prototypes[constants.dummyPrefix .. entityName]
    return dummyEntityPrototype ~= nil
end

--split function above into multiple functions to make it more readable
function getWaterGhostEntities()
    --get all ghosts
    local ghosts = game.surfaces[1].find_entities_filtered{type = "entity-ghost" }
    --loop through ghosts

    --use table.filter to filter the ghosts table
    local foundWaterGhostEntities = table.filter(ghosts, function(ghost)
        local entityName = ghost.ghost_name
        return util.string_starts_with(entityName , constants.dummyPrefix)
    end)

    return foundWaterGhostEntities
end

--function to get the original entity name from the dummy entity name
function getOriginalEntityName(dummyEntityName)
    --get the original entity name from the dummy entity name
    local originalEntityName = string.sub(dummyEntityName, string.len(constants.dummyPrefix) + 1)
    return originalEntityName
end

--function that check if the original entity could be placed in the location of the dummy entity
function canPlaceOriginalEntity(originalEntityName, dummyEntity)
    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    --get surface
    local surface = dummyEntity.surface
    --get position
    local position = dummyEntity.position
    --get direction
    local direction = dummyEntity.direction
    --check if the original entity can be placed
    local canPlace = surface.can_place_entity{name = originalEntityName, position = position, direction = direction}
    return canPlace
end

--function that replaces all dummy entity ghosts with the original entity ghosts
--use orderUpgrade to upgrade the dummy entity ghosts to the original entity ghosts
function replaceDummyEntityGhost(dummyEntity)
    --get the original entity name from the dummy entity name
    local originalEntityName = getOriginalEntityName(dummyEntity.ghost_name)
    --check if the original entity can be placed in the location and with the same direction of the dummy entity
    if canPlaceOriginalEntity(originalEntityName, dummyEntity) then
        --order upgrade (force, target)
        dummyEntity.order_upgrade{force = dummyEntity.force, target = originalEntityName}
    end
end

--Main function that turns dummy entity ghosts into normal entity ghosts after landfill has been placed
function waterGhostUpdate() 
    --get all dummy entity ghosts
    local waterGhostEntities = getWaterGhostEntities()
    --loop through dummy entity ghosts
    for _, waterGhostEntity in pairs(waterGhostEntities) do
        --replace dummy entity ghost with original entity ghost
        replaceDummyEntityGhost(waterGhostEntity)
    end
end


function updateBlueprint(event)
    --get the player
    local player = game.players[event.player_index]
    --check if the player has a blueprint selected return if not
    if not player.is_cursor_blueprint() then return end

    --check if player is really holding a blueprint item stack
    local blueprintStack = player.cursor_stack
    if not blueprintStack.valid_for_read then return end
    --get blueprint entities
    local blueprintEntities = player.get_blueprint_entities()

    --replace blueprint entities with dummy entities using table.map
    local dummyEntities = table.map(blueprintEntities, function(entity)
        if (dummyEntityPrototypeExists(entity.name)) then
            --replace entity with dummy entity
            entity.name = constants.dummyPrefix .. entity.name
        end
        return entity
    end)

    --set the blueprint entities
    local itemStack = player.cursor_stack
    local blueprint = Inventory.get_blueprint(itemStack)
    blueprint.set_blueprint_entities(dummyEntities)

end



--add event handler for on_tick
Event.on_nth_tick(60, waterGhostUpdate)
--add event handler for update blueprint shortcut using filter function
Event.register(defines.events.on_lua_shortcut, updateBlueprint , function(event, shortcut)
    return event.prototype_name == "ShortcutWaterGhostBlueprintUpdate" end, "")
Event.register("InputWaterGhostBlueprintUpdate"  , updateBlueprint)