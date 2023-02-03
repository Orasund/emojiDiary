module Data.Store exposing (Id, Store, empty, get, insert, insertAll, read, remove, toList, unsafeWrite, update)

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


insertAll : List a -> Store a -> ( Store a, List (Id a) )
insertAll list store =
    list
        |> List.foldl
            (\a ( s, l ) ->
                s
                    |> insert a
                    |> Tuple.mapSecond (\head -> head :: l)
            )
            ( store, [] )


update : Id a -> (a -> a) -> Store a -> Store a
update (Id key) fun store =
    { store
        | items =
            store.items
                |> Dict.update key (Maybe.map fun)
    }


remove : Id a -> Store a -> Store a
remove (Id key) store =
    { store | items = store.items |> Dict.remove key }


get : Id a -> Store a -> Maybe a
get (Id key) store =
    store.items |> Dict.get key


read : Id a -> Int
read (Id key) =
    key


toList : Store a -> List ( Id a, a )
toList store =
    store.items |> Dict.toList |> List.map (Tuple.mapFirst Id)


unsafeWrite : Int -> Id a
unsafeWrite key =
    Id key
