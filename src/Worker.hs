{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Worker where

import Control.Concurrent
import Control.Concurrent.STM
import Control.Monad (forever, mzero)
import Data.Aeson
import qualified Data.Aeson as A
import qualified Data.Map as Map
import Data.Text hiding (map, filter)
import qualified Data.ByteString.Char8 as BS
import Data.Text.Encoding
import Data.UUID
import qualified Data.UUID as UUID
import Data.UUID.V4
import GHC.Generics
import qualified Network.WebSockets as WS
import URI.ByteString

import Job
import Model

data Worker = Worker
  { _wProfile :: WorkerProfile
  , _wID      :: WorkerID
  , _wConn    :: WS.Connection
  , _wJobQueue :: TChan Job
  } deriving (Generic)


newtype WorkerMap = WorkerMap (Map.Map WorkerID WorkerProfile)

instance ToJSON WorkerMap where
  toJSON (WorkerMap w) = toJSON $ Map.mapKeys (UUID.toText . unWorkerID) w

data WorkerProfile = WorkerProfile
  { wpName         :: WorkerName
  , wpFunctionName :: Text
  , wpTags         :: [Text]
  } deriving (Eq, Ord, Show)

instance ToJSON WorkerProfile where
  toJSON (WorkerProfile (WorkerName n) f t) =
    A.object ["name" .= n
             ,"function" .= f
             ,"tags" .= t]

------------------------------------------------------------------------------
-- Setup a worker and fork a thread for talking with a worker client process
initializeWorker :: WS.PendingConnection
                 -> WorkerProfile
                 -- ^ Worker setup info
                 -> TChan (WorkerID, JobID, Model.Val)
                 -- ^ Completion write channel
                 -> IO Worker
initializeWorker pending wp resultsChan = do
  conn     <- WS.acceptRequest pending
  i        <- WorkerID <$> nextRandom
  jobsChan <- atomically newTChan
  forkIO $ forever $ do
    job <- atomically $ readTChan jobsChan
    WS.sendTextData conn (encode job)
  return $ Worker wp i conn jobsChan

newtype WorkerID = WorkerID { unWorkerID :: UUID }
  deriving (Eq, Ord, Show)

newtype WorkerName = WorkerName { unWN :: Text }
  deriving (Eq, Ord, Show, Generic)


data JobResult = JobResult
  { jrVal    :: Model.Val
  , jrWorker :: WorkerID
  } deriving (Eq, Show)

parseWorkerProfile :: Query -> Either String WorkerProfile
parseWorkerProfile q = do
  nm <- note "No WorkerProfile name"     $ lookup "name" ps
  fn <- note "No WorkerProfile function" $ lookup "function" ps
  return $ WorkerProfile (WorkerName $ decodeUtf8 nm)
           (decodeUtf8 fn)
           (map decodeUtf8 . map snd . filter ((== "tag") . fst) $ ps)
  where ps = queryPairs q


note :: String -> Maybe a -> Either String a
note err Nothing  = Left err
note _   (Just a) = Right a
