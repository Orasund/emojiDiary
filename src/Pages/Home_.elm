module Pages.Home_ exposing (Model, Msg(..), page)

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
    { page : Int
    , entryDraft : Maybe EntryContent
    , trackers : List ( Id Tracker, Tracker )
    , entries : List ( User, Posix, EntryContent )
    }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    let
        model : Model
        model =
            { page = 1
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
    = EntriesUpdated
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
