module Views.Study.TrainScribbles exposing (..)

import Types exposing (Model, Msg)
import Types.Study.Scribbles exposing (Scribbles)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Views.Study.Scribbles as Scribbles
import Views.Header as Header
import Views.Study.Helpers as Helpers


view : ( Int, Int ) -> Model -> String -> Scribbles -> Html Msg
view ( current, total ) model imageUrl scribbles =
    div [ id "app" ]
        [ Header.view model
        , Helpers.progressBar current total
        , Helpers.instructionsBar Scribbles.imgurImage textInstructions
        , Scribbles.content model scribbles
        , Scribbles.buttonsBar (Scribbles.toFeedback scribbles.checked)
        ]


textInstructions : String
textInstructions =
    """In this part of the study you have to draw green (foreground) strokes
on the object, and red (background) strokes outside the object.
Try multiple times to get used to the interaction and purposely make wrong interactions.
Go next and start when ready.
"""
