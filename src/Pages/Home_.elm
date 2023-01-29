module Pages.Home_ exposing (Model, Msg(..), page)

import Api.User exposing (User)
import Bridge exposing (..)
import Config
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Html exposing (..)
import Layout
import Page
import Request exposing (Request)
import Shared
import Time exposing (Posix)
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
    , entryDraft : Maybe ( Posix, EntryContent )
    , trackers : List ( Id Tracker, Tracker )
    , entries : List ( User, Posix, EntryContent )
    }


init : Shared.Model -> ( Model, Cmd Msg )
init _ =
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
    | DraftCreated (Maybe ( Posix, EntryContent ))
    | GotTrackers (List ( Id Tracker, Tracker ))
    | AddedTracker String
    | DeletedTracker (Id Tracker)


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
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
            ( { model
                | entryDraft =
                    model.entryDraft |> Maybe.map (Tuple.mapSecond (\_ -> entryDraft))
              }
            , AtHome (Bridge.DraftUpdated entryDraft)
                |> sendToBackend
            )

        DraftCreated draft ->
            ( { model | entryDraft = draft }, Cmd.none )

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
                    |> View.Entry.draft { onSubmit = DraftUpdated, zone = shared.zone }
                , [ View.Style.itemHeading "Trackers"
                  , model.trackers
                        |> View.Tracker.list
                            { onDelete = DeletedTracker
                            , onClick =
                                \string ->
                                    model.entryDraft
                                        |> Maybe.map Tuple.second
                                        |> Maybe.withDefault Data.Entry.newDraft
                                        |> (\draft ->
                                                { draft | content = draft.content ++ string }
                                           )
                                        |> DraftUpdated
                            }
                  , View.Tracker.new { onInput = AddedTracker }
                  ]
                    |> Layout.column [ Layout.spacing 8 ]
                ]

            Nothing ->
                [ View.Style.sectionHeading Config.title
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
            |> Layout.column View.Style.container
        ]
    }
