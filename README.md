## Pokemon Mystery Dungeon: Explorers of Sky but even more Roguelike!

Hello! This is a very WIP Pokemon Mystery Dungeon fangame being made in Godot. This readme serves to help with setting up asset fetching. I recommend performing the following steps all in your shell program of choice.

- After navigating to this repo's base directory, make your assets directory using `mkdir assets`, then `cd assets` to get into the new directory.
- Create a new submodule in this directory using `git submodule init`, then add our asset repo to this submodule using `git remote add origin -f https://github.com/PMDCollab/RawAsset`. 
    - Do NOT fetch the contents of the repo yet. 
    - This command will take a while to execute since the repo is big, but our end goal is for Godot not to have to export ~350,000 (at the time of writing!!) spritesheets and other files.
- Setup sparse checkout for this repo using `git sparse-checkout init`. At this point, you've done all the steps you need to in the shell.
- Since the project is very early in development (started November 19, 2025!!), the methods of calling the `fetch_assets.sh` script in-editor are very very subject to change. But at the moment, you can do the following:
    - In a `Pokemon` resource, pressing the "Fetch Assets" tool button in the editor will fetch the Sprite assets of a Pokemon by their `dex_number`. It also initializes `FormDefinition`s for each of the Pokemon's forms that we found sprites for.
    - In `dungeon_tile_map.tscn`, pressing the "Fetch Assets" tool button in the editor will fetch the TileDtef assets of a dungeon by their `dungeon_name`. This name must match the name of a folder in https://github.com/PMDCollab/RawAsset/tree/master/TileDtef, so refer to that.
