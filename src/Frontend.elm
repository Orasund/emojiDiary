module Frontend exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation as Nav exposing (Key)
import Config
import Dict
import Effect
import Gen.Model
import Gen.Pages as Pages
import Gen.Route as Route
import Lamdera
import Request
import Shared
import Task
import Types exposing (FrontendModel, FrontendMsg(..), ToFrontend(..))
import Url exposing (Url)
import View


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


init : Url -> Key -> ( Model, Cmd Msg )
init url key =
    let
        ( shared, sharedCmd ) =
            Shared.init (Request.create () url key) ()

        route =
            Route.fromUrl url

        href =
            Route.toHref route

        ( page, effect ) =
            Pages.init route shared url key
    in
    ( { url = url
      , key = key
      , shared = shared
      , pages = Dict.singleton href page
      , page = href
      }
    , Cmd.batch
        [ Cmd.map Shared sharedCmd
        , Effect.toCmd ( Shared, Page ) effect
        ]
    )



-- UPDATE


scrollPageToTop =
    Task.perform (\_ -> Noop) (Browser.Dom.setViewport 0 0)


type alias Msg =
    FrontendMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink (Browser.Internal url) ->
            ( model
            , Nav.pushUrl model.key (Url.toString url)
            )

        ClickedLink (Browser.External url) ->
            ( model
            , Nav.load url
            )

        ChangedUrl url ->
            if url.path /= model.url.path then
                let
                    route =
                        Route.fromUrl url

                    href =
                        Route.toHref route

                    ( page, effect ) =
                        case model.pages |> Dict.get href of
                            Just p ->
                                ( p, Effect.none )

                            Nothing ->
                                Pages.init (Route.fromUrl url) model.shared url model.key
                in
                ( { model
                    | url = url
                    , pages = model.pages |> Dict.insert href page
                    , page = href
                    , shared =
                        model.shared
                            |> (\m -> { m | error = Nothing })
                  }
                , Cmd.batch [ Effect.toCmd ( Shared, Page ) effect, scrollPageToTop ]
                )

            else
                ( { model | url = url }, Cmd.none )

        Shared sharedMsg ->
            let
                ( shared, sharedCmd ) =
                    Shared.update (Request.create () model.url model.key) sharedMsg model.shared

                ( page, effect ) =
                    Pages.init (Route.fromUrl model.url) shared model.url model.key
            in
            if page == Gen.Model.Redirecting_ then
                ( { model
                    | shared = shared
                    , pages = model.pages |> Dict.insert Config.redirectHref page
                    , page = Config.redirectHref
                  }
                , Cmd.batch
                    [ Cmd.map Shared sharedCmd
                    , Effect.toCmd ( Shared, Page ) effect
                    ]
                )

            else
                ( { model | shared = shared }
                , Cmd.map Shared sharedCmd
                )

        Page pageMsg ->
            let
                m =
                    model.pages
                        |> Dict.get model.page
                        --Dead Branch
                        |> Maybe.withDefault Gen.Model.Redirecting_

                ( page, effect ) =
                    Pages.update pageMsg m model.shared model.url model.key
            in
            ( { model | pages = model.pages |> Dict.insert model.page page }
            , Effect.toCmd ( Shared, Page ) effect
            )

        Noop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        ActiveSession user ->
            update (Shared <| Shared.SignedInUser user) model

        PageMsg pageMsg ->
            update (Page pageMsg) model

        SharedMsg sharedMsg ->
            update (Shared sharedMsg) model

        NoOpToFrontend ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    Shared.view (Request.create () model.url model.key)
        { page =
            model.pages
                |> Dict.get model.page
                --Dead Branch
                |> Maybe.withDefault Gen.Model.Redirecting_
                |> (\p ->
                        Pages.view p model.shared model.url model.key
                   )
                |> View.map Page
        , toMsg = Shared
        }
        model.shared



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    model.pages
        |> Dict.get model.page
        |> Maybe.map (\p -> Pages.subscriptions p model.shared model.url model.key |> Sub.map Page)
        |> Maybe.map List.singleton
        |> Maybe.withDefault []
        |> (::) (Shared.subscriptions (Request.create () model.url model.key) model.shared |> Sub.map Shared)
        |> Sub.batch
