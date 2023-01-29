module View.Entry exposing (..)

import Config
import Data.Date exposing (Date)
import Data.Entry exposing (EntryContent)
import Data.User exposing (UserInfo)
import Html exposing (Html)
import Html.Attributes as Attr
import Layout
import Time exposing (Posix, Zone)
import Time.Extra exposing (Interval(..))
import View.Date
import View.Style


draft : { onSubmit : EntryContent -> msg, zone : Zone } -> Maybe ( Posix, Zone, EntryContent ) -> Html msg
draft args maybe =
    let
        entryDraft =
            maybe
                |> Maybe.map (\( _, _, d ) -> d)
                |> Maybe.withDefault Data.Entry.newDraft
    in
    [ Layout.row [ Layout.noWrap, Layout.spacing 8 ]
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
    ]
        |> Layout.column []


withUser : Zone -> ( UserInfo, Date, EntryContent ) -> Html msg
withUser zone ( user, date, entry ) =
    Layout.row [ Layout.spacing 16 ]
        [ entry.content |> Html.text |> Layout.el []
        , entry.description |> Html.text |> Layout.el [ Layout.fill ]
        , user.username |> Html.text |> Layout.el []
        , View.Date.weekdayToString date.weekday
            ++ ", "
            ++ View.Date.toString date
            |> Html.text
            |> Layout.el []
        ]


toHtml : Date -> EntryContent -> Html msg
toHtml date entry =
    Layout.row [ Layout.spacing 16 ]
        [ entry.content |> Html.text |> Layout.el []
        , entry.description |> Html.text |> Layout.el [ Layout.fill ]
        , View.Date.weekdayToString date.weekday
            ++ ", "
            ++ View.Date.toString date
            |> Html.text
            |> Layout.el []
        ]
