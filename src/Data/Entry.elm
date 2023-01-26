module Data.Entry exposing (..)

import Api.User exposing (UserId)
import Time exposing (Posix)


type alias EntryContent =
    { content : String
    , description : String
    }


newDraft : EntryContent
newDraft =
    { content = ""
    , description = ""
    }
