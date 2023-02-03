module Evergreen.V4.Pages.Register exposing (..)

import Evergreen.V4.Api.Data
import Evergreen.V4.Data.User


type alias Model =
    { user : Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.UserInfo
    , username : String
    , email : String
    , password : String
    , password2 : String
    }


type Field
    = Username
    | Password
    | Password2


type Msg
    = Updated Field String
    | AttemptedSignUp
    | GotUser (Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.UserInfo)
