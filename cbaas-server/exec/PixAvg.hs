module Main where

import Control.Lens
import Codec.Picture
import Codec.Picture.Types
import Model
import WorkerClient

main :: IO ()
main = runWorker $ \x -> do
  -- print x
  let r = compute x
  print r
  return r

compute :: Image PixelRGBA8 -> Int
compute i = imageWidth i * imageHeight i
