module Types exposing (..)

import Api.User exposing (User, UserFull, UserId)
import Bridge
import Browser
import Browser.Navigation exposing (Key)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id, Store)
import Data.Tracker exposing (Tracker)
import Dict exposing (Dict)
import Gen.Pages as Pages
import Lamdera exposing (ClientId, SessionId)
import Shared
import Time
import Url exposing (Url)


type alias FrontendModel =
    { url : Url
    , key : Key
    , shared : Shared.Model
    , page : Pages.Model
    }


type alias BackendModel =
    { sessions : Dict SessionId Session
    , users : Store UserFull
    , trackers : Store Tracker
    , usernames : Dict String (Id UserFull)
    , drafts : Dict UserId ( Time.Posix, EntryContent )
    , entries : Dict UserId (Dict Int EntryContent)
    , following : Dict UserId (List (Id UserFull))
    , hour : Time.Posix
    }


type alias Session =
    { userId : Id UserFull, expires : Time.Posix }


type FrontendMsg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | Shared Shared.Msg
    | Page Pages.Msg
    | Noop


type alias ToBackend =
    Bridge.ToBackend


type BackendMsg
    = CheckSession SessionId ClientId
    | RenewSession (Id UserFull) SessionId ClientId Time.Posix
    | HourPassed Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = ActiveSession User
    | PageMsg Pages.Msg
    | SharedMsg Shared.Msg
    | NoOpToFrontend
