module Study.API exposing (..)

import Types.Study.Resources exposing (ToolType(..), toolString)
import Types.Study.API as API
import Http
import Ports


-- HTTP ##############################################################


getResources : Http.Request API.Resources
getResources =
    Http.get "/api/resources" API.decodeResources



-- PORT ##############################################################


getTrainImage : ToolType -> String -> Cmd msg
getTrainImage tool imageUrl =
    Ports.fetchTrainImage ( toolString tool, imageUrl )


getImage : ToolType -> String -> Cmd msg
getImage tool imageUrl =
    Ports.fetchImage ( toolString tool, imageUrl )


getAllImages : API.Resources -> Cmd msg
getAllImages { rectangle, outline, scribbles } =
    [ [ getTrainImage Rectangle rectangle.trainingImage ]
    , [ getTrainImage Outline outline.trainingImage ]
    , [ getTrainImage Scribbles scribbles.trainingImage ]
    , List.map (getImage Rectangle) rectangle.images
    , List.map (getImage Outline) outline.images
    , List.map (getImage Scribbles) scribbles.images
    ]
        |> List.concat
        |> Cmd.batch
