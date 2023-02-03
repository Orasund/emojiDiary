module View.Entry exposing (..)

import Data.Date exposing (Date)
import Data.Entry exposing (EntryContent)
import Data.User exposing (UserInfo)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events
import Layout
import Time exposing (Posix, Zone)
import Time.Extra exposing (Interval(..))
import View.Date
import View.Style


draft : { onSubmit : EntryContent -> msg, onBlur : msg, zone : Zone } -> Maybe ( Maybe Posix, Zone, EntryContent ) -> Html msg
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
            |> Maybe.andThen
                (\( p, z, _ ) ->
                    p
                        |> Maybe.map (Data.Date.fromPosix z)
                        |> Maybe.map Data.Date.toDate
                        |> Maybe.map View.Date.toString
                        |> Maybe.map
                            (\date ->
                                "For "
                                    ++ date
                                    |> Html.text
                                    |> Layout.el []
                            )
                )
            |> Maybe.withDefault Layout.none
        ]
            |> Layout.row [ Layout.spaceBetween ]
      , View.Style.input [ Html.Events.onBlur args.onBlur ]
            { name = "Description"
            , content = entryDraft.description
            , onInput = \string -> { entryDraft | description = string } |> args.onSubmit
            }
      , View.Style.input [ Html.Events.onBlur args.onBlur ]
            { name = "Link"
            , content = entryDraft.link |> Maybe.withDefault ""
            , onInput =
                \string ->
                    { entryDraft
                        | link =
                            if string == "" then
                                Nothing

                            else
                                Just string
                    }
                        |> args.onSubmit
            }
      ]
        |> Layout.column [ Layout.noWrap, Layout.spacing 8 ]
    ]
        |> Layout.column []


toHtml : Maybe UserInfo -> Date -> EntryContent -> Html msg
toHtml user date entry =
    Layout.row [ Layout.spacing 16 ]
        [ entry.content |> Html.text |> Layout.el []
        , entry.description |> Html.text |> Layout.el [ Layout.fill ]
        , entry.link
            |> Maybe.map
                (\link ->
                    [ Layout.el [ Attr.class "bi bi-link-45deg", Layout.alignCenter ] Layout.none
                    , "Link"
                        |> Html.text
                        |> View.Style.linkToNewTab link
                    ]
                        |> Layout.row []
                )
            |> Maybe.withDefault Layout.none
        , user
            |> Maybe.map (\{ username } -> username |> Html.text |> Layout.el [])
            |> Maybe.withDefault Layout.none
        , View.Date.weekdayToString date.weekday
            ++ ", "
            ++ View.Date.toString date
            |> Html.text
            |> Layout.el []
        ]
