module Evergreen.V4.Data.Store exposing (..)

import Dict


type Id a
    = Id Int


type alias Store a =
    { items : Dict.Dict Int a
    , nextId : Int
    }
