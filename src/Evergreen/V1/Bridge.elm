module Evergreen.V1.Bridge exposing (..)

import Evergreen.V1.Data.Entry
import Evergreen.V1.Data.Store
import Evergreen.V1.Data.Tracker
import Evergreen.V1.Data.User
import Time


type ProfileToBackend
    = GetEntriesOfProfile
    | ToggleSubscription


type HomeToBackend
    = DraftUpdated (Maybe ( Time.Zone, Evergreen.V1.Data.Entry.EntryContent ))
    | GetEntriesOfSubscribed
    | GetDraft
    | GetTrackers
    | AddTracker String
    | RemoveTracker (Evergreen.V1.Data.Store.Id Evergreen.V1.Data.Tracker.Tracker)
    | EditTracker ( Evergreen.V1.Data.Store.Id Evergreen.V1.Data.Tracker.Tracker, Evergreen.V1.Data.Tracker.Tracker )
    | PublishDraft


type ToBackend
    = SignedOut Evergreen.V1.Data.User.UserInfo
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
        { userId : Evergreen.V1.Data.Store.Id Evergreen.V1.Data.User.UserFull
        }
        ProfileToBackend
    | AtHome HomeToBackend
    | NoOpToBackend
