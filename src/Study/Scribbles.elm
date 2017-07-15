module Study.Scribbles exposing (..)

import Types exposing (..)
import Types.Study as Study
import Types.Study.Scribbles as Scribbles exposing (Scribbles)
import Pointer exposing (Pointer)
import Tool exposing (Tool)
import Annotation exposing (Annotation)


update : Scribbles.Msg -> Model -> Scribbles -> Model
update msg model scribbles =
    case msg of
        Scribbles.DeleteLast ->
            case scribbles.visibleAnnotations of
                [] ->
                    model

                del :: rest ->
                    { scribbles
                        | visibleAnnotations = rest
                        , deletedAnnotations = del :: scribbles.deletedAnnotations
                    }
                        |> inModel model

        Scribbles.ToolFG ->
            { scribbles | currentTool = Tool.ScribbleFG }
                |> inModel model

        Scribbles.ToolBG ->
            { scribbles | currentTool = Tool.ScribbleBG }
                |> inModel model


updateWith : Pointer -> Model -> Scribbles -> Model
updateWith pointer model scribbles =
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
            |> Study.asScribblesIn model.study
            |> Study.setPointerTrack newPointerTrack
            |> asStudyIn model



-- HELPERS ###########################################################


check : List Annotation -> Annotation.Check
check scribbles =
    Annotation.areValidScribbles 150 250 scribbles


inModel : Model -> Scribbles -> Model
inModel model =
    (Study.asScribblesIn model.study) >> (asStudyIn model)


maybeCons : Maybe a -> List a -> List a
maybeCons maybe list =
    case maybe of
        Nothing ->
            list

        Just a ->
            a :: list
