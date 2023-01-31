module Evergreen.V3.Types exposing (..)

import Browser
import Browser.Navigation
import Dict
import Evergreen.V3.Bridge
import Evergreen.V3.Data.Date
import Evergreen.V3.Data.Entry
import Evergreen.V3.Data.Store
import Evergreen.V3.Data.Tracker
import Evergreen.V3.Data.User
import Evergreen.V3.Gen.Pages
import Evergreen.V3.Shared
import Lamdera
import Time
import Url


type alias FrontendModel =
    { url : Url.Url
    , key : Browser.Navigation.Key
    , shared : Evergreen.V3.Shared.Model
    , pages : Dict.Dict String Evergreen.V3.Gen.Pages.Model
    , page : String
    }


type alias Session =
    { userId : Evergreen.V3.Data.Store.Id Evergreen.V3.Data.User.UserFull
    , expires : Time.Posix
    }


type alias BackendModel =
    { sessions : Dict.Dict Lamdera.SessionId Session
    , users : Evergreen.V3.Data.Store.Store Evergreen.V3.Data.User.UserFull
    , trackers : Evergreen.V3.Data.Store.Store Evergreen.V3.Data.Tracker.Tracker
    , usernames : Dict.Dict String (Evergreen.V3.Data.Store.Id Evergreen.V3.Data.User.UserFull)
    , drafts : Dict.Dict Evergreen.V3.Data.User.UserId ( Time.Posix, Time.Zone, Evergreen.V3.Data.Entry.EntryContent )
    , entries : Dict.Dict Evergreen.V3.Data.User.UserId (Dict.Dict Evergreen.V3.Data.Date.DateTriple Evergreen.V3.Data.Entry.EntryContent)
    , following : Dict.Dict Evergreen.V3.Data.User.UserId (List (Evergreen.V3.Data.Store.Id Evergreen.V3.Data.User.UserFull))
    , hour : Time.Posix
    }


type FrontendMsg
    = ChangedUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | Shared Evergreen.V3.Shared.Msg
    | Page Evergreen.V3.Gen.Pages.Msg
    | Noop


type alias ToBackend =
    Evergreen.V3.Bridge.ToBackend


type BackendMsg
    = CheckSession Lamdera.SessionId Lamdera.ClientId
    | RenewSession (Evergreen.V3.Data.Store.Id Evergreen.V3.Data.User.UserFull) Lamdera.SessionId Lamdera.ClientId Time.Posix
    | HourPassed Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = ActiveSession Evergreen.V3.Data.User.UserInfo
    | PageMsg Evergreen.V3.Gen.Pages.Msg
    | SharedMsg Evergreen.V3.Shared.Msg
    | NoOpToFrontend
