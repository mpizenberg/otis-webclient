module Views.Study.Scribbles exposing (..)

import Types exposing (Model, Msg)
import Types.Study as Study
import Types.Study.Scribbles as Scribbles exposing (Scribbles)
import DrawingArea.Viewer as Viewer exposing (Viewer)
import Study
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Views.Study.Helpers as Helpers
import Svg exposing (Svg)
import Svg.Attributes as SvgAttributes
import Svg.Lazy exposing (lazy)
import Annotation
import OpenSolid.Geometry.Types exposing (..)
import OpenSolid.BoundingBox2d as BoundingBox2d
import OpenSolid.Svg as Svg


view : ( Int, Int ) -> Model -> String -> Scribbles -> Html Msg
view ( current, total ) model imageUrl scribbles =
    div [ id "app" ]
        [ Helpers.progressBar current total
        , Helpers.instructionsBar imgurImage textInstructions
        , content model scribbles
        , buttonsBar (toFeedback scribbles.checked)
        ]


imgurImage : String
imgurImage =
    "http://i.imgur.com/rvRyeTr.jpg"


textInstructions : String
textInstructions =
    """In this part of the study you have to draw green (foreground) strokes
on the object, and red (background) strokes outside the object.
"""


asMsg : Scribbles.Msg -> Msg
asMsg =
    Study.ScribblesMsg >> Types.StudyMsg


content : Model -> Scribbles -> Html Msg
content model scribbles =
    let
        viewer =
            Viewer.setSize model.study.contentSize scribbles.viewer
                |> Viewer.fitImage 0.9 scribbles.bgImage

        visualFeedback =
            case scribbles.checked of
                Just (Annotation.FGScribbleOutsideGT bb) ->
                    viewBoundingBox bb

                Just (Annotation.BGScribbleInsideGT bb) ->
                    viewBoundingBox bb

                _ ->
                    Svg.text "No feedback"

        htmlViewer =
            scribbles.visibleAnnotations
                |> List.map (lazy (Tuple.second >> Annotation.view))
                |> Svg.g []
                |> flip (::) [ visualFeedback ]
                |> Svg.g []
                |> Viewer.innerView viewer (Just scribbles.bgImage)
                |> Viewer.view (Study.pointerEvents model.study.pointerTrack viewer) viewer
    in
        div [ id "content", class "content-scribbles" ]
            (case scribbles.checked of
                Just Annotation.Valid ->
                    [ htmlViewer, Helpers.nextButton ]

                _ ->
                    [ htmlViewer ]
            )


buttonsBar : String -> Html Msg
buttonsBar feedbackText =
    let
        barButton class_ msg txt =
            button [ class class_, onClick msg ] [ text txt ]
    in
        div [ id "scribbles-bar" ]
            [ barButton "btn-del" (asMsg Scribbles.DeleteLast) "Delete Last"
            , barButton "btn-fg" (asMsg Scribbles.ToolFG) "Foreground"
            , barButton "btn-bg" (asMsg Scribbles.ToolBG) "Background"
            , text feedbackText
            ]


toFeedback : Maybe Annotation.Check -> String
toFeedback check =
    case check of
        Nothing ->
            "  Please start adding foreground"

        Just Annotation.FGLengthToShort ->
            "  Please add more foreground"

        Just Annotation.BGLengthToShort ->
            "  Please add more background"

        Just (Annotation.FGScribbleOutsideGT _) ->
            "  Careful, this is outside the object"

        Just (Annotation.BGScribbleInsideGT _) ->
            "  Careful, this is inside the object"

        _ ->
            "  Ok, go next or add more strokes"


viewBoundingBox : BoundingBox2d -> Svg msg
viewBoundingBox bb =
    let
        extrema =
            BoundingBox2d.extrema bb

        rectangleBB =
            Polygon2d
                [ Point2d ( extrema.minX, extrema.minY )
                , Point2d ( extrema.maxX, extrema.minY )
                , Point2d ( extrema.maxX, extrema.maxY )
                , Point2d ( extrema.minX, extrema.maxY )
                ]
    in
        Svg.polygon2d
            [ SvgAttributes.stroke "blue"
            , SvgAttributes.strokeWidth "3"
            , SvgAttributes.fillOpacity "0"
            ]
            rectangleBB
