{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Monad
import Data.Array.IO
import Data.GI.Base
import Data.GI.Base.ShortPrelude (SignalHandlerId)
import qualified Data.GI.Base.Signals as Gtk
import Data.Maybe (fromJust)
import Data.Text (Text, pack)
import GI.Gtk (styleContext)
import qualified GI.Gtk as Gtk
import System.Random
import Text.Printf (printf)

main :: IO ()
main = do
  Gtk.init Nothing
  window <-
    new
      Gtk.Window
      [ #title := "Minesweeper",
        #borderWidth := 10
      ]
  on window #destroy Gtk.mainQuit
  startGame window

  Gtk.main

startGame :: Gtk.Window -> IO ()
startGame window = do
  Gtk.containerForeach window $ \child -> Gtk.containerRemove window child
  let columns = 10
  let rows = 10
  let mines = 10
  mf <- generateMinefield rows columns mines
  grid <- createGrid window mf rows columns
  #add window grid
  #showAll window

generateMinefield :: Int -> Int -> Int -> IO (IOArray Int Int)
generateMinefield rows columns mines = do
  let size = rows * columns
  mf <- newArray (0, size - 1) 0
  genMines mf size mines
  genNeighbours mf rows columns

  -- Output to console for debug and validation purposes.
  sequence_ $ do
    i <- [0 .. size - 1]
    return $ do
      value <- readArray mf i
      printf "%4d" value
      when (i `mod` columns == columns - 1) $ putChar '\n'
  return mf

-- Consider mines as the number -1.
isMine :: Int -> Bool
isMine x = x == -1

setMine :: IOArray Int Int -> Int -> IO ()
setMine mf index = do
  writeArray mf index (-1)

-- Row and column position by index and column count.
toPosition :: Int -> Int -> (Int, Int)
toPosition index columnC = (index `div` columnC, index `mod` columnC)

-- Index in an array based on the position and column count.
toIndex :: (Int, Int) -> Int -> Int
toIndex position columnC = row * columnC + column
  where
    (row, column) = position

-- In-place addition of a mine to a random position recursively.
-- If there exists a mine in a given position, try again.
addMine :: IOArray Int Int -> Int -> Int -> IO ()
-- Helper function to create a mine in a random position.
addMine mf size (-1) = do
  newPos <- randomRIO (0, size - 1)
  addMine mf size (mod newPos size)
-- Valid mine location check and recursion.
addMine mf size pos = do
  value <- readArray mf pos
  if isMine value
    then addMine mf size (-1)
    else setMine mf pos

-- Generate mines for the grid in-place using mutable arrays.
genMines :: IOArray Int Int -> Int -> Int -> IO ()
genMines mf size 0 = return ()
genMines mf size count = do
  addMine mf size (-1)
  genMines mf size (count - 1)

withinBounds :: Int -> Int -> (Int, Int) -> Bool
withinBounds rowC columnC (row, column) = row >= 0 && row < rowC && column >= 0 && column < columnC

-- Increase the value of a tile if it is not a mine. Used in conjugtion with the generate neighbours function.
increaseNeighbouringMineCount :: IOArray Int Int -> Int -> Int -> (Int, Int) -> IO ()
increaseNeighbouringMineCount mf rowC columnC position
  | not (withinBounds rowC columnC position) = return ()
  | otherwise = do
      value <- readArray mf index
      unless (isMine value) $ writeArray mf index (value + 1)
  where
    (row, column) = position
    index = toIndex position columnC

-- Loop through each tile and increment the value of the tiles that are next to a mine.
genNeighbours :: IOArray Int Int -> Int -> Int -> IO ()
genNeighbours mf rowC columnC = do
  sequence_ $ do
    i <- [0 .. (rowC * columnC - 1)]
    return $ do
      value <- readArray mf i
      when (isMine value) $ do
        let pos = toPosition i columnC
        let (row, col) = pos
        increaseNeighbouringMineCount mf rowC columnC (row, col - 1) -- left
        increaseNeighbouringMineCount mf rowC columnC (row, col + 1) -- right
        increaseNeighbouringMineCount mf rowC columnC (row - 1, col) -- up
        increaseNeighbouringMineCount mf rowC columnC (row - 1, col - 1) -- up-left
        increaseNeighbouringMineCount mf rowC columnC (row - 1, col + 1) -- up-right
        increaseNeighbouringMineCount mf rowC columnC (row + 1, col) -- down
        increaseNeighbouringMineCount mf rowC columnC (row + 1, col - 1) -- down-left
        increaseNeighbouringMineCount mf rowC columnC (row + 1, col + 1) -- down-right

simulateClick :: Maybe Gtk.Widget -> IO ()
simulateClick maybeWidget = case maybeWidget of
  Just widget -> do
    button <- castTo Gtk.Button widget
    forM_ button Gtk.buttonClicked
  Nothing -> return ()

simulateClickAt :: Gtk.Grid -> Int -> Int -> (Int, Int) -> IO ()
simulateClickAt grid rowC columnC position
  | not (withinBounds rowC columnC position) = return ()
  | otherwise = do
      Gtk.gridGetChildAt grid (fromIntegral column) (fromIntegral row) >>= simulateClick
  where
    (row, column) = position

createGrid :: Gtk.Window -> IOArray Int Int -> Int -> Int -> IO Gtk.Grid
createGrid window mf rowC columnC = do
  grid <- new Gtk.Grid []

  sequence_ $ do
    i <- [0 .. (rowC * columnC) - 1]
    return $ do
      value <- readArray mf i
      button <- createButton value
      let (row, col) = toPosition i columnC
      Gtk.gridAttach grid button (fromIntegral col) (fromIntegral row) 1 1

      on button #clicked $ do
        isSensitive <- Gtk.widgetGetSensitive button
        Gtk.setWidgetSensitive button False

        when ((value == 0) && isSensitive) $ do
          simulateClickAt grid rowC columnC (row, col - 1)
          simulateClickAt grid rowC columnC (row, col + 1)
          simulateClickAt grid rowC columnC (row + 1, col)
          simulateClickAt grid rowC columnC (row + 1, col - 1)
          simulateClickAt grid rowC columnC (row + 1, col + 1)
          simulateClickAt grid rowC columnC (row - 1, col)
          simulateClickAt grid rowC columnC (row - 1, col - 1)
          simulateClickAt grid rowC columnC (row - 1, col + 1)

        when (isMine value) $ do
          dialog <- Gtk.dialogNew
          exitbutton <- Gtk.dialogAddButton dialog "Exit" 1
          tryagain <- Gtk.dialogAddButton dialog "Try Again?" 2
          response <- Gtk.dialogRun dialog
          unless (response == 2) Gtk.mainQuit
          when (response == 2) $ do
            startGame window
          #close dialog

  return grid

attachStyle :: Gtk.StyleContext -> Int -> IO ()
attachStyle styleContext (-1) = do
  Gtk.styleContextAddClass styleContext "button-mine"
attachStyle styleContext value = do
  Gtk.styleContextAddClass styleContext "button-safe"

createButton :: Int -> IO Gtk.Button
createButton value = do
  let l = if value <= 0 then pack "" else pack (show value)

  button <- new Gtk.Button [#label := l]
  Gtk.widgetSetSizeRequest button 40 40

  provider <- Gtk.cssProviderNew
  Gtk.cssProviderLoadFromPath provider "data/style.css"
  styleContext <- Gtk.widgetGetStyleContext button
  Gtk.styleContextAddProvider styleContext provider (fromIntegral Gtk.STYLE_PROVIDER_PRIORITY_USER)
  attachStyle styleContext value

  return button
