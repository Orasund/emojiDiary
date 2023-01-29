module View.Date exposing (..)

import Data.Date exposing (Date)
import Time exposing (Month(..), Posix, Weekday(..), Zone)


asTime : Zone -> Posix -> String
asTime zone posix =
    String.fromInt (Time.toHour zone posix)
        ++ ":"
        ++ String.fromInt (Time.toMinute zone posix)


weekdayToString : Weekday -> String
weekdayToString weekday =
    case weekday of
        Mon ->
            "Monday"

        Tue ->
            "Tuesday"

        Wed ->
            "Wednesday"

        Thu ->
            "Thursday"

        Fri ->
            "Friday"

        Sat ->
            "Saturday"

        Sun ->
            "Sunday"


asMonth : Date -> String
asMonth date =
    case date.month of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "november"

        Dec ->
            "december"


toString : Date -> String
toString date =
    (date.day |> String.fromInt)
        ++ ". "
        ++ asMonth date
