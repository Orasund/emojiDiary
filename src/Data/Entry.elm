module Data.Entry exposing (..)


type alias EntryContent =
    { content : String
    , description : String
    }


newDraft : EntryContent
newDraft =
    { content = ""
    , description = ""
    }
