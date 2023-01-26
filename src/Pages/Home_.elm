module Pages.Home_ exposing (Model, Msg(..), page)

import Api.Article exposing (Article)
import Api.Data exposing (Data)
import Api.User exposing (User)
import Bridge exposing (..)
import Data.Entry exposing (EntryContent)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class)
import Layout
import Page
import Request exposing (Request)
import Shared
import Task
import Time exposing (Zone)
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
    , entries : Dict Int EntryContent
    }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    let
        model : Model
        model =
            { listing = Api.Data.Loading
            , page = 1
            , entryDraft = Nothing
            , entries = Dict.empty
            }
    in
    ( model
    , AtHome GetDraft |> sendToBackend
    )



-- UPDATE


type Msg
    = GotArticles (Data Api.Article.Listing)
    | ClickedFavorite User Article
    | ClickedUnfavorite User Article
    | ClickedPage Int
    | UpdatedArticle (Data Article)
    | EntriesUpdated
    | GotEntries (Dict Int EntryContent)
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
        [ div [ class "home-page" ]
            [ div [ class "banner" ]
                [ div [ class "container" ]
                    [ h1 [ class "logo-font" ] [ text "conduit" ]
                    , p [] [ text "A place to share your knowledge." ]
                    ]
                ]
            , div [ class "container page" ]
                [ model.entryDraft
                    |> Maybe.map (View.Entry.draft { onSubmit = DraftUpdated })
                    |> Maybe.withDefault Layout.none
                ]
            ]
        ]
    }
