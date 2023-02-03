module Evergreen.V4.Data.User exposing (..)

import Evergreen.V4.Data.Store
import Evergreen.V4.Data.Tracker


type alias UserFull =
    { username : String
    , bio : Maybe String
    , image : String
    , passwordHash : String
    , trackers : List (Evergreen.V4.Data.Store.Id Evergreen.V4.Data.Tracker.Tracker)
    }


type alias UserInfo =
    { id : Evergreen.V4.Data.Store.Id UserFull
    , username : String
    , image : String
    }


type alias Profile =
    { id : Evergreen.V4.Data.Store.Id UserFull
    , username : String
    , bio : Maybe String
    , image : String
    , following : Bool
    }


type alias UserId =
    Int
