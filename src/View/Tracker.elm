module View.Tracker exposing (..)

import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Html exposing (Html)
import Html.Attributes as Attr
import Layout
import View.Style


new : { onInput : String -> msg } -> Html msg
new args =
    [ View.Style.emojiInput { name = "Emoji", content = "", onInput = args.onInput }
    , "new Tracker" |> Html.text |> Layout.el [ Layout.alignAtCenter ]
    ]
        |> Layout.row [ Layout.spacing 8 ]


asRow : { onDelete : Id Tracker -> msg, onClick : String -> msg } -> ( Id Tracker, Tracker ) -> Html msg
asRow args ( id, tracker ) =
    [ View.Style.buttonText
        { onPress = Just (args.onClick tracker.emoji)
        , label = tracker.emoji
        }
        |> Layout.el [ Attr.style "width" "50px" ]
    , tracker.description
        |> Html.text
        |> Layout.el [ Layout.fill, Layout.alignAtCenter ]
    , View.Style.buttonText
        { onPress = id |> args.onDelete |> Just
        , label = "Remove"
        }
    ]
        |> Layout.row [ Layout.spacing 8 ]


list : { onDelete : Id Tracker -> msg, onClick : String -> msg } -> List ( Id Tracker, Tracker ) -> Html msg
list args trackers =
    trackers
        |> List.map (asRow args)
        |> Layout.column []
