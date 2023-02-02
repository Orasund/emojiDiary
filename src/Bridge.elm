module Bridge exposing (..)

import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Data.User exposing (UserFull, UserInfo)
import Lamdera
import Time exposing (Posix, Zone)


sendToBackend =
    Lamdera.sendToBackend


type HomeToBackend
    = DraftUpdated (Maybe ( Maybe Posix, Zone, EntryContent ))
    | GetEntriesOfSubscribed
    | GetDraft Zone
    | GetTrackers
    | AddTracker String
    | RemoveTracker (Id Tracker)
    | EditTracker ( Id Tracker, Tracker )
    | PublishDraft


type ProfileToBackend
    = GetEntriesOfProfile
    | ToggleSubscription


type ToBackend
    = SignedOut UserInfo
      -- Req/resp paired messages
    | ProfileGet_Profile__Username_ { username : String }
    | UserAuthentication_Login { params : { username : String, password : String } }
    | UserRegistration_Register { params : { username : String, email : String, password : String } }
    | UserUpdate_Settings
        { params :
            { username : String
            , password : Maybe String
            , image : String
            }
        }
    | AtProfile { userId : Id UserFull } ProfileToBackend
    | AtHome HomeToBackend
    | NoOpToBackend
