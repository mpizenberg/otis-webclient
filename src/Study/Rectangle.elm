module Study.Rectangle exposing (..)

import Types exposing (..)
import Types.Study as Study
import Types.Study.Rectangle as Rectangle exposing (Rectangle)
import Pointer exposing (Pointer)
import Annotation
import Tool


update : Model -> Pointer -> Rectangle -> ( Model, Cmd Msg )
update model pointer rectangle =
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
                    Just (Annotation.isValid ann)

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
                |> Study.asRectangleIn model.study
                |> Study.setPointerTrack newPointerTrack
                |> asStudyIn model
    in
        ( newModel, Cmd.none )
