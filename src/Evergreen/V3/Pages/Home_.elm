module Evergreen.V3.Pages.Home_ exposing (..)

import Array
import Evergreen.V3.Data.Date
import Evergreen.V3.Data.Entry
import Evergreen.V3.Data.Store
import Evergreen.V3.Data.Tracker
import Evergreen.V3.Data.User
import Time


type alias Model =
    { page : Int
    , entryDraft : Maybe ( Time.Posix, Time.Zone, Evergreen.V3.Data.Entry.EntryContent )
    , trackers : Array.Array ( Evergreen.V3.Data.Store.Id Evergreen.V3.Data.Tracker.Tracker, Evergreen.V3.Data.Tracker.Tracker )
    , entries : List ( Evergreen.V3.Data.User.UserInfo, Evergreen.V3.Data.Date.Date, Evergreen.V3.Data.Entry.EntryContent )
    , focusedTracker : Maybe Int
    , time : Maybe Time.Posix
    , postedYesterday : Bool
    }


type Msg
    = UpdatedEntries
    | GotEntries (List ( Evergreen.V3.Data.User.UserInfo, Evergreen.V3.Data.Date.Date, Evergreen.V3.Data.Entry.EntryContent ))
    | UpdatedDraft Evergreen.V3.Data.Entry.EntryContent
    | CreatedDraft
        { draft : Maybe ( Time.Posix, Time.Zone, Evergreen.V3.Data.Entry.EntryContent )
        , postedYesterday : Bool
        }
    | FinishedUpdatingDraft
    | PublishDraft
    | SetDraftForYesterday
    | GotTrackers (List ( Evergreen.V3.Data.Store.Id Evergreen.V3.Data.Tracker.Tracker, Evergreen.V3.Data.Tracker.Tracker ))
    | AddedTracker String
    | DeletedTracker (Evergreen.V3.Data.Store.Id Evergreen.V3.Data.Tracker.Tracker)
    | EditedTracker ( Int, Evergreen.V3.Data.Tracker.Tracker )
    | FinishedEditingTracker Int
    | GotTime Time.Posix
