module Pages.Home_ exposing (Model, Msg(..), page)

import Api.Article exposing (Article)
import Api.Data exposing (Data)
import Api.User exposing (User)
import Bridge exposing (..)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
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
import View.Style
import View.Tracker


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
    , trackers : List ( Id Tracker, Tracker )
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
            , trackers = []
            , entries = []
            }
    in
    ( model
    , [ AtHome GetTrackers |> sendToBackend
      , AtHome GetDraft |> sendToBackend
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
    | GotTrackers (List ( Id Tracker, Tracker ))
    | AddedTracker String
    | DeletedTracker (Id Tracker)


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

        GotTrackers trackers ->
            ( { model | trackers = trackers }, Cmd.none )

        AddedTracker emoji ->
            ( model, AtHome (Bridge.AddTracker emoji) |> sendToBackend )

        DeletedTracker id ->
            ( model, Bridge.RemoveTracker id |> AtHome |> sendToBackend )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = ""
    , body =
        [ (case shared.user of
            Just _ ->
                [ View.Style.sectionHeading "How was your day?"
                , model.entryDraft
                    |> Maybe.map (View.Entry.draft { onSubmit = DraftUpdated })
                    |> Maybe.withDefault Layout.none
                , [ View.Style.itemHeading "Trackers"
                  , model.trackers
                        |> View.Tracker.list { onDelete = DeletedTracker }
                  , View.Tracker.new { onInput = AddedTracker }
                  ]
                    |> Layout.column [ Layout.spacing 8 ]
                ]

            Nothing ->
                [ View.Style.sectionHeading "Emoji Diary"
                , View.Style.itemHeading "Share your emotions"
                ]
          )
            |> Layout.column [ Layout.spacing 16 ]
            |> View.Style.hero
        , model.entries
            |> List.map
                (\( user, posix, entry ) ->
                    View.Entry.withUser shared.zone ( user, posix, entry )
                )
            |> Layout.column [ Attr.class "container page" ]
        ]
    }
