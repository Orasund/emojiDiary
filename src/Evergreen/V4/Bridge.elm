module Evergreen.V4.Bridge exposing (..)

import Evergreen.V4.Data.Entry
import Evergreen.V4.Data.Store
import Evergreen.V4.Data.Tracker
import Evergreen.V4.Data.User
import Time


type ProfileToBackend
    = GetEntriesOfProfile
    | ToggleSubscription


type HomeToBackend
    = DraftUpdated (Maybe ( Maybe Time.Posix, Time.Zone, Evergreen.V4.Data.Entry.EntryContent ))
    | GetEntriesOfSubscribed
    | GetDraft Time.Zone
    | GetTrackers
    | AddTracker String
    | RemoveTracker (Evergreen.V4.Data.Store.Id Evergreen.V4.Data.Tracker.Tracker)
    | EditTracker ( Evergreen.V4.Data.Store.Id Evergreen.V4.Data.Tracker.Tracker, Evergreen.V4.Data.Tracker.Tracker )
    | PublishDraft


type ToBackend
    = SignedOut Evergreen.V4.Data.User.UserInfo
    | ProfileGet_Profile__Username_
        { username : String
        }
    | UserAuthentication_Login
        { params :
            { username : String
            , password : String
            }
        }
    | UserRegistration_Register
        { params :
            { username : String
            , email : String
            , password : String
            }
        }
    | UserUpdate_Settings
        { params :
            { username : String
            , password : Maybe String
            , image : String
            }
        }
    | AtProfile
        { userId : Evergreen.V4.Data.Store.Id Evergreen.V4.Data.User.UserFull
        }
        ProfileToBackend
    | AtHome HomeToBackend
    | NoOpToBackend
