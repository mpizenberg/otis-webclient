module Types.Study.Outline exposing (..)

import Annotation exposing (Annotation)
import Pointer
import Image exposing (Image)
import DrawingArea.Viewer as Viewer exposing (Viewer)
import Json.Encode as Encode


type alias Outline =
    { annotations : List ( Int, Annotation )
    , nextId : Int
    , checked : Maybe Annotation.Check
    , viewer : Viewer
    , bgImage : Image
    }


init : Image -> Outline
init bgImage =
    { annotations = []
    , nextId = 0
    , checked = Nothing
    , viewer = Viewer.default
    , bgImage = bgImage
    }



-- ENCODE ############################################################


encode : Outline -> Encode.Value
encode outline =
    List.map Tuple.second outline.annotations
        |> List.map Annotation.encodePath
        |> Encode.list
