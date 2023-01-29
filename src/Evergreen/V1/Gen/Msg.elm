module Evergreen.V1.Gen.Msg exposing (..)

import Evergreen.V1.Pages.Home_
import Evergreen.V1.Pages.Login
import Evergreen.V1.Pages.Profile.UserId_
import Evergreen.V1.Pages.Register
import Evergreen.V1.Pages.Settings


type Msg
    = Home_ Evergreen.V1.Pages.Home_.Msg
    | Login Evergreen.V1.Pages.Login.Msg
    | Register Evergreen.V1.Pages.Register.Msg
    | Settings Evergreen.V1.Pages.Settings.Msg
    | Profile__UserId_ Evergreen.V1.Pages.Profile.UserId_.Msg
