module Study exposing (..)

import Types exposing (..)
import Types.Route as Route
import Types.Log as Log exposing (Log)
import Types.Study as Study exposing (Study)
import Types.Study.Rectangle as Rectangle exposing (Rectangle)
import Types.Study.Outline as Outline exposing (Outline)
import Types.Study.Scribbles as Scribbles exposing (Scribbles)
import Types.Study.Train as Train exposing (Train(..))
import Types.Study.Resources as Resources
import Types.Study.API as API
import Study.Resources as Resources
import Study.Rectangle as Rectangle
import Study.Outline as Outline
import Study.Scribbles as Scribbles
import Study.Train as Train
import Pivot exposing (Pivot)
import Dict
import Image exposing (Image)
import DrawingArea.Viewer as Viewer exposing (Viewer)
import Pointer exposing (Pointer)
import Html
import Ports
import Time exposing (Time)
import Task
import Return
import Json.Encode as Encode
import Json.Decode as Decode
import Http


init : Study
init =
    { contentSize = ( 100, 100 )
    , resources = Resources.NotFetched
    , status = Study.LoadingResources 0 100
    , pointerTrack = Pointer.None
    }


update : Study.Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Study.NewContentSize size ->
            ( Study.setContentSize size model.study
                |> asStudyIn model
            , Cmd.none
            )

        Study.ResourcesMsg resourcesMsg ->
            case Resources.update resourcesMsg model of
                ( newModel, cmd, Resources.NoNotif ) ->
                    ( newModel, cmd )

                ( newModel, cmd, Resources.LoadingProgress ( n, total ) ) ->
                    ( Study.LoadingResources n total
                        |> Study.asStatusIn newModel.study
                        |> asStudyIn newModel
                    , cmd
                    )

                ( newModel, cmd, Resources.AllFetched data ) ->
                    ( Resources.Fetched data
                        |> Study.asResourcesIn newModel.study
                        |> Study.setStatus (Study.Progressing <| createSteps data)
                        |> asStudyIn newModel
                    , if model.currentRoute == Route.Study then
                        Cmd.batch [ cmd, Ports.askContentSize () ]
                      else
                        cmd
                    )

        Study.PointerEventAnnotation pointer ->
            case model.study.status of
                Study.Progressing steps ->
                    case Pivot.getC steps of
                        Study.TrainRectStep ( imageUrl, Train rectangle ) ->
                            Train.updateRectangle model pointer rectangle
                                |> Return.command (logPointer pointer Log.TrainRectMsg)

                        Study.TrainOutStep ( imageUrl, Train outline ) ->
                            Train.updateOutline model pointer outline
                                |> Return.command (logPointer pointer Log.TrainOutMsg)

                        Study.TrainScribStep ( imageUrl, Train scribbles ) ->
                            ( Train.updateScribblesWith pointer model scribbles
                            , logPointer pointer Log.TrainScribMouseMsg
                            )

                        Study.RectangleStep ( imageUrl, rectangle ) ->
                            Rectangle.update model pointer rectangle
                                |> Return.command (logPointer pointer <| Log.RectMsg imageUrl)

                        Study.OutlineStep ( imageUrl, outline ) ->
                            Outline.update model pointer outline
                                |> Return.command (logPointer pointer <| Log.OutMsg imageUrl)

                        Study.ScribblesStep ( imageUrl, scribbles ) ->
                            ( Scribbles.updateWith pointer model scribbles
                            , logPointer pointer <| Log.ScribMouseMsg imageUrl
                            )

                _ ->
                    ( model, Cmd.none )

        Study.ScribblesMsg scribblesMsg ->
            case Study.getProgress model.study.status |> Maybe.map Pivot.getC of
                Just (Study.ScribblesStep ( imageUrl, scribbles )) ->
                    ( Scribbles.update scribblesMsg model scribbles
                    , logScribMsg scribblesMsg <| Log.ScribMsg imageUrl
                    )

                Just (Study.TrainScribStep ( imageUrl, Train scribbles )) ->
                    ( Train.updateScribbles scribblesMsg model scribbles
                    , logScribMsg scribblesMsg Log.TrainScribMsg
                    )

                _ ->
                    ( model, Cmd.none )

        Study.NextStep ->
            case ( model.study.status, model.study.resources ) of
                ( Study.Progressing steps, Resources.Fetched data ) ->
                    case Pivot.goR steps of
                        Nothing ->
                            ( Study.setStatus (Study.Finished steps) model.study
                                |> asStudyIn model
                            , Task.perform (LogMsg << Log.NextMsg) Time.now
                            )

                        Just newSteps ->
                            ( Study.setStatus (Study.Progressing newSteps) model.study
                                |> asStudyIn model
                            , Cmd.batch
                                [ Ports.askContentSize ()
                                , Task.perform (LogMsg << Log.NextMsg) Time.now
                                ]
                            )

                _ ->
                    ( model, Cmd.none )

        Study.SendToServer ->
            ( model, sendToServer model )

        Study.SentToServer (Ok id) ->
            ( Study.setStatus (Study.SavedOnServer id) model.study
                |> asStudyIn model
            , Cmd.none
            )

        Study.SentToServer (Err _) ->
            ( case model.study.status of
                Study.Finished steps ->
                    Study.setStatus (Study.SavingError steps) model.study
                        |> asStudyIn model

                _ ->
                    model
            , Cmd.none
            )


sendToServer : Model -> Cmd Msg
sendToServer model =
    case ( model.study.status, model.study.resources ) of
        ( Study.Finished steps, Resources.Fetched data ) ->
            sendDataAndLog data steps model.log

        ( Study.SavingError steps, Resources.Fetched data ) ->
            sendDataAndLog data steps model.log

        _ ->
            Cmd.none


sendDataAndLog : Resources.Data -> Pivot Study.Step -> Log -> Cmd Msg
sendDataAndLog data steps log =
    Encode.object
        [ ( "data", Study.serialize data steps |> Study.encode )
        , ( "log", Log.encode log )
        ]
        |> API.post "/api/save" (Http.expectJson <| Decode.field "userID" Decode.int)
        |> API.http
        |> Http.send (StudyMsg << Study.SentToServer)


createSteps : Resources.Data -> Pivot Study.Step
createSteps data =
    let
        ( rectangles, outlines, scribbles ) =
            ( Dict.values data.rectangle
            , Dict.values data.outline
            , Dict.values data.scribbles
            )

        rectangleToStep ( imageUrl, image ) =
            Study.RectangleStep ( imageUrl, Rectangle.init image )

        outlineToStep ( imageUrl, image ) =
            Study.OutlineStep ( imageUrl, Outline.init image )

        scribblesToStep ( imageUrl, image ) =
            Study.ScribblesStep ( imageUrl, Scribbles.init image )

        trainRectToStep ( maybeUrl, maybeImage ) =
            let
                ( url, image ) =
                    ( Maybe.withDefault "" maybeUrl
                    , Maybe.withDefault (Image "" 0 0) maybeImage
                    )
            in
                Train (Rectangle.init image)
                    |> (\train -> Study.TrainRectStep ( url, train ))

        trainOutToStep ( maybeUrl, maybeImage ) =
            let
                ( url, image ) =
                    ( Maybe.withDefault "" maybeUrl
                    , Maybe.withDefault (Image "" 0 0) maybeImage
                    )
            in
                Train (Outline.init image)
                    |> (\train -> Study.TrainOutStep ( url, train ))

        trainScribToStep ( maybeUrl, maybeImage ) =
            let
                ( url, image ) =
                    ( Maybe.withDefault "" maybeUrl
                    , Maybe.withDefault (Image "" 0 0) maybeImage
                    )
            in
                Train (Scribbles.init image)
                    |> (\train -> Study.TrainScribStep ( url, train ))

        -- WARNING : TO CHANGE ASAP
        defaultPivot =
            outlineToStep ( "", (Image "" 0 0) )
                |> Pivot.singleton

        toolSteps toolType =
            case toolType of
                Resources.Rectangle ->
                    [ [ trainRectToStep data.training.rectangle ]
                    , List.map rectangleToStep rectangles
                    ]

                Resources.Outline ->
                    [ [ trainOutToStep data.training.outline ]
                    , List.map outlineToStep outlines
                    ]

                Resources.Scribbles ->
                    [ [ trainScribToStep data.training.scribbles ]
                    , List.map scribblesToStep scribbles
                    ]
    in
        case data.toolOrder of
            ( tool1, tool2, tool3 ) ->
                [ toolSteps tool1, toolSteps tool2, toolSteps tool3 ]
                    |> List.concat
                    |> List.concat
                    |> Pivot.fromList
                    |> Maybe.withDefault defaultPivot


pointerEvents : Pointer.Track -> Viewer -> List (Html.Attribute Msg)
pointerEvents pointerTrack viewer =
    let
        annotationOffsetOn eventName event =
            Pointer.offsetOn eventName event (StudyMsg << Study.PointerEventAnnotation) (Viewer.positionIn viewer)

        annotationTouchOffsetOn eventName event =
            Pointer.touchOffsetOn eventName event (StudyMsg << Study.PointerEventAnnotation) (Viewer.positionIn viewer)
    in
        [ annotationOffsetOn "mousedown" Pointer.Down
        , annotationTouchOffsetOn "touchstart" Pointer.Down
        , annotationTouchOffsetOn "touchmove" Pointer.Move
        , annotationOffsetOn "mouseup" Pointer.Up
        , annotationTouchOffsetOn "touchend" Pointer.Up
        ]
            ++ if pointerTrack == Pointer.None then
                []
               else
                [ annotationOffsetOn "mousemove" Pointer.Move ]



-- LOGGING ###########################################################


logPointer : Pointer -> (Log.Timed Log.Mouse -> Log.Msg) -> Cmd Msg
logPointer pointer tag =
    let
        log : Log.Mouse -> Time -> Msg
        log mouse time =
            tag (Log.Timed time mouse)
                |> Types.LogMsg
    in
        case pointer.event of
            Pointer.Down ->
                Task.perform (log Log.Down) Time.now

            Pointer.Up ->
                Task.perform (log Log.Up) Time.now

            _ ->
                Cmd.none


logScribMsg : Scribbles.Msg -> (Log.Timed Log.ScribbleMsg -> Log.Msg) -> Cmd Msg
logScribMsg scribblesMsg tag =
    let
        log : Log.ScribbleMsg -> Time -> Msg
        log scribMsg time =
            tag (Log.Timed time scribMsg)
                |> Types.LogMsg
    in
        case scribblesMsg of
            Scribbles.DeleteLast ->
                Task.perform (log Log.Delete) Time.now

            Scribbles.ToolFG ->
                Task.perform (log Log.ToolFG) Time.now

            Scribbles.ToolBG ->
                Task.perform (log Log.ToolBG) Time.now
