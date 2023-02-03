module Data.Entry exposing (..)


type alias EntryContent =
    { content : String
    , description : String
    , link : Maybe String
    }


newDraft : EntryContent
newDraft =
    { content = ""
    , description = ""
    , link = Nothing
    }
