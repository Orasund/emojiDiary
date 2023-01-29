module Types exposing (..)

import Bridge
import Browser
import Browser.Navigation exposing (Key)
import Data.Date exposing (DateTriple)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id, Store)
import Data.Tracker exposing (Tracker)
import Data.User exposing (UserFull, UserId, UserInfo)
import Dict exposing (Dict)
import Gen.Pages as Pages
import Lamdera exposing (ClientId, SessionId)
import Shared
import Time exposing (Posix, Zone)
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
    , drafts : Dict UserId ( Posix, Zone, EntryContent )
    , entries : Dict UserId (Dict DateTriple EntryContent)
    , following : Dict UserId (List (Id UserFull))
    , hour : Posix
    }


type alias Session =
    { userId : Id UserFull, expires : Posix }


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
    = ActiveSession UserInfo
    | PageMsg Pages.Msg
    | SharedMsg Shared.Msg
    | NoOpToFrontend
