module Gen.Params.Profile.UserId_ exposing (Params, parser)

import Url.Parser as Parser exposing ((</>), Parser)


type alias Params =
    { userId : String }


parser =
    Parser.map Params (Parser.s "profile" </> Parser.string)

