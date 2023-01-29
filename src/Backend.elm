module Backend exposing (..)

import Api.Data exposing (Data(..))
import Api.User
import Backend.FromFrontend
import Bridge exposing (..)
import Config
import Data.Store
import Dict
import Dict.Extra as Dict
import Gen.Msg
import Lamdera exposing (..)
import Pages.Home_
import Task
import Time
import Time.Extra exposing (Interval(..))
import Types exposing (BackendModel, BackendMsg(..), FrontendMsg(..), ToFrontend(..))


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = Backend.FromFrontend.update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { sessions = Dict.empty
      , users = Data.Store.empty
      , usernames = Dict.empty
      , entries = Dict.empty
      , drafts = Dict.empty
      , trackers = Data.Store.empty
      , hour = Time.millisToPosix 0
      , following = Dict.empty
      }
    , Cmd.none
    )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    let
        hour =
            60 * 60 * 1000
    in
    Sub.batch
        [ onConnect CheckSession
        , Time.every hour HourPassed
        ]


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        CheckSession sid cid ->
            model
                |> Backend.FromFrontend.getSessionUser sid
                |> Maybe.map (\user -> ( model, sendToFrontend cid (ActiveSession (Api.User.toUser user)) ))
                |> Maybe.withDefault ( model, Cmd.none )

        RenewSession uid sid cid now ->
            ( { model
                | sessions =
                    model.sessions
                        |> Dict.update sid (always (Just { userId = uid, expires = now |> Time.Extra.add Day 30 Time.utc }))
              }
            , Time.now |> Task.perform (always (CheckSession sid cid))
            )

        HourPassed currentTime ->
            let
                ( entries, drafts ) =
                    model.drafts
                        |> Dict.foldl
                            (\userId ( posix, content ) ( e, d ) ->
                                if
                                    (posix
                                        |> Time.Extra.add Hour Config.postingCooldownInHours Time.utc
                                        |> Time.posixToMillis
                                    )
                                        < Time.posixToMillis currentTime
                                then
                                    ( e
                                        |> Dict.update userId
                                            (\maybe ->
                                                maybe
                                                    |> Maybe.map (Dict.insert (Time.posixToMillis posix) content)
                                                    |> Maybe.withDefault (Dict.singleton (Time.posixToMillis posix) content)
                                                    |> Just
                                            )
                                    , d |> Dict.remove userId
                                    )

                                else
                                    ( e, d )
                            )
                            ( model.entries, model.drafts )
            in
            ( { model
                | hour = currentTime
                , entries = entries
                , drafts = drafts
              }
            , broadcast (PageMsg (Gen.Msg.Home_ Pages.Home_.EntriesUpdated))
            )

        NoOpBackendMsg ->
            ( model, Cmd.none )
