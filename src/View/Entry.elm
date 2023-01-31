module View.Entry exposing (..)

import Data.Date exposing (Date)
import Data.Entry exposing (EntryContent)
import Data.User exposing (UserInfo)
import Html exposing (Html)
import Html.Events
import Layout
import Time exposing (Posix, Zone)
import Time.Extra exposing (Interval(..))
import View.Date
import View.Style


draft : { onSubmit : EntryContent -> msg, onBlur : msg, zone : Zone } -> Maybe ( Posix, Zone, EntryContent ) -> Html msg
draft args maybe =
    let
        entryDraft =
            maybe
                |> Maybe.map (\( _, _, d ) -> d)
                |> Maybe.withDefault Data.Entry.newDraft
    in
    [ [ [ View.Style.emojiInput
            { name = "Mood"
            , content = entryDraft.content
            , onInput = \string -> { entryDraft | content = string } |> args.onSubmit
            }
        , maybe
            |> Maybe.map
                (\( p, z, _ ) ->
                    "For "
                        ++ View.Date.toString (Data.Date.fromPosix z p |> Data.Date.toDate)
                        |> Html.text
                        |> Layout.el []
                )
            |> Maybe.withDefault Layout.none
        ]
            |> Layout.row [ Layout.spaceBetween ]
      , View.Style.input [ Html.Events.onBlur args.onBlur ]
            { name = "Description"
            , content = entryDraft.description
            , onInput = \string -> { entryDraft | description = string } |> args.onSubmit
            }
      ]
        |> Layout.column [ Layout.noWrap, Layout.spacing 8 ]
    ]
        |> Layout.column []


withUser : ( UserInfo, Date, EntryContent ) -> Html msg
withUser ( user, date, entry ) =
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
