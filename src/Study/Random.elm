module Study.Random exposing (..)

import Types.Study.Resources as Resources exposing (ToolType(..), RandomConfig)
import Random exposing (Generator)


config : Int -> Int -> Int -> Generator RandomConfig
config nbRectangle nbOutline nbScribbles =
    Random.map4 RandomConfig
        (toolOrder)
        (order nbRectangle)
        (order nbOutline)
        (order nbScribbles)


toolOrder : Generator ( ToolType, ToolType, ToolType )
toolOrder =
    let
        matchTool : ( Float, Float, Float ) -> List ToolType
        matchTool ( x, y, z ) =
            [ ( x, Rectangle )
            , ( y, Outline )
            , ( z, Scribbles )
            ]
                |> List.sortBy Tuple.first
                |> List.map Tuple.second

        tuplify : List ToolType -> ( ToolType, ToolType, ToolType )
        tuplify tools =
            case tools of
                tool1 :: tool2 :: tool3 :: [] ->
                    ( tool1, tool2, tool3 )

                _ ->
                    ( Rectangle, Outline, Scribbles )
    in
        Random.map3 (,,)
            (Random.float 0 1)
            (Random.float 0 1)
            (Random.float 0 1)
            |> Random.map (matchTool >> tuplify)


order : Int -> Generator (List Int)
order n =
    Random.list n (Random.float 0 1)
        |> Random.map
            (List.indexedMap (,)
                >> List.sortBy Tuple.second
                >> List.map Tuple.first
            )
