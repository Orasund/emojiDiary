module Shared exposing
    ( Flags
    , Model
    , Msg(..)
    , init
    , subscriptions
    , update
    , view
    )

import Api.User exposing (User)
import Bridge exposing (..)
import Components.Navbar
import Html exposing (..)
import Html.Attributes exposing (href, rel)
import Layout
import Request exposing (Request)
import Task
import Time exposing (Zone)
import Utils.Route
import View exposing (View)
import View.Style



-- INIT


type alias Flags =
    ()


type alias Model =
    { user : Maybe User
    , error : Maybe String
    , zone : Zone
    }


init : Request -> Flags -> ( Model, Cmd Msg )
init _ _ =
    ( { user = Nothing
      , zone = Time.utc
      , error = Nothing
      }
    , Task.perform GotZone Time.here
    )



-- UPDATE


type Msg
    = ClickedSignOut
    | SignedInUser User
    | GotError String
    | GotZone Zone


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SignedInUser user ->
            ( { model | user = Just user }
            , Cmd.none
            )

        ClickedSignOut ->
            ( { model | user = Nothing }
            , model.user |> Maybe.map (\user -> sendToBackend (SignedOut user)) |> Maybe.withDefault Cmd.none
            )

        GotError string ->
            ( { model | error = Just string }, Cmd.none )

        GotZone zone ->
            ( { model | zone = zone }, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none



-- VIEW


view :
    Request
    -> { page : View msg, toMsg : Msg -> msg }
    -> Model
    -> View msg
view req { page, toMsg } model =
    { title =
        if String.isEmpty page.title then
            "Emoji Diary"

        else
            page.title ++ " | Emoji Diary"
    , body =
        css
            ++ [ [ Components.Navbar.view
                    { user = model.user
                    , currentRoute = Utils.Route.fromUrl req.url
                    , onSignOut = toMsg ClickedSignOut
                    }
                 , model.error
                    |> Maybe.map View.Style.error
                    |> Maybe.withDefault Layout.none
                 ]
                    ++ page.body
                    |> Layout.column [ Layout.fill, Html.Attributes.attribute "data-theme" "lemonade" ]
               ]
    }


css =
    -- Import Ionicon icons & Google Fonts our Bootstrap theme relies on
    [ Html.node "link" [ rel "stylesheet", href "https://cdn.jsdelivr.net/npm/daisyui@2.49.0/dist/full.css" ] []
    , Html.node "link" [ rel "stylesheet", href "https://cdn.jsdelivr.net/npm/tailwindcss@2.2/dist/tailwind.min.css" ] []
    , Html.node "link" [ rel "stylesheet", href "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.3/font/bootstrap-icons.css" ] []
    ]
