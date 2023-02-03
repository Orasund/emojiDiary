module Evergreen.V4.Pages.Home_ exposing (..)

import Array
import Evergreen.V4.Data.Date
import Evergreen.V4.Data.Entry
import Evergreen.V4.Data.Store
import Evergreen.V4.Data.Tracker
import Evergreen.V4.Data.User
import Time


type alias Model =
    { page : Int
    , entryDraft : Maybe ( Maybe Time.Posix, Time.Zone, Evergreen.V4.Data.Entry.EntryContent )
    , trackers : Array.Array ( Evergreen.V4.Data.Store.Id Evergreen.V4.Data.Tracker.Tracker, Evergreen.V4.Data.Tracker.Tracker )
    , entries : List ( Evergreen.V4.Data.User.UserInfo, Evergreen.V4.Data.Date.Date, Evergreen.V4.Data.Entry.EntryContent )
    , focusedTracker : Maybe Int
    , time : Maybe Time.Posix
    , postedYesterday : Bool
    }


type Msg
    = UpdatedEntries
    | GotEntries (List ( Evergreen.V4.Data.User.UserInfo, Evergreen.V4.Data.Date.Date, Evergreen.V4.Data.Entry.EntryContent ))
    | UpdatedDraft
        { draft : Evergreen.V4.Data.Entry.EntryContent
        , toBackend : Bool
        }
    | CreatedDraft
        { draft : Maybe ( Maybe Time.Posix, Time.Zone, Evergreen.V4.Data.Entry.EntryContent )
        , postedYesterday : Bool
        }
    | FinishedUpdatingDraft
    | PublishDraft
    | SetDraftForYesterday
    | GotTrackers (List ( Evergreen.V4.Data.Store.Id Evergreen.V4.Data.Tracker.Tracker, Evergreen.V4.Data.Tracker.Tracker ))
    | AddedTracker String
    | DeletedTracker (Evergreen.V4.Data.Store.Id Evergreen.V4.Data.Tracker.Tracker)
    | EditedTracker ( Int, Evergreen.V4.Data.Tracker.Tracker )
    | FinishedEditingTracker Int
    | GotTime Time.Posix
