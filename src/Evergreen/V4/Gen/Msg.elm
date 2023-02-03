module Evergreen.V4.Gen.Msg exposing (..)

import Evergreen.V4.Pages.Home_
import Evergreen.V4.Pages.Login
import Evergreen.V4.Pages.Profile.UserId_
import Evergreen.V4.Pages.Register
import Evergreen.V4.Pages.Settings


type Msg
    = Home_ Evergreen.V4.Pages.Home_.Msg
    | Login Evergreen.V4.Pages.Login.Msg
    | Register Evergreen.V4.Pages.Register.Msg
    | Settings Evergreen.V4.Pages.Settings.Msg
    | Profile__UserId_ Evergreen.V4.Pages.Profile.UserId_.Msg
