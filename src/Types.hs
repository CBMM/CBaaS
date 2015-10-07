{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DeriveGeneric #-}

module Types where

------------------------------------------------------------------------------
import           Control.Monad (mzero)
import qualified Data.Aeson    as A
import           Data.Aeson    ((.:), (.=), ToJSON(..), FromJSON(..))
import           Data.Text     (Text, pack, unpack)
import qualified Data.UUID     as UUID
import           Data.UUID     (UUID, fromText, toText)
import           Database.PostgreSQL.Simple
import           Database.PostgreSQL.Simple.ToRow
import           Database.PostgreSQL.Simple.FromRow
import           Database.PostgreSQL.Simple.ToField
import           Database.PostgreSQL.Simple.FromField
import           GHC.Generics


------------------------------------------------------------------------------
-- | A type wrapper for Entity ID tags. We wrap the UUID in our own type
--   so that we can manually define how to convert id's into JSON data
newtype EntityID = EntityID { unID :: UUID }
  deriving (Show, Eq, Ord)


------------------------------------------------------------------------------
-- | Pointer to a stimulus resource somewhere on the web
--   We include an ID tag for referencing this stimulus from feature vectors
--   derived from it. Mime type is provided as a sanity check and to allow
--   clients to avoid downloading certain stimulus types if needed
data StimulusResource = StimulusResource
  { _srId   :: EntityID
  , _srUrl  :: ResourceURL
  , _srMime :: ResourceMedia
  } deriving (Show, Eq, Ord, Generic)

------------------------------------------------------------------------------
-- | Feature data, completely open-ended (any JSON data), but tagged with an
--   ID and metadata
data Features = Features
  { _featuresId   :: EntityID
  , _featuresMeta :: A.Value
  , _featuresData :: A.Value
  } deriving (Show, Eq, Generic)

data User = User
  { _uLogin :: Int
  , _uEmail :: Text
  } deriving (Show, Eq, Generic)

data LoginInfo = LoginInfo
  { _liUsername :: Text
  , _liPassword :: Text
  , _liRemember :: Bool
  } deriving (Eq, Show, Generic)

instance ToJSON   LoginInfo where
instance FromJSON LoginInfo where


data RegisterInfo = RegisterInfo
  { _riUsername :: Text
  , _riPassword :: Text
  } deriving (Eq, Show, Generic)

instance ToJSON   RegisterInfo where
instance FromJSON RegisterInfo where


------------------------------------------------------------------------------
-- | Convert an ID to JSON. Construct a JSON String value from the
--   textual representation of the UUID
instance ToJSON EntityID where
  toJSON (EntityID u) = A.String (toText u)


------------------------------------------------------------------------------
-- | Convert a JSON string into an ID. On successful parsing of the UUID's
--   string, return our wrapped ID type. If string parsing fails or ther
--   JSON type was not a string, ID parsing fails (`mzero`)
instance FromJSON EntityID where
  parseJSON (A.String s) = case UUID.fromText s of
    Nothing -> mzero
    Just i  -> return (EntityID i)
  parseJSON _ = mzero

instance ToJSON   StimulusResource where
instance FromJSON StimulusResource where

instance ToJSON   Features where
instance FromJSON Features where

instance ToJSON   User where
instance FromJSON User where

instance ToField EntityID where
  toField (EntityID i) = toField i

instance ToRow StimulusResource where
  toRow (StimulusResource i u m) = [toField i, toField u, toField m]

instance ToRow Features where
  toRow (Features i m d) = [toField i, toField m, toField d]



------------------------------------------------------------------------------
-- | Custom wrapper around a mime-type, allowing us to define interactions
--   with type classes
newtype ResourceMedia = ResourceMedia { unMedia :: Text }
  deriving (Eq, Ord, Show, ToJSON, FromJSON)


------------------------------------------------------------------------------
-- | Custom wrapper around a URL, allowing us to define interactions
--   with type classes
newtype ResourceURL = ResourceURL { unURL :: Text }
  deriving (Eq, Ord, Show, ToJSON, FromJSON)

instance ToField ResourceURL where
  toField (ResourceURL u) = toField u

instance ToField ResourceMedia where
  toField (ResourceMedia m) = toField m
