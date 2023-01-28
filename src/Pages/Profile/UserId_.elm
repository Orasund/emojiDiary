module Pages.Profile.UserId_ exposing (Model, Msg(..), page)

import Api.Article exposing (Article)
import Api.Data exposing (Data)
import Api.Profile exposing (Profile)
import Api.User exposing (User, UserId)
import Bridge exposing (..)
import Components.NotFound
import Data.Entry exposing (EntryContent)
import Gen.Params.Profile.UserId_ exposing (Params)
import Html exposing (..)
import Html.Attributes exposing (class, src)
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
    { userId : UserId
    , profile : Data Profile
    , listing : Data Api.Article.Listing
    , entries : List ( Posix, EntryContent )
    , page : Int
    }


init : Shared.Model -> Request.With Params -> ( Model, Cmd Msg )
init shared { params } =
    let
        userId =
            String.toInt params.userId |> Maybe.withDefault -1
    in
    ( { userId = userId
      , profile = Api.Data.Loading
      , listing = Api.Data.Loading
      , entries = []
      , page = 1
      }
    , Cmd.batch
        [ ProfileGet_Profile__Username_
            { userId = String.toInt params.userId |> Maybe.withDefault -1
            }
            |> sendToBackend
        , GetEntriesOfProfile
            |> AtProfile { userId = userId }
            |> sendToBackend
        ]
    )



-- UPDATE


type Msg
    = GotProfile (Data Profile)
    | GotArticles (Data Api.Article.Listing)
    | ClickedFavorite User Article
    | ClickedUnfavorite User Article
    | UpdatedArticle (Data Article)
    | ClickedPage Int
    | GotEntries (List ( Posix, EntryContent ))
    | ToggleFollowing


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update shared msg model =
    case msg of
        GotProfile profile ->
            ( { model | profile = profile }
            , Cmd.none
            )

        GotArticles listing ->
            ( { model | listing = listing }
            , Cmd.none
            )

        ClickedFavorite user article ->
            ( model
            , ArticleFavorite_Profile__Username_
                { slug = article.slug
                }
                |> sendToBackend
            )

        ClickedUnfavorite user article ->
            ( model
            , ArticleUnfavorite_Profile__Username_
                { slug = article.slug
                }
                |> sendToBackend
            )

        ClickedPage page_ ->
            ( { model
                | listing = Api.Data.Loading
                , page = page_
              }
            , Cmd.none
            )

        UpdatedArticle (Api.Data.Success article) ->
            ( { model
                | listing =
                    Api.Data.map (Api.Article.updateArticle article)
                        model.listing
              }
            , Cmd.none
            )

        UpdatedArticle _ ->
            ( model, Cmd.none )

        GotEntries entries ->
            ( { model | entries = entries }, Cmd.none )

        ToggleFollowing ->
            ( { model
                | profile =
                    model.profile
                        |> Api.Data.map
                            (\profile ->
                                { profile | following = not profile.following }
                            )
              }
            , ToggleSubscription
                |> AtProfile { userId = model.userId }
                |> sendToBackend
            )


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
                [ viewProfile shared profile model ]

            Api.Data.Failure _ ->
                [ Components.NotFound.view ]

            _ ->
                []
    }


viewProfile : Shared.Model -> Profile -> Model -> Html Msg
viewProfile shared profile model =
    let
        isViewingOwnProfile : Bool
        isViewingOwnProfile =
            Maybe.map .username shared.user == Just profile.username

        viewUserInfo : Html Msg
        viewUserInfo =
            [ div [ class "row" ]
                [ div [ class "col-xs-12 col-md-10 offset-md-1" ]
                    [ img [ class "user-img", src profile.image ] []
                    , h4 [] [ text profile.username ]
                    , Utils.Maybe.view profile.bio
                        (\bio -> p [] [ text bio ])
                    ]
                ]
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
                    [ class "container"
                    , Layout.fill
                    , Layout.spaceBetween
                    ]
                |> Layout.el [ class "user-info" ]
    in
    div [ class "profile-page" ]
        [ viewUserInfo
        , model.entries
            |> List.map
                (\( posix, entry ) ->
                    View.Entry.toHtml shared.zone posix entry
                )
            |> Layout.column [ class "container page" ]
        ]
