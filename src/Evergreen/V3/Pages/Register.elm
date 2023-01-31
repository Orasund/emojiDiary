module Evergreen.V3.Pages.Register exposing (..)

import Evergreen.V3.Api.Data
import Evergreen.V3.Data.User


type alias Model =
    { user : Evergreen.V3.Api.Data.Data Evergreen.V3.Data.User.UserInfo
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
    | GotUser (Evergreen.V3.Api.Data.Data Evergreen.V3.Data.User.UserInfo)
