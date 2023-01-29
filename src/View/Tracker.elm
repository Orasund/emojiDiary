module View.Tracker exposing (..)

import Data.Store exposing (Id)
import Data.Tracker exposing (Tracker)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events
import Layout
import View.Style


new : { onInput : String -> msg } -> Html msg
new args =
    [ View.Style.emojiInput { name = "Emoji", content = "", onInput = args.onInput }
    , "new Tracker" |> Html.text |> Layout.el [ Layout.alignAtCenter ]
    ]
        |> Layout.row [ Layout.spacing 8 ]


asRow :
    { onDelete : Id Tracker -> msg
    , onEdit : Tracker -> msg
    , onBlur : msg
    , onClick : String -> msg
    , focused : Bool
    }
    -> ( Id Tracker, Tracker )
    -> Html msg
asRow args ( id, tracker ) =
    [ View.Style.buttonText []
        { onPress = Just (args.onClick tracker.emoji)
        , label = tracker.emoji
        }
        |> Layout.el [ Attr.style "width" "50px" ]
    , if args.focused then
        View.Style.input
            [ Layout.fill
            , Html.Events.onBlur args.onBlur
            ]
            { name = "description"
            , content = tracker.description
            , onInput = \string -> args.onEdit { tracker | description = string }
            }

      else
        View.Style.buttonText [ Layout.fill ]
            { onPress = Just (args.onEdit tracker)
            , label = tracker.description
            }
    , View.Style.buttonText []
        { onPress = id |> args.onDelete |> Just
        , label = "Remove"
        }
    ]
        |> Layout.row [ Layout.spacing 8 ]


list :
    { onDelete : Id Tracker -> msg
    , onEdit : ( Int, Tracker ) -> msg
    , onBlur : Int -> msg
    , onClick : String -> msg
    , focusedTracker : Maybe Int
    }
    -> List ( Id Tracker, Tracker )
    -> Html msg
list args trackers =
    trackers
        |> List.indexedMap
            (\i ->
                asRow
                    { onDelete = args.onDelete
                    , onEdit = \tracker -> args.onEdit ( i, tracker )
                    , onBlur = args.onBlur i
                    , onClick = args.onClick
                    , focused = Just i == args.focusedTracker
                    }
            )
        |> Layout.column []
