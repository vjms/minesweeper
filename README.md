# Minesweeper
An exercise for the course Programming Paradigms in Practice at the University of Turku; Using a non-mainstream language, implement a game, and document the process.

## How to Play
1. Install Gtk and dependencies using pacman and msys2 (Windows):
```
pacman -S -q --noconfirm git mingw64/mingw-w64-x86_64-pkg-config mingw64/mingw-w64-x86_64-gobject-introspection mingw64/mingw-w64-x86_64-gtksourceview5 mingw64/mingw-w64-x86_64-gtk4 mingw64/mingw-w64-x86_64-atk
```
2. Start the application with: 
```
cabal v2-run
```
3. Enjoy


## Plan
1. Generate "the grid"
    - Grid size
    - Random locations for each mine (point x y on the grid), do not place two mines at the same location.
2. Generate some UI
3. When pressed on some tile, check the mine locations and see if we hit one or not. 
    - If we hit, then game over
    - If we didn't, calculate how many mines are neighbouring the tile.
    - "Open" the field and show the state.
