{-# language GADTs #-}
{-# language FlexibleContexts #-}
{-# language RecursiveDo #-}
{-# language LambdaCase  #-}
{-# language RankNTypes  #-}
{-# language OverloadedStrings  #-}
{-# language ScopedTypeVariables  #-}

module Frontend.Function where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Fix (MonadFix)
import qualified Data.Aeson as A
import qualified Data.ByteString.Char8 as BS
import qualified Data.ByteString.Lazy.Char8 as BSL
import qualified Data.Foldable as F
import Data.List (foldl', isInfixOf)
import qualified Data.Map as Map
import Data.Monoid
import qualified Data.Text as T
import Reflex
import Reflex.Dom
import Reflex.Dom.WebSocket
import Message
import Model
import RemoteFunction
import WorkerProfile
import BrowserProfile
import EntityID


------------------------------------------------------------------------------
-- | FunctionWidget shows profile information for a function,
--   and editing controls when the viewer has editing rights
data FunctionWidget t = FunctionWidget
  { _functionWidget_profile :: Dynamic t Function }

functionWidget :: (DomBuilder t m, DomBuilderSpace m ~ GhcjsDomSpace, PostBuild t m) => FunctionWidget t -> m ()
functionWidget f = do
  d <- dyn =<< mapDyn functionDetails (_functionWidget_profile f)
  return ()
  where functionDetails fun =
          elClass "div" "function-widget" $ do
            el "div" (text $ fnName fun)
            el "div" (text . T.pack . show $ fnType fun)
            mapM_ (elClass "div" "tag" . text . T.pack . show) (fnTags fun)


------------------------------------------------------------------------------
-- | A list of functions meant to update with typing in the search box
functionListing :: forall t m .(DomBuilder t m, DomBuilderSpace m ~ GhcjsDomSpace, MonadFix m,MonadHold t m, PostBuild t m)
                => Dynamic t (Map.Map T.Text Function)
                -> Dynamic t T.Text
                -- TODO: change Function to FunctionInfo
                --       FunctionInfo might list tags,
                --       usage history, nWorkers implementing, etc
                -> m (Event t T.Text)
functionListing functions sel = mdo
  searchbox <- value <$> elClass "div" "search-box" (textInput def)
  funPredicate :: Dynamic t (T.Text -> Function -> Bool) <- mapDyn funListPredicate searchbox
  okFuns <- combineDyn Map.filterWithKey funPredicate functions

  listing <- selectViewListWithKey_ curSelect okFuns $ \k v b -> do
    divAttrs <- forDyn b $ \case
      False -> "class" =: "function-entry"
      True  -> "class" =: "function-entry selected" <>
               "style" =: "background-color:gray" -- TODO only use class & css file
    (e,_) <- elDynAttr' "div" divAttrs (functionWidget (FunctionWidget v))
    return (k <$ domEvent Click e)

  curSelect <- holdDyn T.empty listing
  return $ updated curSelect

 -- TODO: more customizations
funListPredicate :: T.Text -> T.Text -> v -> Bool
funListPredicate s k v
  | T.null s  = False
  | otherwise = s `T.isInfixOf` k


------------------------------------------------------------------------------
-- | Page-level coordination of function-related widgets
functionPage :: forall t m.(DomBuilder t m, HasWebView (Performable m), MonadHold t m, MonadIO m, MonadIO (Performable m), MonadFix m, TriggerEvent t m, PerformEvent t m, PostBuild t m, HasWebView m) => m ()
functionPage = mdo
  pb <- getPostBuild
  ws <- webSocket "/api1/browse" (WebSocketConfig wsSends)
  let msg = decoded (_webSocket_recv ws)
  let x  = msg :: Event t BrowserMessage

  wsSends <- return never -- TODO Send data sometimes?

  browserId <- holdDyn Nothing $ ffor msg $ \case
    SetBrowserID i -> Just i
    _              -> Nothing

  workers0 :: Event t WorkerProfileMap <- fmapMaybe id <$> getAndDecode ("/api1/worker" <$ pb)
  let workersInit :: Event t (WorkerProfileMap -> WorkerProfileMap) = ffor workers0 $ \(EntityMap ws) -> const . EntityMap $
        foldl' (\m (k,v) -> Map.insert k v m) mempty (Map.toList ws)

  let workersModify :: Event t (WorkerProfileMap -> WorkerProfileMap) = fforMaybe msg $ \case
        WorkerJoined wId wProfile -> Just (EntityMap . Map.insert wId wProfile . unEntityMap)
        WorkerLeft wId            -> Just (EntityMap . Map.delete wId . unEntityMap)

  workers :: Dynamic t WorkerProfileMap <- foldDyn ($) (EntityMap mempty) (leftmost [workersInit, workersModify])
  nWorkers :: Dynamic t Int <- mapDyn (F.length . unEntityMap) workers

  -- elClass "div" "function-page" $ do
  --   functionListing workers (constDyn 0)

  return ()

type WMap = Map.Map WorkerProfileId WorkerProfile

decoded :: (Reflex t, A.FromJSON a)
                   => Event t BS.ByteString
                   -> Event t a
decoded = fmapMaybe (A.decode . BSL.fromStrict)
