module Evergreen.V1.Pages.Register exposing (..)

import Evergreen.V1.Api.Data
import Evergreen.V1.Data.User


type alias Model =
    { user : Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.UserInfo
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
    | GotUser (Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.UserInfo)
