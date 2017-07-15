module Views.Study.TrainRectangle exposing (..)

import Types exposing (Model, Msg)
import Types.Study.Rectangle exposing (Rectangle)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Views.Study.Rectangle as Rectangle
import Views.Study.Helpers as Helpers


view : ( Int, Int ) -> Model -> String -> Rectangle -> Html Msg
view ( current, total ) model imageUrl rectangle =
    div [ id "app" ]
        [ Helpers.progressBar current total
        , Helpers.instructionsBar Rectangle.imgurImage textInstructions
        , Rectangle.content model rectangle
        , Rectangle.rectangleFooter rectangle
        ]


textInstructions : String
textInstructions =
    """In this part of the study you have to draw a rectangle
around the object in the image by clicking and draging.
Try multiple times to get used to the interaction and purposely make wrong interactions.
Go next and start when ready.
"""
