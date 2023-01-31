module Evergreen.V3.Pages.Settings exposing (..)

import Evergreen.V3.Api.Data
import Evergreen.V3.Data.User


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
    | SubmittedForm Evergreen.V3.Data.User.UserInfo
    | GotUser (Evergreen.V3.Api.Data.Data Evergreen.V3.Data.User.UserInfo)
