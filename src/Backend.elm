module Backend exposing (..)

import Api.Article exposing (Article, ArticleStore, Slug)
import Api.Data exposing (Data(..))
import Api.User exposing (UserFull)
import Bridge exposing (..)
import Data.Entry
import Data.Store
import Data.Tracker
import Dict
import Dict.Extra as Dict
import Gen.Msg
import Lamdera exposing (..)
import List.Extra as List
import Pages.Article.Slug_
import Pages.Home_
import Pages.Login
import Pages.Profile.UserId_
import Pages.Register
import Pages.Settings
import Set
import Task
import Time
import Time.Extra as Time
import Types exposing (BackendModel, BackendMsg(..), FrontendMsg(..), ToFrontend(..))


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { sessions = Dict.empty
      , users = Dict.empty
      , articles = Dict.empty
      , comments = Dict.empty
      , entries = Dict.empty
      , drafts = Dict.empty
      , trackers = Data.Store.empty
      , hour = Time.millisToPosix 0
      }
    , Cmd.none
    )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    let
        hour =
            --60 * 60 * 1000
            60 * 1000
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
                |> getSessionUser sid
                |> Maybe.map (\user -> ( model, sendToFrontend cid (ActiveSession (Api.User.toUser user)) ))
                |> Maybe.withDefault ( model, Cmd.none )

        RenewSession uid sid cid now ->
            ( { model | sessions = model.sessions |> Dict.update sid (always (Just { userId = uid, expires = now |> Time.add Time.Day 30 Time.utc })) }
            , Time.now |> Task.perform (always (CheckSession sid cid))
            )

        ArticleCommentCreated t userM clientId slug commentBody ->
            case userM of
                Just user ->
                    let
                        comment =
                            { id = Time.posixToMillis t
                            , createdAt = t
                            , updatedAt = t
                            , body = commentBody.body
                            , author = Api.User.toProfile False user
                            }

                        newComments =
                            model.comments
                                |> Dict.update slug
                                    (\commentsM ->
                                        case commentsM of
                                            Just comments ->
                                                Just (comments |> Dict.insert comment.id comment)

                                            Nothing ->
                                                Just <| Dict.singleton comment.id comment
                                    )
                    in
                    ( { model | comments = newComments }
                    , sendToFrontend clientId (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.CreatedComment (Success comment))))
                    )

                Nothing ->
                    ( model
                    , Cmd.none
                    )

        HourPassed currentTime ->
            let
                entries =
                    model.drafts
                        |> Dict.foldl
                            (\userId ( posix, content ) ->
                                Dict.update userId
                                    (\maybe ->
                                        maybe
                                            |> Maybe.map (Dict.insert (Time.posixToMillis posix) content)
                                            |> Maybe.withDefault (Dict.singleton (Time.posixToMillis posix) content)
                                            |> Just
                                    )
                            )
                            model.entries
            in
            ( { model
                | hour = currentTime
                , entries = entries
                , drafts =
                    Dict.empty
              }
            , broadcast (PageMsg (Gen.Msg.Home_ Pages.Home_.EntriesUpdated))
            )

        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    let
        send v =
            ( model, send_ v )

        send_ v =
            sendToFrontend clientId v

        onlyWhenArticleOwner_ slug fn =
            let
                res =
                    model |> loadArticleBySlug slug sessionId

                userM =
                    model |> getSessionUser sessionId
            in
            fn <|
                case ( res, userM ) of
                    ( Success article, Just user ) ->
                        if article.author.username == user.username then
                            res

                        else
                            Failure [ "you do not have permission for this article" ]

                    _ ->
                        Failure [ "you do not have permission for this article" ]
    in
    case msg of
        SignedOut _ ->
            ( { model | sessions = model.sessions |> Dict.remove sessionId }, Cmd.none )

        ArticleGet_Article__Slug_ { slug } ->
            let
                res =
                    model |> loadArticleBySlug slug sessionId
            in
            send (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.GotArticle res)))

        ArticleDelete_Article__Slug_ { slug } ->
            onlyWhenArticleOwner_ slug
                (\r ->
                    ( { model | articles = model.articles |> Dict.remove slug }
                    , send_ (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.DeletedArticle r)))
                    )
                )

        ArticleFavorite_Profile__Username_ { slug } ->
            favoriteArticle sessionId
                slug
                model
                (\r -> send_ (PageMsg (Gen.Msg.Profile__UserId_ (Pages.Profile.UserId_.UpdatedArticle r))))

        ArticleUnfavorite_Profile__Username_ { slug } ->
            unfavoriteArticle sessionId
                slug
                model
                (\r -> send_ (PageMsg (Gen.Msg.Profile__UserId_ (Pages.Profile.UserId_.UpdatedArticle r))))

        ArticleFavorite_Home_ { slug } ->
            favoriteArticle sessionId
                slug
                model
                (\r -> send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.UpdatedArticle r))))

        ArticleUnfavorite_Home_ { slug } ->
            unfavoriteArticle sessionId
                slug
                model
                (\r -> send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.UpdatedArticle r))))

        ArticleFavorite_Article__Slug_ { slug } ->
            favoriteArticle sessionId
                slug
                model
                (\r -> send_ (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.GotArticle r))))

        ArticleUnfavorite_Article__Slug_ { slug } ->
            unfavoriteArticle sessionId
                slug
                model
                (\r -> send_ (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.GotArticle r))))

        ArticleCommentGet_Article__Slug_ { articleSlug } ->
            let
                res =
                    model.comments
                        |> Dict.get articleSlug
                        |> Maybe.map Dict.values
                        |> Maybe.map (List.sortBy .id)
                        |> Maybe.map List.reverse
                        |> Maybe.map Success
                        |> Maybe.withDefault (Success [])
            in
            send (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.GotComments res)))

        ArticleCommentCreate_Article__Slug_ { articleSlug, comment } ->
            let
                userM =
                    model |> getSessionUser sessionId
            in
            ( model, Time.now |> Task.perform (\t -> ArticleCommentCreated t userM clientId articleSlug comment) )

        ArticleCommentDelete_Article__Slug_ { articleSlug, commentId } ->
            let
                newComments =
                    model.comments
                        |> Dict.update articleSlug (Maybe.map (\comments -> Dict.remove commentId comments))
            in
            ( { model | comments = newComments }
            , send_ (PageMsg (Gen.Msg.Article__Slug_ (Pages.Article.Slug_.DeletedComment (Success commentId))))
            )

        ProfileGet_Profile__Username_ { userId } ->
            let
                subscribed =
                    model
                        |> getSessionUser sessionId
                        |> Maybe.map (\user -> user.following |> Set.member userId)
                        |> Maybe.withDefault False

                res =
                    profileByUsername subscribed userId model
                        |> Maybe.map Success
                        |> Maybe.withDefault (Failure [ "user not found" ])
            in
            send (PageMsg (Gen.Msg.Profile__UserId_ (Pages.Profile.UserId_.GotProfile res)))

        UserAuthentication_Login { params } ->
            let
                ( response, cmd ) =
                    model.users
                        |> Dict.find (\_ u -> u.username == params.username)
                        |> Maybe.map
                            (\( _, u ) ->
                                if u.password == params.password then
                                    ( Success (Api.User.toUser u), renewSession u.id sessionId clientId )

                                else
                                    ( Failure [ "email or password is invalid" ], Cmd.none )
                            )
                        |> Maybe.withDefault ( Failure [ "email or password is invalid" ], Cmd.none )
            in
            ( model, Cmd.batch [ send_ (PageMsg (Gen.Msg.Login (Pages.Login.GotUser response))), cmd ] )

        UserRegistration_Register { params } ->
            let
                ( model_, cmd, res ) =
                    if model.users |> Dict.any (\_ u -> u.username == params.username) then
                        ( model, Cmd.none, Failure [ "username already taken" ] )

                    else
                        let
                            user_ : UserFull
                            user_ =
                                { id = Dict.size model.users
                                , username = params.username
                                , bio = Nothing
                                , image = "https://static.productionready.io/images/smiley-cyrus.jpg"
                                , password = params.password
                                , favorites = []
                                , trackers = []
                                , following = Set.empty
                                }
                        in
                        ( { model | users = model.users |> Dict.insert user_.id user_ }
                        , renewSession user_.id sessionId clientId
                        , Success (Api.User.toUser user_)
                        )
            in
            ( model_, Cmd.batch [ cmd, send_ (PageMsg (Gen.Msg.Register (Pages.Register.GotUser res))) ] )

        UserUpdate_Settings { params } ->
            let
                ( model_, res ) =
                    case model |> getSessionUser sessionId of
                        Just user ->
                            let
                                user_ =
                                    { user
                                        | username = params.username

                                        -- , email = params.email
                                        , password = params.password |> Maybe.withDefault user.password
                                        , image = params.image
                                    }
                            in
                            ( model |> updateUser user_, Success (Api.User.toUser user_) )

                        Nothing ->
                            ( model, Failure [ "you do not have permission for this user" ] )
            in
            ( model_, send_ (PageMsg (Gen.Msg.Settings (Pages.Settings.GotUser res))) )

        AtHome (DraftUpdated draft) ->
            case model |> getSessionUser sessionId of
                Just user ->
                    ( { model
                        | drafts =
                            model.drafts
                                |> Dict.update user.id
                                    (\maybe ->
                                        if String.isEmpty draft.content then
                                            Nothing

                                        else
                                            maybe
                                                |> Maybe.map (Tuple.mapSecond (\_ -> draft))
                                                |> Maybe.withDefault ( model.hour, draft )
                                                |> Just
                                    )
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        AtProfile profile GetEntriesOfProfile ->
            model.entries
                |> Dict.get profile.userId
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
                Just user ->
                    ( { model
                        | users =
                            model.users
                                |> Dict.insert user.id
                                    { user
                                        | following =
                                            if user.following |> Set.member profile.userId then
                                                user.following |> Set.remove profile.userId

                                            else
                                                user.following |> Set.insert profile.userId
                                    }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        AtHome GetEntriesOfSubscribed ->
            case model |> getSessionUser sessionId of
                Just user ->
                    user.following
                        |> Set.toList
                        |> List.filterMap (\id -> model.users |> Dict.get id)
                        |> List.filterMap
                            (\u ->
                                model.entries
                                    |> Dict.get u.id
                                    |> Maybe.withDefault Dict.empty
                                    |> Dict.toList
                                    |> List.reverse
                                    |> List.head
                                    |> Maybe.map
                                        (\( millis, entry ) ->
                                            ( Api.User.toUser u, Time.millisToPosix millis, entry )
                                        )
                            )
                        |> (\entries ->
                                ( model
                                , send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.GotEntries entries)))
                                )
                           )

                Nothing ->
                    ( model, Cmd.none )

        AtHome GetDraft ->
            case model |> getSessionUser sessionId of
                Just user ->
                    model.drafts
                        |> Dict.get user.id
                        |> Maybe.map Tuple.second
                        |> Maybe.withDefault Data.Entry.newDraft
                        |> (\draft ->
                                ( model, send_ (PageMsg (Gen.Msg.Home_ (Pages.Home_.DraftUpdated draft))) )
                           )

                Nothing ->
                    ( model, Cmd.none )

        AtHome GetTrackers ->
            case model |> getSessionUser sessionId of
                Just user ->
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

                Nothing ->
                    ( model, Cmd.none )

        AtHome (AddTracker emoji) ->
            case model |> getSessionUser sessionId of
                Just user ->
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
                                            |> Dict.insert user.id
                                                { user | trackers = userTrackers }
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

                Nothing ->
                    ( model, Cmd.none )

        AtHome (RemoveTracker trackerId) ->
            case model |> getSessionUser sessionId of
                Just user ->
                    ( model.trackers |> Data.Store.remove trackerId
                    , user.trackers |> List.filter ((/=) trackerId)
                    )
                        |> (\( store, userTrackers ) ->
                                ( { model
                                    | trackers = store
                                    , users =
                                        model.users
                                            |> Dict.insert user.id
                                                { user | trackers = userTrackers }
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

                Nothing ->
                    ( model, Cmd.none )

        NoOpToBackend ->
            ( model, Cmd.none )


getSessionUser : SessionId -> Model -> Maybe UserFull
getSessionUser sid model =
    model.sessions
        |> Dict.get sid
        |> Maybe.andThen (\session -> model.users |> Dict.get session.userId)


renewSession email sid cid =
    Time.now |> Task.perform (RenewSession email sid cid)


getListing : Model -> SessionId -> Int -> Api.Article.Listing
getListing model sessionId page =
    let
        filtered =
            model.articles

        enriched =
            filtered |> Dict.map (\_ article -> loadArticleFromStore model (model |> getSessionUser sessionId) article)

        grouped =
            enriched |> Dict.values |> List.greedyGroupsOf Api.Article.itemsPerPage

        articles =
            grouped |> List.getAt (page - 1) |> Maybe.withDefault []
    in
    { articles = articles
    , page = page
    , totalPages = grouped |> List.length
    }


loadArticleBySlug : String -> SessionId -> Model -> Data Article
loadArticleBySlug slug sid model =
    model.articles
        |> Dict.get slug
        |> Maybe.map Success
        |> Maybe.withDefault (Failure [ "no article with slug: " ++ slug ])
        |> Api.Data.map (loadArticleFromStore model (model |> getSessionUser sid))


uniqueSlug : Model -> String -> Int -> String
uniqueSlug model title i =
    let
        slug =
            title |> String.replace " " "-"
    in
    if not (model.articles |> Dict.member slug) then
        slug

    else if not (model.articles |> Dict.member (slug ++ "-" ++ String.fromInt i)) then
        slug ++ "-" ++ String.fromInt i

    else
        uniqueSlug model title (i + 1)


favoriteArticle : SessionId -> Slug -> Model -> (Data Article -> Cmd msg) -> ( Model, Cmd msg )
favoriteArticle sessionId slug model toResponseCmd =
    let
        res =
            model
                |> loadArticleBySlug slug sessionId
                |> Api.Data.map (\a -> { a | favorited = True })
    in
    case model |> getSessionUser sessionId of
        Just user ->
            ( if model.articles |> Dict.member slug then
                model |> updateUser { user | favorites = (slug :: user.favorites) |> List.unique }

              else
                model
            , toResponseCmd res
            )

        Nothing ->
            ( model, toResponseCmd <| Failure [ "invalid session" ] )


unfavoriteArticle : SessionId -> Slug -> Model -> (Data Article -> Cmd msg) -> ( Model, Cmd msg )
unfavoriteArticle sessionId slug model toResponseCmd =
    let
        res =
            model
                |> loadArticleBySlug slug sessionId
                |> Api.Data.map (\a -> { a | favorited = False })
    in
    case model |> getSessionUser sessionId of
        Just user ->
            ( model |> updateUser { user | favorites = user.favorites |> List.remove slug }
            , toResponseCmd res
            )

        Nothing ->
            ( model, toResponseCmd <| Failure [ "invalid session" ] )


updateUser : UserFull -> Model -> Model
updateUser user model =
    { model | users = model.users |> Dict.update user.id (Maybe.map (always user)) }


profileByUsername subscribed userId model =
    model.users
        |> Dict.get userId
        |> Maybe.map (Api.User.toProfile subscribed)


loadArticleFromStore : Model -> Maybe UserFull -> ArticleStore -> Article
loadArticleFromStore model userM store =
    let
        favorited =
            userM |> Maybe.map (\user -> user.favorites |> List.member store.slug) |> Maybe.withDefault False

        author =
            model.users
                |> Dict.get store.userId
                |> Maybe.map (Api.User.toProfile False)
                |> Maybe.withDefault { username = "error: unknown user", bio = Nothing, image = "", following = False }
    in
    { slug = store.slug
    , title = store.title
    , description = store.description
    , tags = store.tags
    , createdAt = store.createdAt
    , updatedAt = store.updatedAt
    , favorited = favorited
    , favoritesCount = model.users |> Dict.filter (\_ user -> user.favorites |> List.member store.slug) |> Dict.size
    , author = author
    }
