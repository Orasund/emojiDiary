module Evergreen.V4.Data.Date exposing (..)

import Time


type alias Date =
    { year : Int
    , month : Time.Month
    , day : Int
    , weekday : Time.Weekday
    }


type alias DateTriple =
    ( Int, Int, ( Int, Int ) )
