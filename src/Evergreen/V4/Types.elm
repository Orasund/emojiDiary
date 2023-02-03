module Evergreen.V4.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Evergreen.V4.Bridge
import Evergreen.V4.Data.Date
import Evergreen.V4.Data.Entry
import Evergreen.V4.Data.Store
import Evergreen.V4.Data.Tracker
import Evergreen.V4.Data.User
import Evergreen.V4.Gen.Pages
import Evergreen.V4.Shared
import Lamdera
import Time
import Url


type alias FrontendModel =
    { url : Url.Url
    , key : Browser.Navigation.Key
    , shared : Evergreen.V4.Shared.Model
    , pages : Dict.Dict String Evergreen.V4.Gen.Pages.Model
    , page : String
    }


type alias Session =
    { userId : Evergreen.V4.Data.Store.Id Evergreen.V4.Data.User.UserFull
    , expires : Time.Posix
    }


type alias BackendModel =
    { sessions : Dict.Dict Lamdera.SessionId Session
    , users : Evergreen.V4.Data.Store.Store Evergreen.V4.Data.User.UserFull
    , trackers : Evergreen.V4.Data.Store.Store Evergreen.V4.Data.Tracker.Tracker
    , usernames : Dict.Dict String (Evergreen.V4.Data.Store.Id Evergreen.V4.Data.User.UserFull)
    , drafts : Dict.Dict Evergreen.V4.Data.User.UserId ( Time.Posix, Time.Zone, Evergreen.V4.Data.Entry.EntryContent )
    , entries : Dict.Dict Evergreen.V4.Data.User.UserId (Dict.Dict Evergreen.V4.Data.Date.DateTriple Evergreen.V4.Data.Entry.EntryContent)
    , following : Dict.Dict Evergreen.V4.Data.User.UserId (List (Evergreen.V4.Data.Store.Id Evergreen.V4.Data.User.UserFull))
    , hour : Time.Posix
    }


type FrontendMsg
    = ChangedUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | Shared Evergreen.V4.Shared.Msg
    | Page Evergreen.V4.Gen.Pages.Msg
    | Noop


type alias ToBackend =
    Evergreen.V4.Bridge.ToBackend


type BackendMsg
    = CheckSession Lamdera.SessionId Lamdera.ClientId
    | RenewSession (Evergreen.V4.Data.Store.Id Evergreen.V4.Data.User.UserFull) Lamdera.SessionId Lamdera.ClientId Time.Posix
    | HourPassed Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = ActiveSession Evergreen.V4.Data.User.UserInfo
    | PageMsg Evergreen.V4.Gen.Pages.Msg
    | SharedMsg Evergreen.V4.Shared.Msg
    | NoOpToFrontend
