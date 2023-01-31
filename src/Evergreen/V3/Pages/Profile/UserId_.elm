module Evergreen.V3.Pages.Profile.UserId_ exposing (..)

import Evergreen.V3.Api.Data
import Evergreen.V3.Data.Date
import Evergreen.V3.Data.Entry
import Evergreen.V3.Data.User


type alias Model =
    { profile : Evergreen.V3.Api.Data.Data Evergreen.V3.Data.User.Profile
    , entries : List ( Evergreen.V3.Data.Date.Date, Evergreen.V3.Data.Entry.EntryContent )
    , page : Int
    }


type Msg
    = GotProfile (Evergreen.V3.Api.Data.Data Evergreen.V3.Data.User.Profile)
    | GotEntries (List ( Evergreen.V3.Data.Date.Date, Evergreen.V3.Data.Entry.EntryContent ))
    | ToggleFollowing
