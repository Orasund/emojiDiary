module Evergreen.V4.Shared exposing (..)

import Evergreen.V4.Data.User
import Time


type alias Model =
    { user : Maybe Evergreen.V4.Data.User.UserInfo
    , error : Maybe String
    , zone : Time.Zone
    }


type Msg
    = ClickedSignOut
    | SignedInUser Evergreen.V4.Data.User.UserInfo
    | GotError String
    | GotZone Time.Zone
