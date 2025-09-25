# Open

- Allow extending an existing planner with more entities.
  - Pressing the hotkey again while holding a planner will add entities.
  - Prevent duplicate additions.
- Add a shortcut mode
    - Click the shortcut will first create an "empty" planner, which will then take on the type of the first clicked
      entity.
- Add smart groups.
    - Selecting certain entities with an intuitive group will create a deconstruction planner for the entire group.
    - On a different hotkey (Shift + D)
    - Groups:
        - Transport Belt: belts, underground belts, splitters
        - Rail: rails, signals (Chain and normal), train stops
        - Support: rail supports, rail ramps
- Apply the same logic to upgrade planners.
    - Make the planner a temporary item
    - Instantly open the config dialog
- Add visual feedback to when an entity has been added (or removed) for the planner, when using extensible mode.
- Add filtered copy planners (copy, cut, blueprint)
    - Using the same logic, using the hotkey creates a planner with the hovered entity, dragging executes the planner.

# Done

- Add a shortcut to add more entities to the current planner.
    - Something intuitive, like Alt + Click.
    - Needs special handling for tree/rock deconstruction.
- Create "Item request slot" deconstructor when hovering an entity that has an item request.
    - Configurable
- Add ghost handling.
    - Default: Create ghost deconstructor.
    - With setting: Create deconstructor for underlying entity.
- Add pentapod shell support.
    - Currently, selecting a pentapod shell results in a tree deconstructor.
    - Selecting such shell should create a deconstructor with all 3 shell types.
- Add rail support.
    - Selecting any rail should always create a "straight rail" deconstruction planner, which innately includes curved
      and diagonal rails.

# Bugs

- Behemoth stomper shells try to get added even without the mod active.

# Fixed

- Having a permanent "trees and rocks only" planner will allow you to insert entities into it.

# Discarded

- Define icons for groups.
    - The visual feedback for the user is better if they see the filtered entities directly,
      even if a group icon would look more neat.