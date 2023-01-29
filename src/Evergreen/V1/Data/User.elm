module Evergreen.V1.Data.User exposing (..)

import Evergreen.V1.Data.Store
import Evergreen.V1.Data.Tracker


type alias UserFull =
    { username : String
    , bio : Maybe String
    , image : String
    , password : String
    , trackers : List (Evergreen.V1.Data.Store.Id Evergreen.V1.Data.Tracker.Tracker)
    }


type alias UserInfo =
    { id : Evergreen.V1.Data.Store.Id UserFull
    , username : String
    , image : String
    }


type alias Profile =
    { id : Evergreen.V1.Data.Store.Id UserFull
    , username : String
    , bio : Maybe String
    , image : String
    , following : Bool
    }


type alias UserId =
    Int
