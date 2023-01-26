module Data.Entry exposing (..)


type alias EntryDraft =
    { content : String
    , description : String
    }


newDraft : EntryDraft
newDraft =
    { content = ""
    , description = ""
    }
