module Evergreen.V4.Pages.Settings exposing (..)

import Evergreen.V4.Api.Data
import Evergreen.V4.Data.User


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
    | SubmittedForm Evergreen.V4.Data.User.UserInfo
    | GotUser (Evergreen.V4.Api.Data.Data Evergreen.V4.Data.User.UserInfo)
