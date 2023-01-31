module Evergreen.V3.Shared exposing (..)

import Evergreen.V3.Data.User
import Time


type alias Model =
    { user : Maybe Evergreen.V3.Data.User.UserInfo
    , error : Maybe String
    , zone : Time.Zone
    }


type Msg
    = ClickedSignOut
    | SignedInUser Evergreen.V3.Data.User.UserInfo
    | GotError String
    | GotZone Time.Zone
