module Bridge exposing (..)

import Api.User exposing (User, UserId)
import Data.Entry exposing (EntryContent)
import Lamdera


sendToBackend =
    Lamdera.sendToBackend


type HomeToBackend
    = DraftUpdated EntryContent
    | GetDraft


type ProfileToBackend
    = GetEntriesOfProfile
    | Subscribe


type ToBackend
    = SignedOut User
      -- Req/resp paired messages
    | ArticleGet_Article__Slug_ { slug : String }
    | ArticleDelete_Article__Slug_ { slug : String }
    | ArticleFavorite_Profile__Username_ { slug : String }
    | ArticleUnfavorite_Profile__Username_ { slug : String }
    | ArticleFavorite_Home_ { slug : String }
    | ArticleUnfavorite_Home_ { slug : String }
    | ArticleFavorite_Article__Slug_ { slug : String }
    | ArticleUnfavorite_Article__Slug_ { slug : String }
    | ArticleCommentGet_Article__Slug_ { articleSlug : String }
    | ArticleCommentCreate_Article__Slug_ { articleSlug : String, comment : { body : String } }
    | ArticleCommentDelete_Article__Slug_ { articleSlug : String, commentId : Int }
    | ProfileGet_Profile__Username_ { userId : UserId }
    | UserAuthentication_Login { params : { email : String, password : String } }
    | UserRegistration_Register { params : { username : String, email : String, password : String } }
    | UserUpdate_Settings
        { params :
            { username : String
            , email : String
            , password : Maybe String
            , image : String
            , bio : String
            }
        }
    | AtProfile { userId : UserId } ProfileToBackend
    | AtHome HomeToBackend
    | NoOpToBackend
