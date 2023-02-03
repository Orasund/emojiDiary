module Pages.Login exposing (Model, Msg(..), page)

import Api.Data exposing (Data)
import Bridge exposing (..)
import Components.ErrorList
import Data.User exposing (UserInfo)
import Effect exposing (Effect)
import Gen.Route as Route
import Html
import Html.Events
import Layout
import Page
import Pages.Register exposing (Msg(..))
import Request exposing (Request)
import Shared
import Utils.Route
import View exposing (View)
import View.Style


page : Shared.Model -> Request -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared
        , update = update req
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { user : Data UserInfo
    , username : String
    , password : String
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( Model
        (case shared.user of
            Just user ->
                Api.Data.Success user

            Nothing ->
                Api.Data.NotAsked
        )
        ""
        ""
    , Effect.none
    )



-- UPDATE


type Msg
    = Updated Field String
    | AttemptedSignIn
    | GotUser (Data UserInfo)


type Field
    = Username
    | Password


update : Request -> Msg -> Model -> ( Model, Effect Msg )
update req msg model =
    case msg of
        Updated Username username ->
            ( { model | username = username }
            , Effect.none
            )

        Updated Password password ->
            ( { model | password = password }
            , Effect.none
            )

        AttemptedSignIn ->
            ( model
            , (Effect.fromCmd << sendToBackend) <|
                UserAuthentication_Login
                    { params =
                        { username = model.username
                        , password = model.password
                        }
                    }
            )

        GotUser user ->
            case Api.Data.toMaybe user of
                Just user_ ->
                    ( { model | user = user }
                    , Effect.batch
                        [ Effect.fromCmd (Utils.Route.navigate req.key Route.Home_)
                        , Effect.fromShared (Shared.SignedInUser user_)
                        ]
                    )

                Nothing ->
                    ( { model | user = user }
                    , Effect.none
                    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Sign in"
    , body =
        [ View.Style.sectionHeading "Sign in"
        , [ Html.text "Don't have an account?"
                |> View.Style.linkTo (Route.toHref Route.Register)
          , case model.user of
                Api.Data.Failure reasons ->
                    Components.ErrorList.view reasons

                _ ->
                    Layout.none
          , View.Style.inputWithType
                { name = "Username"
                , content = model.username
                , onInput = Updated Username
                , type_ = "username"
                }
          , View.Style.inputWithType
                { name = "Password"
                , content = model.password
                , onInput = Updated Password
                , type_ = "password"
                }
          ]
            |> Layout.column [ Layout.spacing 8 ]
        , View.Style.button
            { onPress = Just AttemptedSignIn
            , label = "Sign in"
            }
        ]
            |> Layout.column [ Layout.spacing 32 ]
            |> List.singleton
            |> Html.form [ Html.Events.onSubmit AttemptedSignIn ]
            |> View.Style.hero
            |> List.singleton
    }
