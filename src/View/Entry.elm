module View.Entry exposing (..)

import Api.User exposing (User)
import Data.Entry exposing (EntryContent)
import Html exposing (Html)
import Html.Attributes
import Layout
import Time exposing (Posix, Zone)
import View.Posix
import View.Style


draft : { onSubmit : EntryContent -> msg } -> EntryContent -> Html msg
draft args entryDraft =
    Layout.row [ Layout.noWrap, Layout.spacing 8 ]
        [ View.Style.emojiInput
            { name = "Mood"
            , content = entryDraft.content
            , onInput = \string -> { entryDraft | content = string } |> args.onSubmit
            }
        , View.Style.input
            { name = "Description"
            , content = entryDraft.description
            , onInput = \string -> { entryDraft | description = string } |> args.onSubmit
            }
        ]


withUser : Zone -> ( User, Posix, EntryContent ) -> Html msg
withUser zone ( user, timestamp, entry ) =
    Layout.row [ Layout.spacing 16 ]
        [ entry.content |> Html.text |> Layout.el []
        , entry.description |> Html.text |> Layout.el [ Layout.fill ]
        , user.username |> Html.text |> Layout.el []
        , View.Posix.asWeekday zone timestamp
            ++ ", "
            ++ View.Posix.asDate zone timestamp
            |> Html.text
            |> Layout.el []
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
