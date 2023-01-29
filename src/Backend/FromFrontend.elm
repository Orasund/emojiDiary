module Backend.FromFrontend exposing (..)

import Api.Data exposing (Data(..))
import Api.User exposing (UserFull)
import Bridge exposing (..)
import Data.Store exposing (Id)
import Data.Tracker
import Dict
import Dict.Extra as Dict
import Gen.Msg
import Lamdera exposing (..)
import List.Extra as List
import Pages.Home_
import Pages.Login
import Pages.Profile.UserId_
import Pages.Register
import Pages.Settings
import Shared
import Task
import Time
import Time.Extra exposing (Interval(..))
import Types exposing (BackendModel, BackendMsg(..), FrontendMsg(..), ToFrontend(..))


type alias Model =
    BackendModel


updateAtHome : (ToFrontend -> Cmd BackendMsg) -> Id UserFull -> UserFull -> HomeToBackend -> Model -> ( Model, Cmd BackendMsg )
updateAtHome send_ userId user msg model =
    case msg of
        DraftUpdated draft ->
            model.drafts
                |> Dict.get (Data.Store.read userId)
                |> (\maybe ->
                        ( { model
                            | drafts =
                                if String.isEmpty draft.content then
                                    model.drafts |> Dict.remove (Data.Store.read userId)

                                else
                                    model.drafts
                                        |> Dict.insert (Data.Store.read userId)
                                            (maybe
                                                |> Maybe.map (Tuple.mapSecond (\_ -> draft))
                                                |> Maybe.withDefault ( model.hour, draft )
                                            )
                          }
                        , case maybe of
                            Just _ ->
                                Cmd.none

                            Nothing ->
                                ( model.hour, draft )
                                    |> Just
                                    |> Pages.Home_.DraftCreated
                                    |> Gen.Msg.Home_
                                    |> PageMsg
                                    |> send_
                        )
                   )

        GetEntriesOfSubscribed ->
            model.following
                |> Dict.get (Data.Store.read userId)
                |> Maybe.withDefault []
                |> List.filterMap
                    (\id ->
                        model.users
                            |> Data.Store.get id
                            |> Maybe.map (Tuple.pair id)
                    )
                |> List.filterMap
                    (\( id, u ) ->
                        model.entries
                            |> Dict.get (Data.Store.read id)
                            |> Maybe.withDefault Dict.empty
                            |> Dict.toList
                            |> List.reverse
                            |> List.head
                            |> Maybe.map
                                (\( millis, entry ) ->
                                    ( Api.User.toUser ( id, u ), Time.millisToPosix millis, entry )
                                )
                    )
                |> (\entries ->
                        ( model
                        , send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.GotEntries entries)))
                        )
                   )

        GetDraft ->
            model.drafts
                |> Dict.get (Data.Store.read userId)
                |> (\draft ->
                        ( model, send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.DraftCreated draft))) )
                   )

        GetTrackers ->
            user.trackers
                |> List.filterMap
                    (\id ->
                        model.trackers
                            |> Data.Store.get id
                            |> Maybe.map (Tuple.pair id)
                    )
                |> (\trackers ->
                        ( model, send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.GotTrackers trackers))) )
                   )

        AddTracker emoji ->
            model.trackers
                |> Data.Store.insert
                    (emoji
                        |> String.left 2
                        |> Data.Tracker.new
                    )
                |> Tuple.mapSecond
                    (\id ->
                        id :: user.trackers
                    )
                |> (\( store, userTrackers ) ->
                        ( { model
                            | trackers = store
                            , users =
                                model.users
                                    |> Data.Store.update userId
                                        (\_ -> { user | trackers = userTrackers })
                          }
                        , userTrackers
                            |> List.filterMap
                                (\id ->
                                    store
                                        |> Data.Store.get id
                                        |> Maybe.map (Tuple.pair id)
                                )
                            |> Pages.Home_.GotTrackers
                            |> Gen.Msg.Home_
                            |> PageMsg
                            |> send_
                        )
                   )

        RemoveTracker trackerId ->
            ( model.trackers |> Data.Store.remove trackerId
            , user.trackers |> List.filter ((/=) trackerId)
            )
                |> (\( store, userTrackers ) ->
                        ( { model
                            | trackers = store
                            , users =
                                model.users
                                    |> Data.Store.update userId
                                        (\_ -> { user | trackers = userTrackers })
                          }
                        , userTrackers
                            |> List.filterMap
                                (\id ->
                                    store
                                        |> Data.Store.get id
                                        |> Maybe.map (Tuple.pair id)
                                )
                            |> Pages.Home_.GotTrackers
                            |> Gen.Msg.Home_
                            |> PageMsg
                            |> send_
                        )
                   )


update : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
update sessionId clientId msg model =
    let
        send v =
            ( model, send_ v )

        send_ v =
            sendToFrontend clientId v

        ifSignedIn : (( Id UserFull, UserFull ) -> ( Model, Cmd BackendMsg )) -> ( Model, Cmd BackendMsg )
        ifSignedIn fun =
            case model |> getSessionUser sessionId of
                Just a ->
                    fun a

                Nothing ->
                    "Please sign in"
                        |> Shared.GotError
                        |> SharedMsg
                        |> send
    in
    case msg of
        SignedOut _ ->
            ( { model | sessions = model.sessions |> Dict.remove sessionId }, Cmd.none )

        ProfileGet_Profile__Username_ { username } ->
            model.usernames
                |> Dict.get username
                |> Maybe.andThen
                    (\profileId ->
                        let
                            subscribed =
                                model
                                    |> getSessionUser sessionId
                                    |> Maybe.map Tuple.first
                                    |> Maybe.map
                                        (\userId ->
                                            model.following
                                                |> Dict.get (Data.Store.read userId)
                                                |> Maybe.withDefault []
                                                |> List.member profileId
                                        )
                                    |> Maybe.withDefault False
                        in
                        model.users
                            |> Data.Store.get profileId
                            |> Maybe.map (Tuple.pair profileId)
                            |> Maybe.map (Api.User.toProfile subscribed)
                            |> Maybe.map Success
                    )
                |> Maybe.withDefault (Failure [ "user not found" ])
                |> (\res -> send (PageMsg (Gen.Msg.Profile__UserId_ (Pages.Profile.UserId_.GotProfile res))))

        UserAuthentication_Login { params } ->
            let
                ( response, cmd ) =
                    model.usernames
                        |> Dict.get params.username
                        |> Maybe.andThen
                            (\id ->
                                model.users
                                    |> Data.Store.get id
                                    |> Maybe.map (Tuple.pair id)
                            )
                        |> Maybe.map
                            (\( id, u ) ->
                                if u.password == params.password then
                                    ( Success (Api.User.toUser ( id, u ))
                                    , renewSession id sessionId clientId
                                    )

                                else
                                    ( Failure [ "email or password is invalid" ], Cmd.none )
                            )
                        |> Maybe.withDefault ( Failure [ "email or password is invalid" ], Cmd.none )
            in
            ( model, Cmd.batch [ send_ (PageMsg (Gen.Msg.Login (Pages.Login.GotUser response))), cmd ] )

        UserRegistration_Register { params } ->
            let
                ( model_, cmd, res ) =
                    if model.usernames |> Dict.member params.username then
                        ( model, Cmd.none, Failure [ "username already taken" ] )

                    else
                        let
                            ( trackers, trackerIds ) =
                                model.trackers
                                    |> Data.Store.insertAll
                                        [ { emoji = "💡", description = "Learned something new" }
                                        , { emoji = "💪", description = "Felt strong" }
                                        , { emoji = "🥳", description = "Had a good time" }
                                        ]

                            user_ : UserFull
                            user_ =
                                { username = params.username
                                , bio = Nothing
                                , image = "https://static.productionready.io/images/smiley-cyrus.jpg"
                                , password = params.password
                                , trackers = trackerIds
                                }

                            ( store, userId ) =
                                model.users |> Data.Store.insert user_
                        in
                        ( { model
                            | users = store
                            , usernames = model.usernames |> Dict.insert params.username userId
                            , trackers = trackers
                          }
                        , renewSession userId sessionId clientId
                        , Success (Api.User.toUser ( userId, user_ ))
                        )
            in
            ( model_, Cmd.batch [ cmd, send_ (PageMsg (Gen.Msg.Register (Pages.Register.GotUser res))) ] )

        UserUpdate_Settings { params } ->
            let
                ( model_, res ) =
                    case model |> getSessionUser sessionId of
                        Just ( userId, user ) ->
                            let
                                user_ =
                                    { user
                                        | username = params.username

                                        -- , email = params.email
                                        , password = params.password |> Maybe.withDefault user.password
                                        , image = params.image
                                    }
                            in
                            ( { model
                                | users =
                                    model.users |> Data.Store.update userId (\_ -> user_)
                              }
                            , Success (Api.User.toUser ( userId, user_ ))
                            )

                        Nothing ->
                            ( model, Failure [ "you do not have permission for this user" ] )
            in
            ( model_, send_ (PageMsg (Gen.Msg.Settings (Pages.Settings.GotUser res))) )

        AtProfile profile GetEntriesOfProfile ->
            model.entries
                |> Dict.get (Data.Store.read profile.userId)
                |> Maybe.withDefault Dict.empty
                |> Dict.toList
                |> List.reverse
                |> List.take 31
                |> List.map (Tuple.mapFirst Time.millisToPosix)
                |> (\entries ->
                        ( model
                        , send_ (PageMsg (Gen.Msg.Profile__UserId_ (Pages.Profile.UserId_.GotEntries entries)))
                        )
                   )

        AtProfile profile ToggleSubscription ->
            case model |> getSessionUser sessionId of
                Just ( userId, _ ) ->
                    ( { model
                        | following =
                            model.following
                                |> Dict.update (Data.Store.read userId)
                                    (\maybe ->
                                        maybe
                                            |> Maybe.withDefault []
                                            |> (\list ->
                                                    if list |> List.member profile.userId then
                                                        list |> List.filter ((/=) profile.userId)

                                                    else
                                                        profile.userId :: list
                                               )
                                            |> Just
                                    )
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        AtHome m ->
            ifSignedIn
                (\( userId, user ) ->
                    updateAtHome send_ userId user m model
                )

        NoOpToBackend ->
            ( model, Cmd.none )


getSessionUser : SessionId -> Model -> Maybe ( Id UserFull, UserFull )
getSessionUser sid model =
    model.sessions
        |> Dict.get sid
        |> Maybe.map .userId
        |> Maybe.andThen
            (\id ->
                model.users
                    |> Data.Store.get id
                    |> Maybe.map (Tuple.pair id)
            )


renewSession userId sid cid =
    Time.now |> Task.perform (RenewSession userId sid cid)


getUserIdByUsername : String -> Model -> Maybe (Id UserFull)
getUserIdByUsername string model =
    model.usernames
        |> Dict.get string