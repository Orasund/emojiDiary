module Pages.Profile.UserId_ exposing (Model, Msg(..), page)

import Api.Data exposing (Data(..))
import Bridge exposing (..)
import Components.NotFound
import Data.Date exposing (Date)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.User exposing (Profile, UserFull, UserId, UserInfo)
import Gen.Params.Profile.UserId_ exposing (Params)
import Html exposing (..)
import Html.Attributes as Attr
import Layout
import Page
import Request
import Set
import Shared
import Time exposing (Posix, Zone)
import Utils.Maybe
import View exposing (View)
import View.Entry
import View.Style


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared req
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    { profile : Data Profile
    , entries : List ( Date, EntryContent )
    , page : Int
    }


init : Shared.Model -> Request.With Params -> ( Model, Cmd Msg )
init shared { params } =
    let
        username =
            --todo rename params.userId to params.username
            params.userId
    in
    ( { profile = Api.Data.Loading
      , entries = []
      , page = 1
      }
    , Cmd.batch
        [ ProfileGet_Profile__Username_ { username = username }
            |> sendToBackend
        ]
    )



-- UPDATE


type Msg
    = GotProfile (Data Profile)
    | GotEntries (List ( Date, EntryContent ))
    | ToggleFollowing


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update shared msg model =
    case msg of
        GotProfile profile ->
            ( { model | profile = profile }
            , case profile of
                Api.Data.Success { id } ->
                    GetEntriesOfProfile
                        |> AtProfile { userId = id }
                        |> sendToBackend

                _ ->
                    Cmd.none
            )

        GotEntries entries ->
            ( { model | entries = entries }, Cmd.none )

        ToggleFollowing ->
            case model.profile of
                Success profile ->
                    ( { model
                        | profile =
                            Api.Data.Success
                                { profile | following = not profile.following }
                      }
                    , ToggleSubscription
                        |> AtProfile { userId = profile.id }
                        |> sendToBackend
                    )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Profile"
    , body =
        case model.profile of
            Api.Data.Success profile ->
                viewProfile shared profile model

            Api.Data.Failure _ ->
                [ Components.NotFound.view ]

            _ ->
                []
    }


viewProfile : Shared.Model -> Profile -> Model -> List (Html Msg)
viewProfile shared profile model =
    let
        isViewingOwnProfile : Bool
        isViewingOwnProfile =
            Maybe.map .username shared.user == Just profile.username

        viewUserInfo : Html Msg
        viewUserInfo =
            [ [ img
                    [ Attr.class "user-img"
                    , Attr.src profile.image
                    , Attr.style "border-radius" "1000px"
                    ]
                    []
              , profile.username
                    |> View.Style.sectionHeading
                    |> Layout.el [ Layout.centerContent ]
              , Utils.Maybe.view profile.bio
                    (\bio -> p [] [ text bio ])
              ]
                |> Layout.column [ Layout.spacing 16 ]
            , (if isViewingOwnProfile then
                Layout.none

               else if profile.following then
                View.Style.buttonText { onPress = Just ToggleFollowing, label = "Unsubscribe" }
                    |> List.singleton
                    |> Html.div []

               else
                View.Style.button { onPress = Just ToggleFollowing, label = "Subscribe" }
                    |> List.singleton
                    |> Html.div []
              )
                |> Layout.el [ Layout.alignAtEnd ]
            ]
                |> Layout.row
                    ([ Layout.spaceBetween
                     ]
                        ++ View.Style.container
                    )
                |> View.Style.hero
    in
    [ viewUserInfo
    , model.entries
        |> List.map
            (\( date, entry ) ->
                View.Entry.toHtml date entry
            )
        |> Layout.column View.Style.container
        |> Layout.el [ Layout.centerContent ]
    ]
