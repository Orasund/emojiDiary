module View.Style exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Layout


heading : String -> Html msg
heading string =
    Html.text string
        |> Layout.el
            [ Attr.style "font-weight" "bold"
            , Attr.style "padding-bottom" "8px"
            ]


input : { name : String, content : String, onInput : String -> msg } -> Html msg
input args =
    Html.input
        [ Attr.class "form-control"
        , Attr.placeholder args.name
        , Attr.type_ "text"
        , Attr.value args.content
        , Events.onInput args.onInput
        ]
        []


button : { onPress : Maybe msg, label : String } -> Html msg
button args =
    Html.text args.label
        |> Layout.buttonEl { onPress = args.onPress, label = args.label }
            [ Attr.class "btn btn-primary" ]


buttonText : { onPress : Maybe msg, label : String } -> Html msg
buttonText args =
    Html.text args.label
        |> Layout.buttonEl { onPress = args.onPress, label = args.label }
            [ Attr.class "btn btn-link" ]
