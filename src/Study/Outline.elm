module Study.Outline exposing (..)

import Types exposing (..)
import Types.Study as Study
import Types.Study.Outline as Outline exposing (Outline)
import Pointer exposing (Pointer)
import Annotation
import Tool


update : Model -> Pointer -> Outline -> ( Model, Cmd Msg )
update model pointer outline =
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
                    Just (Annotation.isValid ann)

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
                |> Study.asOutlineIn model.study
                |> Study.setPointerTrack newPointerTrack
                |> asStudyIn model
    in
        ( newModel, Cmd.none )
