module Log exposing (..)

import Types exposing (..)
import Types.Log as Log
import Dict exposing (Dict)


update : Log.Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Log.NavMsg timedRoute ->
            ( (timedRoute :: model.log.navigation)
                |> Log.asNavigationIn model.log
                |> asLogIn model
            , Cmd.none
            )

        Log.TrainRectMsg timedMouse ->
            (timedMouse :: model.log.study.trainRectangle)
                |> Log.asTrainRectangleIn model.log.study
                |> returnStudyIn model

        Log.TrainOutMsg timedMouse ->
            (timedMouse :: model.log.study.trainOutline)
                |> Log.asTrainOutlineIn model.log.study
                |> returnStudyIn model

        Log.TrainScribMouseMsg timedMouse ->
            (timedMouse :: model.log.study.trainScribbles.mouse)
                |> Log.asMouseIn model.log.study.trainScribbles
                |> Log.asTrainScribblesIn model.log.study
                |> returnStudyIn model

        Log.TrainScribMsg timedMsg ->
            (timedMsg :: model.log.study.trainScribbles.msg)
                |> Log.asMsgIn model.log.study.trainScribbles
                |> Log.asTrainScribblesIn model.log.study
                |> returnStudyIn model

        Log.RectMsg imageId timedMouse ->
            model.log.study.rectangle
                |> Dict.update imageId (justCons timedMouse)
                |> Log.asRectangleIn model.log.study
                |> returnStudyIn model

        Log.OutMsg imageId timedMouse ->
            model.log.study.outline
                |> Dict.update imageId (justCons timedMouse)
                |> Log.asOutlineIn model.log.study
                |> returnStudyIn model

        Log.ScribMouseMsg imageId timedMouse ->
            model.log.study.scribbles
                |> Dict.update imageId (justConsMouse timedMouse)
                |> Log.asScribblesIn model.log.study
                |> returnStudyIn model

        Log.ScribMsg imageId timedMsg ->
            model.log.study.scribbles
                |> Dict.update imageId (justConsMsg timedMsg)
                |> Log.asScribblesIn model.log.study
                |> returnStudyIn model

        Log.NextMsg time ->
            model.log.study.next
                |> (::) time
                |> Log.asNextIn model.log.study
                |> returnStudyIn model


justConsMouse : Log.Timed Log.Mouse -> Maybe Log.ScribblesLog -> Maybe Log.ScribblesLog
justConsMouse timedMouse scribblesLog =
    scribblesLog
        |> Maybe.map (\s -> Just { s | mouse = timedMouse :: s.mouse })
        |> Maybe.withDefault (Just { mouse = [ timedMouse ], msg = [] })


justConsMsg : Log.Timed Log.ScribbleMsg -> Maybe Log.ScribblesLog -> Maybe Log.ScribblesLog
justConsMsg timedMsg scribblesLog =
    scribblesLog
        |> Maybe.map (\s -> Just { s | msg = timedMsg :: s.msg })
        |> Maybe.withDefault (Just { mouse = [], msg = [ timedMsg ] })


justCons : a -> Maybe (List a) -> Maybe (List a)
justCons a list =
    Maybe.map ((::) a >> Just) list
        |> Maybe.withDefault (Just [ a ])


returnStudyIn : Model -> Log.StudyLog -> ( Model, Cmd Msg )
returnStudyIn model study =
    ( Log.asStudyIn model.log study
        |> asLogIn model
    , Cmd.none
    )
