module Evergreen.V1.Pages.Settings exposing (..)

import Evergreen.V1.Api.Data
import Evergreen.V1.Data.User


type alias Model =
    { image : String
    , username : String
    , password : Maybe String
    , message : Maybe String
    , errors : List String
    }


type Field
    = Image
    | Username
    | Password


type Msg
    = Updated Field String
    | SubmittedForm Evergreen.V1.Data.User.UserInfo
    | GotUser (Evergreen.V1.Api.Data.Data Evergreen.V1.Data.User.UserInfo)
