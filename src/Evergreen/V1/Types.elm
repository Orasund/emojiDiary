module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Evergreen.V1.Bridge
import Evergreen.V1.Data.Date
import Evergreen.V1.Data.Entry
import Evergreen.V1.Data.Store
import Evergreen.V1.Data.Tracker
import Evergreen.V1.Data.User
import Evergreen.V1.Gen.Pages
import Evergreen.V1.Shared
import Lamdera
import Time
import Url


type alias FrontendModel =
    { url : Url.Url
    , key : Browser.Navigation.Key
    , shared : Evergreen.V1.Shared.Model
    , pages : Dict.Dict String Evergreen.V1.Gen.Pages.Model
    , page : String
    }


type alias Session =
    { userId : Evergreen.V1.Data.Store.Id Evergreen.V1.Data.User.UserFull
    , expires : Time.Posix
    }


type alias BackendModel =
    { sessions : Dict.Dict Lamdera.SessionId Session
    , users : Evergreen.V1.Data.Store.Store Evergreen.V1.Data.User.UserFull
    , trackers : Evergreen.V1.Data.Store.Store Evergreen.V1.Data.Tracker.Tracker
    , usernames : Dict.Dict String (Evergreen.V1.Data.Store.Id Evergreen.V1.Data.User.UserFull)
    , drafts : Dict.Dict Evergreen.V1.Data.User.UserId ( Time.Posix, Time.Zone, Evergreen.V1.Data.Entry.EntryContent )
    , entries : Dict.Dict Evergreen.V1.Data.User.UserId (Dict.Dict Evergreen.V1.Data.Date.DateTriple Evergreen.V1.Data.Entry.EntryContent)
    , following : Dict.Dict Evergreen.V1.Data.User.UserId (List (Evergreen.V1.Data.Store.Id Evergreen.V1.Data.User.UserFull))
    , hour : Time.Posix
    }


type FrontendMsg
    = ChangedUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | Shared Evergreen.V1.Shared.Msg
    | Page Evergreen.V1.Gen.Pages.Msg
    | Noop


type alias ToBackend =
    Evergreen.V1.Bridge.ToBackend


type BackendMsg
    = CheckSession Lamdera.SessionId Lamdera.ClientId
    | RenewSession (Evergreen.V1.Data.Store.Id Evergreen.V1.Data.User.UserFull) Lamdera.SessionId Lamdera.ClientId Time.Posix
    | HourPassed Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = ActiveSession Evergreen.V1.Data.User.UserInfo
    | PageMsg Evergreen.V1.Gen.Pages.Msg
    | SharedMsg Evergreen.V1.Shared.Msg
    | NoOpToFrontend
