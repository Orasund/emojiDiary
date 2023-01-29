module Evergreen.V1.Pages.Login exposing (..)

import Evergreen.V1.Api.Data
import Evergreen.V1.Data.User


type alias Model =
    { user : Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.UserInfo
    , username : String
    , password : String
    }


type Field
    = Username
    | Password


type Msg
    = Updated Field String
    | AttemptedSignIn
    | GotUser (Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.UserInfo)
