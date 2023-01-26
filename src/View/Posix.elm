module View.Posix exposing (..)

import Time exposing (Month(..), Posix, Weekday(..), Zone)


asWeekday : Zone -> Posix -> String
asWeekday zone posix =
    case Time.toWeekday zone posix of
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


asMonth : Zone -> Posix -> String
asMonth zone posix =
    case Time.toMonth zone posix of
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


asDate : Zone -> Posix -> String
asDate zone posix =
    (posix |> Time.toDay zone |> String.fromInt)
        ++ ". "
        ++ asMonth zone posix
