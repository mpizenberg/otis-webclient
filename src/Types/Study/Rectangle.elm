module Types.Study.Rectangle exposing (..)

import Annotation exposing (Annotation)
import Image exposing (Image)
import DrawingArea.Viewer as Viewer exposing (Viewer)
import Json.Encode as Encode


type alias Rectangle =
    { annotations : List ( Int, Annotation )
    , nextId : Int
    , checked : Maybe Annotation.Check
    , viewer : Viewer
    , bgImage : Image
    }


init : Image -> Rectangle
init bgImage =
    { annotations = []
    , nextId = 0
    , checked = Nothing
    , viewer = Viewer.default
    , bgImage = bgImage
    }



-- ENCODE ############################################################


encode : Rectangle -> Encode.Value
encode rectangle =
    List.map Tuple.second rectangle.annotations
        |> List.map Annotation.encodePath
        |> Encode.list
