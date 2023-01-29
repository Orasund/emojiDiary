module Pages.Home_ exposing (Model, Msg(..), page)

import Bridge exposing (..)
import Config
import Data.Date exposing (Date)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Data.User exposing (UserInfo)
import Html exposing (..)
import Layout
import Page
import Request exposing (Request)
import Shared
import Task
import Time exposing (Posix, Zone)
import Time.Extra exposing (Interval(..))
import View exposing (View)
import View.Date
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
    , entryDraft : Maybe ( Posix, Zone, EntryContent )
    , trackers : List ( Id Tracker, Tracker )
    , entries : List ( UserInfo, Date, EntryContent )
    , time : Maybe Posix
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
            , time = Nothing
            }
    in
    ( model
    , [ AtHome GetTrackers |> sendToBackend
      , AtHome GetDraft |> sendToBackend
      , AtHome GetEntriesOfSubscribed |> sendToBackend
      , Time.now |> Task.perform GotTime
      ]
        |> Cmd.batch
    )



-- UPDATE


type Msg
    = EntriesUpdated
    | GotEntries (List ( UserInfo, Date, EntryContent ))
    | DraftUpdated EntryContent
    | DraftCreated (Maybe ( Posix, Zone, EntryContent ))
    | StoppedUpdatingDraft
    | PublishDraft
    | GotTrackers (List ( Id Tracker, Tracker ))
    | AddedTracker String
    | DeletedTracker (Id Tracker)
    | GotTime Posix


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
                    { d
                        | content = String.left 6 d.content
                        , description = String.left 50 d.description
                    }

                shouldDelete =
                    String.isEmpty d.content
            in
            ( { model
                | entryDraft =
                    if shouldDelete then
                        Nothing

                    else
                        case model.entryDraft of
                            Just ( posix, zone, _ ) ->
                                Just ( posix, zone, entryDraft )

                            Nothing ->
                                model.time
                                    |> Maybe.map (\time -> ( time, shared.zone, entryDraft ))
              }
            , Cmd.none
            )

        StoppedUpdatingDraft ->
            ( model
            , model.entryDraft
                |> Maybe.map (\( _, zone, draft ) -> ( zone, draft ))
                |> Bridge.DraftUpdated
                |> AtHome
                |> sendToBackend
            )

        DraftCreated draft ->
            ( { model | entryDraft = draft }, Cmd.none )

        GotTrackers trackers ->
            ( { model | trackers = trackers }, Cmd.none )

        AddedTracker emoji ->
            ( model
            , AtHome (Bridge.AddTracker emoji)
                |> sendToBackend
            )

        DeletedTracker id ->
            ( model
            , Bridge.RemoveTracker id
                |> AtHome
                |> sendToBackend
            )

        PublishDraft ->
            ( model, Bridge.PublishDraft |> AtHome |> sendToBackend )

        GotTime time ->
            ( { model | time = Just time }, Cmd.none )


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
                    |> View.Entry.draft
                        { onSubmit = DraftUpdated
                        , onBlur = StoppedUpdatingDraft
                        , zone = shared.zone
                        }
                , model.entryDraft
                    |> Maybe.map
                        (\( posix, zone, _ ) ->
                            let
                                p =
                                    Time.Extra.add Hour Config.postingCooldownInHours zone posix

                                minTime =
                                    Time.Extra.add Hour Config.postingMinCooldownInHours zone posix
                            in
                            [ "Draft will be published"
                                ++ (if
                                        model.time
                                            |> Maybe.map
                                                (\time ->
                                                    Data.Date.fromPosix zone p
                                                        == Data.Date.fromPosix shared.zone time
                                                )
                                            |> Maybe.withDefault False
                                    then
                                        " today"

                                    else
                                        " on "
                                            ++ View.Date.weekdayToString (Time.toWeekday shared.zone p)
                                   )
                                ++ " at "
                                ++ View.Date.asTime shared.zone p
                                |> Html.text
                                |> Layout.el [ Layout.alignAtCenter ]
                            , case model.time of
                                Just time ->
                                    if Time.posixToMillis minTime < Time.posixToMillis time then
                                        View.Style.button
                                            { onPress = Just PublishDraft
                                            , label = "Publish now"
                                            }

                                    else
                                        Layout.none

                                Nothing ->
                                    Layout.none
                            ]
                                |> Layout.row [ Layout.spaceBetween ]
                        )
                    |> Maybe.withDefault Layout.none
                , [ View.Style.itemHeading "Trackers"
                  , model.trackers
                        |> View.Tracker.list
                            { onDelete = DeletedTracker
                            , onClick =
                                \string ->
                                    model.entryDraft
                                        |> Maybe.map (\( _, _, d ) -> d)
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
        , [ View.Style.sectionHeading "Yesterdays adventures"
          , model.entries
                |> List.map
                    (\( user, posix, entry ) ->
                        View.Entry.withUser ( user, posix, entry )
                    )
                |> Layout.column [ Layout.spacing 4 ]
          ]
            |> Layout.column View.Style.container
            |> Layout.el [ Layout.centerContent ]
        ]
            |> Layout.column [ Layout.spacing 16 ]
            |> List.singleton
    }
