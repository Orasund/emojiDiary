module Api.User exposing (..)

{-|

@docs User, UserFull, Email

-}

import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)


type alias User =
    { id : Id UserFull
    , username : String
    , image : String
    }


type alias UserFull =
    { username : String
    , bio : Maybe String
    , image : String
    , password : String
    , trackers : List (Id Tracker)
    }


type alias UserId =
    Int


new : { username : String, password : String } -> UserFull
new args =
    { username = args.username
    , bio = Nothing
    , image = "https://static.productionready.io/images/smiley-cyrus.jpg"
    , password = args.password
    , trackers = []
    }


toUser : ( Id UserFull, UserFull ) -> User
toUser ( id, u ) =
    { id = id
    , username = u.username
    , image = u.image
    }


toProfile : Bool -> ( Id UserFull, UserFull ) -> Profile
toProfile subscribed ( id, u ) =
    { id = id
    , username = u.username
    , bio = u.bio
    , image = u.image
    , following = subscribed
    }


type alias Profile =
    { id : Id UserFull
    , username : String
    , bio : Maybe String
    , image : String
    , following : Bool
    }
