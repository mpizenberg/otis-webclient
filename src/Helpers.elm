module Helpers exposing (..)


logAndReturn : String -> msg -> a -> a
logAndReturn name msg value =
    let
        _ =
            Debug.log name msg
    in
        value
