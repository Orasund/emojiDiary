module Pages.Home_ exposing (Model, Msg(..), page)

import Api.Article exposing (Article)
import Api.Data exposing (Data)
import Api.User exposing (User)
import Bridge exposing (..)
import Data.Entry exposing (EntryContent)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as Attr
import Layout
import Page
import Request exposing (Request)
import Shared
import Task
import Time exposing (Posix, Zone)
import View exposing (View)
import View.Entry


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init shared
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }



-- INIT


type alias Model =
    { listing : Data Api.Article.Listing
    , page : Int
    , entryDraft : Maybe EntryContent
    , entries : List ( User, Posix, EntryContent )
    }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    let
        model : Model
        model =
            { listing = Api.Data.Loading
            , page = 1
            , entryDraft = Nothing
            , entries = []
            }
    in
    ( model
    , [ AtHome GetDraft |> sendToBackend
      , AtHome GetEntriesOfSubscribed |> sendToBackend
      ]
        |> Cmd.batch
    )



-- UPDATE


type Msg
    = GotArticles (Data Api.Article.Listing)
    | ClickedFavorite User Article
    | ClickedUnfavorite User Article
    | ClickedPage Int
    | UpdatedArticle (Data Article)
    | EntriesUpdated
    | GotEntries (List ( User, Posix, EntryContent ))
    | DraftUpdated EntryContent


type alias Tag =
    String


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update shared msg model =
    case msg of
        GotArticles listing ->
            ( { model | listing = listing }
            , Cmd.none
            )

        ClickedFavorite user article ->
            ( model
            , ArticleFavorite_Home_
                { slug = article.slug
                }
                |> sendToBackend
            )

        ClickedUnfavorite user article ->
            ( model
            , ArticleUnfavorite_Home_
                { slug = article.slug
                }
                |> sendToBackend
            )

        ClickedPage page_ ->
            let
                newModel : Model
                newModel =
                    { model
                        | listing = Api.Data.Loading
                        , page = page_
                    }
            in
            ( newModel, Cmd.none )

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
            ( { model | entries = entries }
            , Cmd.none
            )

        EntriesUpdated ->
            ( model
            , [ AtHome Bridge.GetDraft |> sendToBackend
              ]
                |> Cmd.batch
            )

        DraftUpdated d ->
            let
                entryDraft =
                    { d | content = String.slice 0 6 d.content }
            in
            ( { model | entryDraft = Just entryDraft }
            , AtHome (Bridge.DraftUpdated entryDraft)
                |> sendToBackend
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = ""
    , body =
        [ div [ Attr.class "home-page" ]
            [ div [ Attr.class "banner" ]
                [ model.entryDraft
                    |> Maybe.map (View.Entry.draft { onSubmit = DraftUpdated })
                    |> Maybe.withDefault Layout.none
                    |> Layout.el [ Attr.class "container " ]
                ]
            , model.entries
                |> List.map
                    (\( user, posix, entry ) ->
                        View.Entry.withUser shared.zone ( user, posix, entry )
                    )
                |> Layout.column [ Attr.class "container page" ]
            ]
        ]
    }
