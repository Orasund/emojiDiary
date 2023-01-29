module Pages.Register exposing (Model, Msg(..), page)

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
    , email : String
    , password : String
    , password2 : String
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
        ""
        ""
    , Effect.none
    )



-- UPDATE


type Msg
    = Updated Field String
    | AttemptedSignUp
    | GotUser (Data UserInfo)


type Field
    = Username
    | Password
    | Password2


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

        Updated Password2 password2 ->
            ( { model | password2 = password2 }
            , Effect.none
            )

        AttemptedSignUp ->
            if model.password == model.password2 then
                ( model
                , (Effect.fromCmd << sendToBackend) <|
                    UserRegistration_Register
                        { params =
                            { username = model.username
                            , email = model.email
                            , password = model.password
                            }
                        }
                )

            else
                ( { model | user = Api.Data.Failure [ "Password fields don't match" ] }, Effect.none )

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
    { title = "Sign up"
    , body =
        [ View.Style.sectionHeading "Sign Up"
        , [ Html.text "Already have an account?"
                |> Layout.linkTo (Route.toHref Route.Login) []
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
          , View.Style.inputWithType
                { name = "Password Repeated"
                , content = model.password2
                , onInput = Updated Password2
                , type_ = "password"
                }
          ]
            |> Layout.column [ Layout.spacing 8 ]
        , View.Style.button
            { onPress = Just AttemptedSignUp
            , label = "Sign up"
            }
        ]
            |> Layout.column [ Layout.spacing 32 ]
            |> List.singleton
            |> Html.form [ Html.Events.onSubmit AttemptedSignUp ]
            |> View.Style.hero
            |> List.singleton
    }
