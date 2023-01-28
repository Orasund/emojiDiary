module Data.Tracker exposing (..)


type alias Tracker =
    { emoji : String
    , description : String
    }


new : String -> Tracker
new emoji =
    { emoji = emoji
    , description = "Tracks how often you use " ++ emoji
    }
