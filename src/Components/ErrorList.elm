module Components.ErrorList exposing (view)

import Html exposing (..)
import Layout
import View.Style


view : List String -> Html msg
view reasons =
    if List.isEmpty reasons then
        Layout.none

    else
        List.map (\message -> View.Style.error message) reasons
            |> Layout.column [ Layout.spacing 4 ]
