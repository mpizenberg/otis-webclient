port module Ports exposing (..)

import Json.Encode as Encode


-- Content size


port askContentSize : () -> Cmd msg


port contentSize : (( Float, Float ) -> msg) -> Sub msg



-- Load images and create local blobs


port fetchTrainImage : ( String, String ) -> Cmd msg


port trainImageFetched : (( String, String, String, ( Int, Int ) ) -> msg) -> Sub msg


port fetchImage : ( String, String ) -> Cmd msg


port imageFetched : (( String, String, String, ( Int, Int ) ) -> msg) -> Sub msg



-- Manage groundtruth display


port displayGroundtruth : ( String, Encode.Value ) -> Cmd msg
