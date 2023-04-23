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

## Struggles
- Hard to get started; finding a suitable gui library, installing it, understanding how all of it works, etc. 
    - Tried Threepenny, which at first seemed great. It uses web browser to display the ui. Building a game this way using Haskell didn't seem that great of an idea.
    - After searching for quite a bit, looking at different gui libraries, I stumbled on a reddit post, which suggested that most gui applications are built with gtk. Decided to try it.
    - Getting a simple Hello world GUI example to run has been a pain.
- Why do these kinds of errors even exists:
    - Couldn't match expected type ‘GHC.Int.Int32’ with actual type ‘Int’
        - using `fromIntegral i` resolves the problem, but why?
- Relying on imperative indexed for loops.
    - When creating the grid, how to attach each button to a position without knowing the index of it