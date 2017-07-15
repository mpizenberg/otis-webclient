module Views.Study.Outline exposing (..)

import Types exposing (Model, Msg)
import Types.Study.Outline exposing (Outline)
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


view : ( Int, Int ) -> Model -> String -> Outline -> Html Msg
view ( current, total ) model imageUrl outline =
    div [ id "app" ]
        [ Helpers.progressBar current total
        , Helpers.instructionsBar imgurImage textInstructions
        , content model outline
        , outlineFooter outline
        ]


imgurImage : String
imgurImage =
    "http://i.imgur.com/EP5AoHB.jpg"


textInstructions : String
textInstructions =
    """In this part of the study you have to outline
the object in the image by clicking and draging.
"""


content : Model -> Outline -> Html Msg
content model outline =
    let
        viewer =
            Viewer.setSize model.study.contentSize outline.viewer
                |> Viewer.fitImage 0.9 outline.bgImage

        visualGroundtruth =
            case outline.checked of
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

        visualFeedback =
            case outline.checked of
                Just (Annotation.SegmentsCrossing point) ->
                    Circle2d { centerPoint = point, radius = 10 }
                        |> Svg.circle2d
                            [ SvgAttributes.stroke "blue"
                            , SvgAttributes.strokeWidth "3"
                            , SvgAttributes.fillOpacity "0"
                            ]

                _ ->
                    Svg.text "No feedback"

        htmlViewer =
            outline.annotations
                |> List.head
                |> Maybe.map (Tuple.second >> Annotation.view)
                |> Maybe.withDefault (Svg.text "No annotation yet")
                |> flip (::) [ visualGroundtruth, visualFeedback ]
                |> Svg.g []
                |> Viewer.innerView viewer (Just outline.bgImage)
                |> Viewer.view (Study.pointerEvents model.study.pointerTrack viewer) viewer
    in
        div [ id "content", class "content-outline" ]
            (case outline.checked of
                Just Annotation.Valid ->
                    [ htmlViewer, Helpers.nextButton ]

                _ ->
                    [ htmlViewer ]
            )


toFeedback : Annotation.Check -> ( Html.Attribute msg, Html msg )
toFeedback check =
    case check of
        Annotation.Valid ->
            ( class "valid", text "Great, go next or re-outline" )

        Annotation.SegmentsCrossing point ->
            ( class "invalid", text "Oups, please avoid self intersections" )

        Annotation.AreaUnderLimit limit ->
            ( class "invalid", text "Too small, please re-outline bigger" )

        Annotation.CrossingGT _ ->
            ( class "invalid", text ("Careful: the object is not entirely inside the outline") )

        _ ->
            ( class "invalid", text "Oups, something went wrong, please retry" )


outlineFooter : Outline -> Html msg
outlineFooter outline =
    case outline.checked of
        Nothing ->
            footer [] [ text "Instruction: outline the object" ]

        Just check ->
            let
                ( attribute, feedbackText ) =
                    toFeedback check
            in
                footer [ attribute ] [ feedbackText ]
