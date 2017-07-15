module Views.Study.Rectangle exposing (..)

import Types exposing (Model, Msg)
import Types.Study.Rectangle exposing (Rectangle)
import DrawingArea.Viewer as Viewer exposing (Viewer)
import Study
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Views.Study.Helpers as Helpers
import Svg
import Svg.Attributes as SvgAttributes
import Annotation
import OpenSolid.Geometry.Types exposing (Circle2d(..))
import OpenSolid.Svg as Svg


view : ( Int, Int ) -> Model -> String -> Rectangle -> Html Msg
view ( current, total ) model imageUrl rectangle =
    div [ id "app" ]
        [ Helpers.progressBar current total
        , Helpers.instructionsBar imgurImage textInstructions
        , content model rectangle
        , rectangleFooter rectangle
        ]


imgurImage : String
imgurImage =
    "http://i.imgur.com/YBr0Mgl.jpg"


textInstructions : String
textInstructions =
    """In this part of the study you have to draw a rectangle
around the object in the image by clicking and draging.
"""


content : Model -> Rectangle -> Html Msg
content model rectangle =
    let
        viewer =
            Viewer.setSize model.study.contentSize rectangle.viewer
                |> Viewer.fitImage 0.9 rectangle.bgImage

        visualGroundtruth =
            case rectangle.checked of
                Just (Annotation.CrossingGT matrix) ->
                    Svg.image
                        [ id "groundtruth"
                        , SvgAttributes.x "0"
                        , SvgAttributes.y "0"
                        , SvgAttributes.width <| toString (Tuple.first matrix.size)
                        , SvgAttributes.height <| toString (Tuple.second matrix.size)
                        ]
                        [ text "Groundtruth visible" ]

                _ ->
                    text "No groundtruth"

        htmlViewer =
            rectangle.annotations
                |> List.head
                |> Maybe.map (Tuple.second >> Annotation.view)
                |> Maybe.withDefault (Svg.text "No annotation yet")
                |> flip (::) [ visualGroundtruth ]
                |> Svg.g []
                |> Viewer.innerView viewer (Just rectangle.bgImage)
                |> Viewer.view (Study.pointerEvents model.study.pointerTrack viewer) viewer
    in
        div [ id "content", class "content-rectangle" ]
            (case rectangle.checked of
                Just Annotation.Valid ->
                    [ htmlViewer, Helpers.nextButton ]

                _ ->
                    [ htmlViewer ]
            )


rectangleFooter : Rectangle -> Html msg
rectangleFooter rectangle =
    case rectangle.checked of
        Nothing ->
            footer [] [ text "Instruction: draw a bounding box around the object" ]

        Just check ->
            let
                ( attribute, feedbackText ) =
                    toFeedback check
            in
                footer [ attribute ] [ feedbackText ]


toFeedback : Annotation.Check -> ( Html.Attribute msg, Html msg )
toFeedback check =
    case check of
        Annotation.AreaUnderLimit limit ->
            ( class "invalid", text "Too small, please redraw bigger" )

        Annotation.CrossingGT _ ->
            ( class "invalid", text ("Careful: the object is not entirely inside the rectangle") )

        _ ->
            ( class "valid", text "Great, go next or re-draw the bounding box" )
