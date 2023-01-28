module Components.Navbar exposing (view)

import Api.User exposing (User)
import Gen.Route as Route exposing (Route)
import Html exposing (..)
import Html.Attributes exposing (class, classList, href)
import Html.Events as Events
import Layout
import View.Style


view :
    { user : Maybe User
    , currentRoute : Route
    , onSignOut : msg
    }
    -> Html msg
view options =
    [ text "Emoji Diary" |> Layout.el [ class "text-xl", Layout.fill ]
    , case options.user of
        Just user ->
            [ [ ( "Home", Route.Home_ )
              , ( "Profile", Route.Profile__UserId_ { userId = user.username } )
              , ( "Settings", Route.Settings )
              ]
                |> List.map (viewLink options.currentRoute)
                |> ul [ class "menu p-2 menu-horizontal bg-base-100 rounded-box" ]
            , View.Style.buttonText
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
                |> ul [ class "menu p-2 menu-horizontal bg-base-100 rounded-box" ]
    ]
        |> Layout.row [ class "navbar bg-base-100" ]


viewLink : Route -> ( String, Route ) -> Html msg
viewLink currentRoute ( label, route ) =
    li [ class "nav-item" ]
        [ a
            [ class "nav-link"
            , classList [ ( "active", currentRoute == route ) ]
            , href (Route.toHref route)
            ]
            [ text label ]
        ]
