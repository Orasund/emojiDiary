module Data.Date exposing (..)

import Array exposing (Array)
import Time exposing (Month(..), Posix, Weekday(..), Zone)


type alias DateTriple =
    ( Int, Int, ( Int, Int ) )


type alias Date =
    { year : Int, month : Month, day : Int, weekday : Weekday }


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


months : Array Month
months =
    [ Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec ]
        |> Array.fromList


intToMonth : Int -> Month
intToMonth int =
    months |> Array.get (int - 1) |> Maybe.withDefault Jan


weekdayToInt : Weekday -> Int
weekdayToInt weekday =
    case weekday of
        Mon ->
            1

        Tue ->
            2

        Wed ->
            3

        Thu ->
            4

        Fri ->
            5

        Sat ->
            6

        Sun ->
            7


weekdays : Array Weekday
weekdays =
    [ Mon, Tue, Wed, Thu, Fri, Sat, Sun ]
        |> Array.fromList


intToWeekday : Int -> Weekday
intToWeekday int =
    weekdays
        |> Array.get (int - 1)
        |> Maybe.withDefault Mon


fromPosix : Zone -> Posix -> DateTriple
fromPosix zone posix =
    ( Time.toYear zone posix
    , Time.toMonth zone posix |> monthToInt
    , ( Time.toDay zone posix
      , Time.toWeekday zone posix |> weekdayToInt
      )
    )


toDate : DateTriple -> Date
toDate ( year, month, ( day, weekday ) ) =
    { year = year
    , month = intToMonth month
    , day = day
    , weekday = intToWeekday weekday
    }
