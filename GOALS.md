# Open

- Add smart groups.
    - Selecting certain entities with a intuitive group will create a deconstruction planner for the entire group.
    - On a different hotkey (Shift + D)
    - Groups:
        - Transport Belt: belts, underground belts, splitters
        - Rail: rails, signals (Chain and normal), train stops
        - Support: rail supports, rail ramps
- Create "Item request slot" deconstructor when hovering an entity that has an item request.
  - Configurable
- Apply the same logic to upgrade planners.


# Done

- Add ghost handling.
    - Default: Create ghost deconstructor.
    - With setting: Create deconstructor for underlying entity.
- Add pentapod shell support.
    - Currently, selecting a pentapod shell results in a tree deconstructor.
    - Selecting such shell should create a deconstructor with all 3 shell types.
- Add rail support.
    - Selecting any rail should always create a "straight rail" deconstruction planner, which innately includes curved
      and diagonal rails.


# Discarded

- Define icons for groups.
    - The visual feedback for the user is better if they see the filtered entities directly,
      even if a group icon would look more neat.