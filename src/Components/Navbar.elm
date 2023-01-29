module Components.Navbar exposing (view)

import Data.User exposing (UserInfo)
import Gen.Route as Route exposing (Route)
import Html exposing (..)
import Html.Attributes as Attr
import Layout
import View.Style


view :
    { user : Maybe UserInfo
    , currentRoute : Route
    , onSignOut : msg
    }
    -> Html msg
view options =
    [ Html.img [ Attr.src "favicon.svg", Attr.width 30, Attr.height 30 ] []
    , text "Emoji Diary" |> Layout.el [ Attr.class "text-xl", Layout.fill ]
    , case options.user of
        Just user ->
            [ [ ( "Home", Route.Home_ )
              , ( "Profile", Route.Profile__UserId_ { userId = user.username } )
              , ( "Settings", Route.Settings )
              ]
                |> List.map (viewLink options.currentRoute)
                |> ul [ Attr.class "menu p-2 menu-horizontal bg-base-100 rounded-box" ]
            , View.Style.buttonText []
                { onPress = Just options.onSignOut
                , label = "Sign out"
                }
            ]
                |> Layout.row [ Layout.spacing 16 ]

        Nothing ->
            [ ( "Home", Route.Home_ )
            , ( "Sign in", Route.Login )
            , ( "Sign up", Route.Register )
            ]
                |> List.map (viewLink options.currentRoute)
                |> ul [ Attr.class "menu p-2 menu-horizontal bg-base-100 rounded-box" ]
    ]
        |> Layout.row [ Attr.class "navbar bg-base-100", Layout.spacing 16 ]


viewLink : Route -> ( String, Route ) -> Html msg
viewLink currentRoute ( label, route ) =
    li [ Attr.class "nav-item" ]
        [ a
            [ Attr.class "nav-link"
            , Attr.classList [ ( "active", currentRoute == route ) ]
            , Attr.href (Route.toHref route)
            ]
            [ text label ]
        ]
