module Gen.Msg exposing (Msg(..))

import Gen.Params.Home_
import Gen.Params.Login
import Gen.Params.NotFound
import Gen.Params.Register
import Gen.Params.Settings
import Gen.Params.Profile.UserId_
import Pages.Home_
import Pages.Login
import Pages.NotFound
import Pages.Register
import Pages.Settings
import Pages.Profile.UserId_


type Msg
    = Home_ Pages.Home_.Msg
    | Login Pages.Login.Msg
    | Register Pages.Register.Msg
    | Settings Pages.Settings.Msg
    | Profile__UserId_ Pages.Profile.UserId_.Msg

