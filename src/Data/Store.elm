module Data.Store exposing (Id, Store, empty, get, insert, remove)

import Dict exposing (Dict)


type Id a
    = Id Int


type alias Store a =
    { items : Dict Int a
    , nextId : Int
    }


empty : Store a
empty =
    { items = Dict.empty
    , nextId = 0
    }


insert : a -> Store a -> ( Store a, Id a )
insert a store =
    ( { items = store.items |> Dict.insert store.nextId a
      , nextId = store.nextId + 1
      }
    , Id store.nextId
    )


remove : Id a -> Store a -> Store a
remove (Id key) store =
    { store | items = store.items |> Dict.remove key }


get : Id a -> Store a -> Maybe a
get (Id key) store =
    store.items |> Dict.get key
