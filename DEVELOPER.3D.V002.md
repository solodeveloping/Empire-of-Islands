- [x] Map
	- [x] Load it instead of having it in the MainScene

- [x] Buildings
	- [x] Cost resources
		- [x] Check resources when clicking on ground
		- [x] Check resources when clicking on button
		- [x] Display proper costs
		- [x] Remove resources from storage
	- [x] Click on building
		- [x] Display basic information
			- [x] Building type name
			- [x] Worker counts
			- [x] Housing count
		- [x] Can delete it
			- [x] Show the trees that were at his location
			- [x] Reassign pop units (housing, production)

- [ ] Ship (cancelled)
	- [ ] Add new ship
	- [ ] Pick randomly either ship

- [x] Population
	- [x] Properly assign to production building when debarking
	- [x] Properly assign to housing building when debarking
	- [x] Find and assign housing building when constructing one

- [x] Fixes
	- [x] Buildings are constructible inside cliffs
		- the script was just wrong
	- [x] Buildings disappear sometimes when near the water when we position them
		- goshapes wall were still in the wrong physics layer
	- [x] Population in the UI are wrong
		- We need: capacity, current population, workers needed, current workers
	- [x] Production system was not working: correctly produce level 1 resources
