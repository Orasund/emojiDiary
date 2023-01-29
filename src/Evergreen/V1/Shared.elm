module Evergreen.V1.Shared exposing (..)

import Evergreen.V1.Data.User
import Time


type alias Model =
    { user : Maybe Evergreen.V1.Data.User.UserInfo
    , error : Maybe String
    , zone : Time.Zone
    }


type Msg
    = ClickedSignOut
    | SignedInUser Evergreen.V1.Data.User.UserInfo
    | GotError String
    | GotZone Time.Zone
