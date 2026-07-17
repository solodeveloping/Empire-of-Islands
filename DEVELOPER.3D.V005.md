- [x] Travelling ship
	- [x] Sell or buy resources
	- [x] Can click on it
		- [x] Display information
		- [x] Display gold count
		- [x] Display resources
	- [x] Sound when it arrives at the dock
	- [x] Storage
		- [x] Max weight
		- [x] Max space

- [x] Resources
	- [x] Have weight
	- [x] Have space

- [x] Trading
	- [x] Global storage system
		- [x] Sell based on price/quantity
		- [x] Buy based on price/quantity
		- Constant price threshold

- [ ] Unit
	- [x] Can click on it
	- [x] Display information
		- [x] Gold count
		- [x] Hasn't eaten for
		- [x] Hasn't been paid for
		- [x] Is starving
		- [x] Is dead
	- [x] Can move it (more options later on)
		- [ ] Don't move in ocean ground
		- [x] Don't contribute to work count of building if not present
	- [x] Use CharacterBody3D to move it
		- [x] Make sure we can reach the building
	- [x] Gain a salary if working
		- [x] Stop working if not paid
	- [x] Consume food
		- [x] Take food from global storage of own faction
		- [x] Dies if no food
	- [x] Assign to faction

- [x] Factions
	- [x] Buildings belong to a faction
	- [x] Ships belong to a faction
	- [x] Units belong to a faction
	- [x] Starts with custom resources
	- [x] Color
	- [x] Custom color
	- [x] Custom flag
	- [x] Neutral faction
		- [x] Food consumption
			- If works, consume production building's faction food
			- Otherwise, take neutral faction food

- [x] Buildings
	- [x] Produce to their faction global storage

- [x] UI
	- [x] Buildings
		- [x] Show faction
	- [x] Trade
		- [x] Close is click outside

- [x] RTS camera
	- [x] Disable camera movement if trade UI is opened
