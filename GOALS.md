# Open
- Customizable wait conditions (For any temp station).
- Teleport train on call (Configurable)
    - Wait for the rail to be clear as not to collide with other trains.

- Show time till arrival.
- Sensible default wait conditions.
- Hotkey to switch the personal train to manual and back.
- Allow any train to be called (Configuration: Personal Only/Bidirectional Only/Any).
    - Get closest one.
- Switch to manual when arriving at the target station.
- Queue up new temporary stops while the train is being called.

# Done
- Switch to manual when entering
- Configuration
    - Search Radius
    - Auto pickup/eject
    - Open interface
    - Switch to manual
- Auto Pickup the player if nearby.
- Auto eject the player when arriving at any temp station.
- Open the train interface when entering the train.
- Do not show waiting indicator if the train is already at the target rail.
- Call to rail if a specific rail is selected.
- Offer Shortcut to open the train interface.
- Create fancy icons.

# Discarded
- Use map pin to show the arrival location.
    - Currently there is no way to programatically delete map pins.
- Remove the personal temp station when creating a new one (Via map)
    - Othewise, the call station will stay up and the train will drive back to it.
    - The behaviour of the current station is extremely whacky. It is is unreliable at the time when the event fires and modifying the schedule often leads to misplaced wait conditions.