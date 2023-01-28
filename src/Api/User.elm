module Api.User exposing (..)

{-|

@docs User, UserFull, Email

-}

import Api.Profile exposing (Profile)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Set exposing (Set)


type alias User =
    { id : UserId
    , username : String
    , image : String
    }


type alias UserFull =
    { id : UserId
    , username : String
    , bio : Maybe String
    , image : String
    , password : String
    , trackers : List (Id Tracker)
    , following : Set UserId
    }


type alias UserId =
    Int


toUser : UserFull -> User
toUser u =
    { id = u.id
    , username = u.username
    , image = u.image
    }


toProfile : Bool -> UserFull -> Profile
toProfile subscribed u =
    { username = u.username
    , bio = u.bio
    , image = u.image
    , following = subscribed
    }
