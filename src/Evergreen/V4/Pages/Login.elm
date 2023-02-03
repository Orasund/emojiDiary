module Evergreen.V4.Pages.Login exposing (..)

import Evergreen.V4.Api.Data
import Evergreen.V4.Data.User


type alias Model =
    { user : Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.UserInfo
    , username : String
    , password : String
    }


type Field
    = Username
    | Password


type Msg
    = Updated Field String
    | AttemptedSignIn
    | GotUser (Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.UserInfo)
