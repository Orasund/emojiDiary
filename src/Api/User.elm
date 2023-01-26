module Api.User exposing (..)

{-|

@docs User, UserFull, Email

-}

import Api.Article exposing (Slug)
import Api.Profile exposing (Profile)
import Set exposing (Set)


type alias User =
    { id : Int
    , email : Email
    , username : String
    , bio : Maybe String
    , image : String
    }


type alias UserFull =
    { id : Int
    , email : Email
    , username : String
    , bio : Maybe String
    , image : String
    , password : String
    , favorites : List Slug
    , following : Set UserId
    }


type alias UserId =
    Int


toUser : UserFull -> User
toUser u =
    { id = u.id
    , email = u.email
    , username = u.username
    , bio = u.bio
    , image = u.image
    }


toProfile : Bool -> UserFull -> Profile
toProfile subscribed u =
    { username = u.username
    , bio = u.bio
    , image = u.image
    , following = subscribed
    }


type alias Email =
    String
