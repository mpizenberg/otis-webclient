module Study.Train exposing (..)

import Types exposing (..)
import Types.Study as Study
import Types.Study.Rectangle as Rectangle exposing (Rectangle)
import Types.Study.Outline as Outline exposing (Outline)
import Types.Study.Scribbles as Scribbles exposing (Scribbles)
import Annotation
import Pointer exposing (Pointer)
import Annotation exposing (Annotation)
import Tool exposing (Tool)
import Ports


updateRectangle : Model -> Pointer -> Rectangle -> ( Model, Cmd Msg )
updateRectangle model pointer rectangle =
    let
        track =
            model.study.pointerTrack

        visibleHead =
            case pointer.event of
                Pointer.Down ->
                    Annotation.update pointer track Tool.Rectangle rectangle.nextId Nothing

                _ ->
                    List.head rectangle.annotations
                        |> Annotation.update pointer track Tool.Rectangle rectangle.nextId

        annotations =
            case ( pointer.event, visibleHead, rectangle.annotations ) of
                ( Pointer.Down, Just head, _ ) ->
                    head :: rectangle.annotations

                ( _, Just head, _ :: ann ) ->
                    head :: ann

                _ ->
                    rectangle.annotations

        checked =
            case ( pointer.event, List.head annotations ) of
                ( Pointer.Up, Just ( _, ann ) ) ->
                    Just (Annotation.isValidStrict ann)

                ( Pointer.Down, _ ) ->
                    Nothing

                _ ->
                    rectangle.checked

        newPointerTrack =
            Pointer.updateTrack pointer model.study.pointerTrack

        nextId =
            if pointer.event == Pointer.Down then
                rectangle.nextId + 1
            else
                rectangle.nextId

        newModel =
            { rectangle
                | annotations = annotations
                , checked = checked
                , nextId = nextId
            }
                |> Study.asTrainingRectangleIn model.study
                |> Study.setPointerTrack newPointerTrack
                |> asStudyIn model
    in
        ( newModel, Cmd.none )


updateOutline : Model -> Pointer -> Outline -> ( Model, Cmd Msg )
updateOutline model pointer outline =
    let
        track =
            model.study.pointerTrack

        visibleHead =
            case pointer.event of
                Pointer.Down ->
                    Annotation.update pointer track Tool.Outline outline.nextId Nothing

                _ ->
                    List.head outline.annotations
                        |> Annotation.update pointer track Tool.Outline outline.nextId

        annotations =
            case ( pointer.event, visibleHead, outline.annotations ) of
                ( Pointer.Down, Just head, _ ) ->
                    head :: outline.annotations

                ( _, Just head, _ :: ann ) ->
                    head :: ann

                _ ->
                    outline.annotations

        checked =
            case ( pointer.event, List.head annotations ) of
                ( Pointer.Up, Just ( _, ann ) ) ->
                    Just (Annotation.isValidStrict ann)

                ( Pointer.Down, _ ) ->
                    Nothing

                _ ->
                    outline.checked

        newPointerTrack =
            Pointer.updateTrack pointer model.study.pointerTrack

        nextId =
            if pointer.event == Pointer.Down then
                outline.nextId + 1
            else
                outline.nextId

        newModel =
            { outline
                | annotations = annotations
                , checked = checked
                , nextId = nextId
            }
                |> Study.asTrainingOutlineIn model.study
                |> Study.setPointerTrack newPointerTrack
                |> asStudyIn model
    in
        ( newModel, Cmd.none )


updateScribbles : Scribbles.Msg -> Model -> Scribbles -> Model
updateScribbles msg model scribbles =
    case msg of
        Scribbles.DeleteLast ->
            case scribbles.visibleAnnotations of
                [] ->
                    model

                del :: rest ->
                    { scribbles
                        | visibleAnnotations = rest
                        , deletedAnnotations = del :: scribbles.deletedAnnotations
                        , checked = Just <| check (List.map Tuple.second rest)
                    }
                        |> inModel model

        Scribbles.ToolFG ->
            { scribbles | currentTool = Tool.ScribbleFG }
                |> inModel model

        Scribbles.ToolBG ->
            { scribbles | currentTool = Tool.ScribbleBG }
                |> inModel model


updateScribblesWith : Pointer -> Model -> Scribbles -> Model
updateScribblesWith pointer model scribbles =
    let
        track =
            model.study.pointerTrack

        updatedHead =
            case pointer.event of
                Pointer.Down ->
                    Annotation.update pointer track scribbles.currentTool scribbles.nextId Nothing

                _ ->
                    List.head scribbles.visibleAnnotations
                        |> Annotation.update pointer track scribbles.currentTool scribbles.nextId

        visibleAnnotations =
            case ( pointer.event, updatedHead ) of
                ( Pointer.Down, Just head ) ->
                    head :: scribbles.visibleAnnotations

                ( _, Just head ) ->
                    head :: Maybe.withDefault [] (List.tail scribbles.visibleAnnotations)

                _ ->
                    scribbles.visibleAnnotations

        nextId =
            if pointer.event == Pointer.Down then
                scribbles.nextId + 1
            else
                scribbles.nextId

        newPointerTrack =
            Pointer.updateTrack pointer model.study.pointerTrack

        checked =
            case pointer.event of
                Pointer.Up ->
                    Just <| check (List.map Tuple.second visibleAnnotations)

                _ ->
                    scribbles.checked
    in
        { scribbles
            | visibleAnnotations = visibleAnnotations
            , nextId = nextId
            , checked = checked
        }
            |> Study.asTrainingScribblesIn model.study
            |> Study.setPointerTrack newPointerTrack
            |> asStudyIn model



-- HELPERS ###########################################################


check : List Annotation -> Annotation.Check
check scribbles =
    Annotation.areValidScribbles 150 250 scribbles


inModel : Model -> Scribbles -> Model
inModel model =
    (Study.asTrainingScribblesIn model.study) >> (asStudyIn model)


maybeCons : Maybe a -> List a -> List a
maybeCons maybe list =
    case maybe of
        Nothing ->
            list

        Just a ->
            a :: list
