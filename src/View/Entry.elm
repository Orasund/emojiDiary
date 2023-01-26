module View.Entry exposing (..)

import Data.Entry exposing (EntryContent)
import Html exposing (Html)
import Html.Attributes
import Layout
import Time exposing (Posix, Zone)
import View.Posix
import View.Style


draft : { onSubmit : EntryContent -> msg } -> EntryContent -> Html msg
draft args entryDraft =
    Layout.column []
        [ View.Style.heading "How was your day?"
        , Layout.row [ Layout.noWrap, Layout.spacing 8 ]
            [ View.Style.input
                { name = "Emoji"
                , content = entryDraft.content
                , onInput = \string -> { entryDraft | content = string } |> args.onSubmit
                }
                |> Layout.el [ Html.Attributes.style "width" "100px" ]
            , View.Style.input
                { name = "Description"
                , content = entryDraft.description
                , onInput = \string -> { entryDraft | description = string } |> args.onSubmit
                }
            ]
        ]


toHtml : Zone -> Posix -> EntryContent -> Html msg
toHtml zone timestamp entry =
    Layout.row [ Layout.spacing 16 ]
        [ entry.content |> Html.text |> Layout.el []
        , entry.description |> Html.text |> Layout.el [ Layout.fill ]
        , View.Posix.asWeekday zone timestamp
            ++ ", "
            ++ View.Posix.asDate zone timestamp
            |> Html.text
            |> Layout.el []
        ]
