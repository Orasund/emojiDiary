module Bridge exposing (..)

import Api.User exposing (User, UserFull, UserId)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Lamdera


sendToBackend =
    Lamdera.sendToBackend


type HomeToBackend
    = DraftUpdated EntryContent
    | GetEntriesOfSubscribed
    | GetDraft
    | GetTrackers
    | AddTracker String
    | RemoveTracker (Id Tracker)


type ProfileToBackend
    = GetEntriesOfProfile
    | ToggleSubscription


type ToBackend
    = SignedOut User
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
