{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE ScopedTypeVariables   #-}

module Server.APIServer where

import Control.Concurrent.STM
import Control.Monad.IO.Class
import Control.Monad.State (gets)
import Control.Monad.Trans.Class
import Data.ByteString (ByteString)
import qualified Data.Map as Map
import Data.Maybe (listToMaybe)
import Data.Monoid ((<>))
import Data.Proxy
import Data.Text
import Data.Text.Encoding (encodeUtf8)
import Data.UUID.V4
import Database.PostgreSQL.Simple.Types
import Network.WebSockets
import Network.WebSockets.Snap
import Servant.API
import Servant.Server
import Snap.Core
import Snap.Snaplet
import Snap.Snaplet.Auth
import Snap.Snaplet.PostgresqlSimple
import API
import EntityID
import Worker
import Permissions
import User
import Server.Application
import Server.Crud
import Browser
import Job
import WebSocketServer

------------------------------------------------------------------------------
-- | Top-level API server implementation
serverAPI :: Server API1 AppHandler
serverAPI = serverAuth
       :<|> listOnlineWorkers
       :<|> callfun
       :<|> serveBrowserWS
       :<|> serveWorkerWS


serverAuth :: Server UserAPI AppHandler
serverAuth =
  let loginServer li = with auth $ do
        u <- loginByUsername (_liUsername li)
                             (ClearText . encodeUtf8 $ _liPassword li)
                             (_liRemember li)
        either (error "login error") return u

      registerServer ri = with auth $ do
        u <- createUser (_riUsername ri) (encodeUtf8 (_riPassword ri))
        either (error "Registration error") return u

      currentUserServer = with auth currentUser

      logoutServer = with auth logout

  in loginServer :<|> registerServer :<|> currentUserServer :<|> logoutServer


crudServer :: forall v.Crud v => Proxy v -> Server (CrudAPI (EntityID v) v) AppHandler
crudServer p =
  let getAll   = query_ (getAllQuery p)

      get i    = do
        rs <- query (getOneQuery p) (Only i)
        case rs of
          [r] -> return r
          _        -> error "Get failure"

      post v   = do
        rs <- query (postQuery p) v
        case rs of
          [Only r] -> return r
          _   -> error "Post failure"

      put i v  = do
        rs <- query (putQuery p) (i :. v)
        case rs of
          [Only b] -> return b
          _        -> error "Put error"

      delete i = do
        n <- query (deleteQuery p) (Only i)
        case n of
          [Only (1 :: Int)] -> return True
          _        -> error "Delete error"

  in getAll :<|> get :<|> post :<|> put :<|> delete

listOnlineWorkers :: Server (Get '[JSON] WorkerProfileMap) AppHandler
listOnlineWorkers = do
  wrks <- liftIO . atomically . readTVar =<< gets _workers
  return (EntityMap $ Map.map _wProfile wrks)

callfun
  :: Server (QueryParam "worker-id" (EntityID WorkerProfile)
             :> QueryParam "browser-id" (EntityID Browser)
             :> ReqBody '[JSON] Job
             :> Post '[JSON] (EntityID Job)) AppHandler
callfun (Just wID :: Maybe (EntityID WorkerProfile)) bID job = do
  wrks :: Map.Map (EntityID WorkerProfile) Worker <-
    liftIO . atomically . readTVar =<< gets _workers
  case Map.lookup wID wrks of
    Nothing                  -> liftIO (print "No match") >> pass
    (Just w :: Maybe Worker) -> do
      jID  <- EntityID <$> liftIO nextRandom
      liftIO $ atomically $ writeTChan (_wJobQueue w) (jID, bID, job)
      return jID

serveBrowserWS :: Server Raw AppHandler
serveBrowserWS = do
  brs <- gets _browsers
  wks <- gets _workers
  -- runWebSocketsSnapWith myOpts $ \pending -> runBrowser pending brs wks
  runWebSocketsSnap $ \pending -> runBrowser pending brs wks
    where myOpts = ConnectionOptions (print "SERVE BROWSER PONG!")

serveWorkerWS :: Maybe WorkerName -> Maybe Text -> [Text] -> AppHandler ()
serveWorkerWS (Just wName) (Just fName) tags = do
  liftIO $ print "We hit the right endpoint"
  brs     <- gets _browsers
  wks     <- gets _workers
  results <- gets _rqueue
  liftIO $ print "ServeWorker: about to runWebSockets"
  --runWebSocketsSnapWith (ConnectionOptions myOnPong) $ \pending -> do
  runWebSocketsSnap $ \pending -> do
    print "Running"
    runWorker pending (WorkerProfile wName fName tags) wks brs results
      where myOnPong = print "SERVE WORKER PONG!"
serveWorkerWS Nothing _ _ = do
  liftIO $ print "No name"
  writeBS "Please give a worker-name parameter"
serveWorkerWS _ Nothing _ = do
  liftIO $ print "No function"
  writeBS "Please give a function-name parameter"
