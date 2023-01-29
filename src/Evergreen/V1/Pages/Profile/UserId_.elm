module Evergreen.V1.Pages.Profile.UserId_ exposing (..)

import Evergreen.V1.Api.Data
import Evergreen.V1.Data.Date
import Evergreen.V1.Data.Entry
import Evergreen.V1.Data.User


type alias Model =
    { profile : Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.Profile
    , entries : List ( Evergreen.V1.Data.Date.Date, Evergreen.V1.Data.Entry.EntryContent )
    , page : Int
    }


type Msg
    = GotProfile (Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.Profile)
    | GotEntries (List ( Evergreen.V1.Data.Date.Date, Evergreen.V1.Data.Entry.EntryContent ))
    | ToggleFollowing
