module Types.Study.Scribbles exposing (..)

import Annotation exposing (Annotation)
import Pointer
import Image exposing (Image)
import DrawingArea.Viewer as Viewer exposing (Viewer)
import Tool exposing (Tool)
import Json.Encode as Encode


type alias Scribbles =
    { viewer : Viewer
    , bgImage : Image
    , checked : Maybe Annotation.Check
    , visibleAnnotations : List ( Int, Annotation )
    , deletedAnnotations : List ( Int, Annotation )
    , nextId : Int
    , currentTool : Tool
    }


encodeAnnotations : List ( Int, Annotation ) -> Encode.Value
encodeAnnotations annotations =
    List.map Tuple.second annotations
        |> List.map Annotation.encodePath
        |> Encode.list


encode : Scribbles -> Encode.Value
encode scribbles =
    Encode.object
        [ ( "visible", encodeAnnotations scribbles.visibleAnnotations )
        , ( "deleted", encodeAnnotations scribbles.deletedAnnotations )
        ]


init : Image -> Scribbles
init bgImage =
    { viewer = Viewer.default
    , bgImage = bgImage
    , checked = Nothing
    , visibleAnnotations = []
    , deletedAnnotations = []
    , nextId = 0
    , currentTool = Tool.None
    }



-- UPDATE ############################################################


type Msg
    = DeleteLast
    | ToolFG
    | ToolBG



-- ENCODE ############################################################
