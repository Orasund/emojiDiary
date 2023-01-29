module Evergreen.V1.Pages.Home_ exposing (..)

import Array
import Evergreen.V1.Data.Date
import Evergreen.V1.Data.Entry
import Evergreen.V1.Data.Store
import Evergreen.V1.Data.Tracker
import Evergreen.V1.Data.User
import Time


type alias Model =
    { page : Int
    , entryDraft : Maybe ( Time.Posix, Time.Zone, Evergreen.V1.Data.Entry.EntryContent )
    , trackers : Array.Array ( Evergreen.V1.Data.Store.Id Evergreen.V1.Data.Tracker.Tracker, Evergreen.V1.Data.Tracker.Tracker )
    , entries : List ( Evergreen.V1.Data.User.UserInfo, Evergreen.V1.Data.Date.Date, Evergreen.V1.Data.Entry.EntryContent )
    , focusedTracker : Maybe Int
    , time : Maybe Time.Posix
    }


type Msg
    = UpdatedEntries
    | GotEntries (List ( Evergreen.V1.Data.User.UserInfo, Evergreen.V1.Data.Date.Date, Evergreen.V1.Data.Entry.EntryContent ))
    | UpdatedDraft Evergreen.V1.Data.Entry.EntryContent
    | CreatedDraft (Maybe ( Time.Posix, Time.Zone, Evergreen.V1.Data.Entry.EntryContent ))
    | FinishedUpdatingDraft
    | PublishDraft
    | GotTrackers (List ( Evergreen.V1.Data.Store.Id Evergreen.V1.Data.Tracker.Tracker, Evergreen.V1.Data.Tracker.Tracker ))
    | AddedTracker String
    | DeletedTracker (Evergreen.V1.Data.Store.Id Evergreen.V1.Data.Tracker.Tracker)
    | EditedTracker ( Int, Evergreen.V1.Data.Tracker.Tracker )
    | FinishedEditingTracker Int
    | GotTime Time.Posix
