module View.Entry exposing (..)

import Data.Entry exposing (EntryDraft)
import Html exposing (Html)
import Html.Attributes
import Layout
import View.Style


draft : { onSubmit : EntryDraft -> msg } -> EntryDraft -> Html msg
draft args entryDraft =
    Layout.column []
        [ View.Style.heading "How was your day?"
        , Layout.row [ Layout.noWrap, Layout.spacing 8 ]
            [ View.Style.input
                { name = "How do you feel?"
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
