module Views.Study.Helpers exposing (..)

import Types exposing (..)
import Types.Study as Study
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode


progressBar : Int -> Int -> Html msg
progressBar n total =
    progress [ class "study-progress", value (toString n), Attributes.max (toString total) ] []


instructionsBar : String -> String -> Html msg
instructionsBar imageInstructionUrl theText =
    div [ class "instructions" ]
        [ div []
            [ b [] [ text "Instructions: " ]
            , text theText
            ]
        , img [ class "img-instructions", src imageInstructionUrl ] []
        ]


nextButton : Html Msg
nextButton =
    button
        [ class "next"
        , onWithOptions "click" stop <| Decode.succeed (StudyMsg Study.NextStep)
        ]
        [ text ">" ]


stop : Options
stop =
    { stopPropagation = True
    , preventDefault = True
    }
