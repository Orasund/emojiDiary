module View.Style exposing (..)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import Layout


sectionHeading : String -> Html msg
sectionHeading string =
    Html.text string
        |> Layout.heading3
            [ Attr.style "font-size" "24px"
            ]


itemHeading : String -> Html msg
itemHeading string =
    Html.text string
        |> Layout.heading4 [ Attr.style "font-weight" "bold" ]


emojiInput : { name : String, content : String, onInput : String -> msg } -> Html msg
emojiInput args =
    [ Html.span [] [ Layout.el [ Attr.class "bi bi-emoji-smile" ] Layout.none ]
    , Html.input
        [ Attr.class "input w-full max-w-xs"
        , Attr.placeholder args.name
        , Attr.type_ "text"
        , Attr.value args.content
        , Events.onInput args.onInput
        ]
        []
    ]
        |> Html.label [ Attr.class "input-group" ]
        |> Layout.el [ Attr.style "width" "130px" ]


hero : Html msg -> Html msg
hero content =
    content
        |> Layout.el
            (Layout.centered
                ++ [ Attr.class "bg-accent"
                   , Attr.style "padding-top" "64px"
                   , Attr.style "padding-bottom" "64px"
                   , Attr.style "width" "100%"
                   ]
            )


input : { name : String, content : String, onInput : String -> msg } -> Html msg
input args =
    Html.input
        [ Attr.class "input w-full max-w-xs"
        , Attr.placeholder args.name
        , Attr.type_ "text"
        , Attr.value args.content
        , Events.onInput args.onInput
        ]
        []
        |> Layout.el []


inputWithType : { name : String, content : String, onInput : String -> msg, type_ : String } -> Html msg
inputWithType args =
    Html.input
        [ Attr.class "input w-full max-w-xs"
        , Attr.placeholder args.name
        , Attr.type_ args.type_
        , Attr.value args.content
        , Events.onInput args.onInput
        ]
        []
        |> Layout.el []


button : { onPress : Maybe msg, label : String } -> Html msg
button args =
    Html.text args.label
        |> Layout.buttonEl { onPress = args.onPress, label = args.label }
            [ Attr.class "btn btn-primary" ]


buttonText : { onPress : Maybe msg, label : String } -> Html msg
buttonText args =
    Html.text args.label
        |> Layout.buttonEl { onPress = args.onPress, label = args.label }
            [ Attr.class "btn btn-ghost" ]


error : String -> Html msg
error err =
    Html.text err
        |> List.singleton
        |> Html.span []
        |> Layout.el [ Attr.class "alert alert-error shadow-lg" ]


container : List (Attribute msg)
container =
    [ Attr.style "width" "800px", Layout.centerContent ]
