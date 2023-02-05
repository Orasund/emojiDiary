module Pages.Home_ exposing (Model, Msg(..), page)

import Array exposing (Array)
import Bridge exposing (..)
import Config
import Data.Date exposing (Date)
import Data.Entry exposing (EntryContent)
import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Data.User exposing (UserInfo)
import EmojiPicker
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


emojiPickerDraftId =
    "Draft"


emojiPickerTrackerId =
    "Tracker"


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
    , entryDraft : Maybe ( Maybe Posix, Zone, EntryContent )
    , trackers : Array ( Id Tracker, Tracker )
    , entries : List ( UserInfo, Date, EntryContent )
    , focusedTracker : Maybe Int
    , time : Maybe Posix
    , postedYesterday : Bool
    , emojiPicker : EmojiPicker.Model
    , emojiPickerId : String
    }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    let
        model : Model
        model =
            { page = 1
            , entryDraft = Nothing
            , trackers = Array.empty
            , entries = []
            , focusedTracker = Nothing
            , time = Nothing
            , postedYesterday = True
            , emojiPicker =
                EmojiPicker.init
                    { offsetX = 0
                    , offsetY = 0
                    , closeOnSelect = True
                    }
            , emojiPickerId = ""
            }
    in
    ( model
    , [ AtHome GetTrackers |> sendToBackend
      , GetDraft shared.zone |> AtHome |> sendToBackend
      , AtHome GetEntriesOfSubscribed |> sendToBackend
      , Time.now |> Task.perform GotTime
      ]
        |> Cmd.batch
    )



-- UPDATE


type Msg
    = UpdatedEntries
    | GotEntries (List ( UserInfo, Date, EntryContent ))
    | UpdatedDraft { draft : EntryContent, toBackend : Bool }
    | CreatedDraft { draft : Maybe ( Maybe Posix, Zone, EntryContent ), postedYesterday : Bool }
    | FinishedUpdatingDraft
    | PublishDraft
    | SetDraftForYesterday
    | GotTrackers (List ( Id Tracker, Tracker ))
    | AddedTracker String
    | DeletedTracker (Id Tracker)
    | EditedTracker ( Int, Tracker )
    | FinishedEditingTracker Int
    | GotTime Posix
    | EmojiPickerSpecific String EmojiPicker.Msg


updateDraft : Shared.Model -> { draft : EntryContent, toBackend : Bool } -> Model -> ( Model, Cmd Msg )
updateDraft shared { draft, toBackend } model =
    let
        entryDraft =
            { draft
                | content = String.left 6 draft.content
                , description = String.left 50 draft.description
            }

        shouldDelete =
            String.isEmpty draft.content
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
                        Just ( Nothing, shared.zone, entryDraft )
      }
    , if toBackend then
        model.entryDraft
            |> Bridge.DraftUpdated
            |> AtHome
            |> sendToBackend

      else
        Cmd.none
    )


addTracker : String -> Cmd Msg
addTracker emoji =
    AtHome (Bridge.AddTracker emoji)
        |> sendToBackend


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update shared msg model =
    case msg of
        GotEntries entries ->
            ( { model | entries = entries }
            , Cmd.none
            )

        UpdatedEntries ->
            ( model
            , Bridge.GetDraft shared.zone
                |> AtHome
                |> sendToBackend
            )

        UpdatedDraft args ->
            updateDraft shared args model

        FinishedUpdatingDraft ->
            ( model
            , model.entryDraft
                |> Bridge.DraftUpdated
                |> AtHome
                |> sendToBackend
            )

        CreatedDraft { draft, postedYesterday } ->
            ( { model
                | entryDraft = draft
                , postedYesterday = postedYesterday
              }
            , Cmd.none
            )

        GotTrackers trackers ->
            ( { model | trackers = trackers |> Array.fromList }, Cmd.none )

        AddedTracker emoji ->
            ( model
            , addTracker emoji
            )

        DeletedTracker id ->
            ( model
            , Bridge.RemoveTracker id
                |> AtHome
                |> sendToBackend
            )

        EditedTracker ( index, tracker ) ->
            ( { model
                | trackers =
                    model.trackers
                        |> Array.get index
                        |> Maybe.map (\( id, _ ) -> model.trackers |> Array.set index ( id, tracker ))
                        |> Maybe.withDefault model.trackers
                , focusedTracker =
                    Just index
              }
            , Cmd.none
            )

        FinishedEditingTracker index ->
            ( { model | focusedTracker = Nothing }
            , model.trackers
                |> Array.get index
                |> Maybe.map Bridge.EditTracker
                |> Maybe.map AtHome
                |> Maybe.map sendToBackend
                |> Maybe.withDefault Cmd.none
            )

        PublishDraft ->
            ( model, Bridge.PublishDraft |> AtHome |> sendToBackend )

        SetDraftForYesterday ->
            let
                entryDraft =
                    Maybe.map2
                        (\( _, z, e ) time ->
                            ( time |> Time.Extra.add Day -1 shared.zone |> Just
                            , z
                            , e
                            )
                        )
                        model.entryDraft
                        model.time
            in
            ( { model
                | entryDraft = entryDraft
                , postedYesterday = True
              }
            , entryDraft
                |> Bridge.DraftUpdated
                |> AtHome
                |> sendToBackend
            )

        GotTime time ->
            ( { model | time = Just time }, Cmd.none )

        EmojiPickerSpecific tag m ->
            model.emojiPicker
                |> EmojiPicker.update m
                |> (\( emojiPicker, cmd ) ->
                        { model
                            | emojiPicker = emojiPicker
                            , emojiPickerId = tag
                        }
                            |> (\newModel ->
                                    case m of
                                        EmojiPicker.Select string ->
                                            if tag == emojiPickerDraftId then
                                                newModel.entryDraft
                                                    |> Maybe.map (\( _, _, draft ) -> draft)
                                                    |> Maybe.withDefault Data.Entry.newDraft
                                                    |> (\draft ->
                                                            updateDraft shared
                                                                { draft = { draft | content = draft.content ++ string }
                                                                , toBackend = True
                                                                }
                                                                newModel
                                                       )

                                            else if tag == emojiPickerTrackerId then
                                                ( newModel, addTracker string )

                                            else
                                                ( newModel, Cmd.none )

                                        _ ->
                                            ( newModel, Cmd.none )
                               )
                            |> Tuple.mapSecond
                                (\newCmd ->
                                    Cmd.batch [ newCmd, cmd |> Cmd.map (EmojiPickerSpecific tag) ]
                                )
                   )


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
                [ [ View.Style.sectionHeading "How was your day?"
                  , case model.entryDraft of
                        Just ( posix, _, _ ) ->
                            if
                                posix
                                    |> Maybe.map
                                        (\p ->
                                            Maybe.map
                                                (\time ->
                                                    Data.Date.fromPosix shared.zone p
                                                        == Data.Date.fromPosix shared.zone time
                                                        && model.postedYesterday
                                                )
                                                model.time
                                                |> Maybe.withDefault False
                                        )
                                    |> Maybe.withDefault True
                            then
                                Layout.none

                            else
                                View.Style.button
                                    { onPress = Just SetDraftForYesterday
                                    , label = "For Yesterday"
                                    }

                        Nothing ->
                            Layout.none
                  ]
                    |> Layout.row [ Layout.spaceBetween ]
                , model.entryDraft
                    |> View.Entry.draft
                        { onSubmit = \d -> UpdatedDraft { draft = d, toBackend = False }
                        , onBlur = FinishedUpdatingDraft
                        , zone = shared.zone
                        , toggleEmojiPicker = EmojiPickerSpecific emojiPickerDraftId EmojiPicker.Toggle
                        }
                , EmojiPicker.view model.emojiPicker
                    |> Html.map (EmojiPickerSpecific model.emojiPickerId)
                , model.entryDraft
                    |> Maybe.andThen (\( p, z, _ ) -> p |> Maybe.map (\posix -> ( posix, z )))
                    |> Maybe.map
                        (\( posix, zone ) ->
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
                        |> Array.toList
                        |> List.reverse
                        |> View.Tracker.list
                            { onDelete = DeletedTracker
                            , onClick =
                                \string ->
                                    model.entryDraft
                                        |> Maybe.map (\( _, _, d ) -> d)
                                        |> Maybe.withDefault Data.Entry.newDraft
                                        |> (\draft ->
                                                { draft =
                                                    { draft
                                                        | content = draft.content ++ string
                                                    }
                                                , toBackend = True
                                                }
                                           )
                                        |> UpdatedDraft
                            , onBlur = FinishedEditingTracker
                            , onEdit = EditedTracker
                            , focusedTracker = model.focusedTracker
                            }
                  , View.Tracker.new
                        { onInput = AddedTracker
                        , toggleEmojiPicker = EmojiPickerSpecific emojiPickerTrackerId EmojiPicker.Toggle
                        }
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
        , case shared.user of
            Just _ ->
                [ View.Style.sectionHeading "Yesterdays adventures"
                , model.entries
                    |> List.map
                        (\( user, posix, entry ) ->
                            View.Entry.toHtml (Just user) posix entry
                        )
                    |> Layout.column [ Layout.spacing 4 ]
                ]
                    |> Layout.column View.Style.container
                    |> Layout.el [ Layout.centerContent ]

            Nothing ->
                Layout.none
        ]
            |> Layout.column [ Layout.spacing 16 ]
            |> List.singleton
    }
