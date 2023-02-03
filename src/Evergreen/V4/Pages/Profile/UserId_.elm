module Evergreen.V4.Pages.Profile.UserId_ exposing (..)

import Evergreen.V4.Api.Data
import Evergreen.V4.Data.Date
import Evergreen.V4.Data.Entry
import Evergreen.V4.Data.User


type alias Model =
    { profile : Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.Profile
    , entries : List ( Evergreen.V4.Data.Date.Date, Evergreen.V4.Data.Entry.EntryContent )
    , page : Int
    }


type Msg
    = GotProfile (Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.Profile)
    | GotEntries (List ( Evergreen.V4.Data.Date.Date, Evergreen.V4.Data.Entry.EntryContent ))
    | ToggleFollowing
