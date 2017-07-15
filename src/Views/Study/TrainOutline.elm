module Views.Study.TrainOutline exposing (..)

import Types exposing (Model, Msg)
import Types.Study.Outline exposing (Outline)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Views.Study.Outline as Outline
import Views.Study.Helpers as Helpers


view : ( Int, Int ) -> Model -> String -> Outline -> Html Msg
view ( current, total ) model imageUrl outline =
    div [ id "app" ]
        [ Helpers.progressBar current total
        , Helpers.instructionsBar Outline.imgurImage textInstructions
        , Outline.content model outline
        , Outline.outlineFooter outline
        ]


textInstructions : String
textInstructions =
    """In this part of the study you have to outline
the object in the image by clicking and draging.
Try multiple times to get used to the interaction and purposely make wrong interactions.
Go next and start when ready.
"""
