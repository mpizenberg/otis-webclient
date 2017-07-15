module Types.Study exposing (..)

import Types.Study.Resources as Resources exposing (Resources)
import Pivot exposing (Pivot)
import Types.Study.Rectangle as Rectangle exposing (Rectangle)
import Types.Study.Outline as Outline exposing (Outline)
import Types.Study.Scribbles as Scribbles exposing (Scribbles)
import Types.Study.Train as Train exposing (Train(..))
import Pointer exposing (Pointer)
import Json.Encode as Encode
import Helpers.List as List
import Http


-- MODEL #############################################################


type alias Study =
    { contentSize : ( Float, Float )
    , resources : Resources
    , status : Status
    , pointerTrack : Pointer.Track
    }


type Status
    = LoadingResources Int Int
    | Progressing (Pivot Step)
    | Finished (Pivot Step)
    | SavingError (Pivot Step)
    | SavedOnServer Int


type Step
    = RectangleStep ( String, Rectangle )
    | OutlineStep ( String, Outline )
    | ScribblesStep ( String, Scribbles )
    | TrainRectStep ( String, Train Rectangle )
    | TrainOutStep ( String, Train Outline )
    | TrainScribStep ( String, Train Scribbles )



-- HELPERS ###########################################################


asResourcesIn : Study -> Resources -> Study
asResourcesIn study resources =
    { study | resources = resources }


setContentSize : ( Float, Float ) -> Study -> Study
setContentSize size study =
    { study | contentSize = size }


setStatus : Status -> Study -> Study
setStatus status study =
    { study | status = status }


asStatusIn : Study -> Status -> Study
asStatusIn study status =
    { study | status = status }


asRectangleIn : Study -> Rectangle -> Study
asRectangleIn study rectangle =
    updateSteps (updateRectangleStep rectangle) study


asOutlineIn : Study -> Outline -> Study
asOutlineIn study outline =
    updateSteps (updateOutlineStep outline) study


asScribblesIn : Study -> Scribbles -> Study
asScribblesIn study scribbles =
    updateSteps (updateScribblesStep scribbles) study


asTrainingRectangleIn : Study -> Rectangle -> Study
asTrainingRectangleIn study rectangle =
    updateSteps (updateTrainingRectangleStep rectangle) study


asTrainingOutlineIn : Study -> Outline -> Study
asTrainingOutlineIn study outline =
    updateSteps (updateTrainingOutlineStep outline) study


asTrainingScribblesIn : Study -> Scribbles -> Study
asTrainingScribblesIn study scribbles =
    updateSteps (updateTrainingScribblesStep scribbles) study


setPointerTrack : Pointer.Track -> Study -> Study
setPointerTrack pointerTrack study =
    { study | pointerTrack = pointerTrack }



-- UPDATERS ##########################################################


updateSteps : (Pivot Step -> Pivot Step) -> Study -> Study
updateSteps updater study =
    getProgress study.status
        |> Maybe.map (updater >> Progressing >> (asStatusIn study))
        |> Maybe.withDefault study


updateRectangleStep : Rectangle -> Pivot Step -> Pivot Step
updateRectangleStep rectangle steps =
    getRectangleUrl (Pivot.getC steps)
        |> Maybe.map (\url -> RectangleStep ( url, rectangle ))
        |> Maybe.map (\step -> Pivot.setC step steps)
        |> Maybe.withDefault steps


updateOutlineStep : Outline -> Pivot Step -> Pivot Step
updateOutlineStep outline steps =
    getOutlineUrl (Pivot.getC steps)
        |> Maybe.map (\url -> OutlineStep ( url, outline ))
        |> Maybe.map (\step -> Pivot.setC step steps)
        |> Maybe.withDefault steps


updateScribblesStep : Scribbles -> Pivot Step -> Pivot Step
updateScribblesStep scribbles steps =
    getScribblesUrl (Pivot.getC steps)
        |> Maybe.map (\url -> ScribblesStep ( url, scribbles ))
        |> Maybe.map (\step -> Pivot.setC step steps)
        |> Maybe.withDefault steps


updateTrainingRectangleStep : Rectangle -> Pivot Step -> Pivot Step
updateTrainingRectangleStep rectangle steps =
    case Pivot.getC steps of
        TrainRectStep ( url, Train _ ) ->
            TrainRectStep ( url, Train rectangle )
                |> flip Pivot.setC steps

        _ ->
            steps


updateTrainingOutlineStep : Outline -> Pivot Step -> Pivot Step
updateTrainingOutlineStep outline steps =
    case Pivot.getC steps of
        TrainOutStep ( url, Train _ ) ->
            TrainOutStep ( url, Train outline )
                |> flip Pivot.setC steps

        _ ->
            steps


updateTrainingScribblesStep : Scribbles -> Pivot Step -> Pivot Step
updateTrainingScribblesStep scribbles steps =
    case Pivot.getC steps of
        TrainScribStep ( url, Train _ ) ->
            TrainScribStep ( url, Train scribbles )
                |> flip Pivot.setC steps

        _ ->
            steps



-- GETTERS ###########################################################


getProgress : Status -> Maybe (Pivot Step)
getProgress status =
    case status of
        Progressing steps ->
            Just steps

        _ ->
            Nothing


getRectangleUrl : Step -> Maybe String
getRectangleUrl step =
    case step of
        RectangleStep ( imageUrl, _ ) ->
            Just imageUrl

        _ ->
            Nothing


getOutlineUrl : Step -> Maybe String
getOutlineUrl step =
    case step of
        OutlineStep ( imageUrl, _ ) ->
            Just imageUrl

        _ ->
            Nothing


getScribblesUrl : Step -> Maybe String
getScribblesUrl step =
    case step of
        ScribblesStep ( imageUrl, _ ) ->
            Just imageUrl

        _ ->
            Nothing


getScribbles : Step -> Maybe Scribbles
getScribbles step =
    case step of
        ScribblesStep ( _, scribbles ) ->
            Just scribbles

        _ ->
            Nothing



-- OTHER #############################################################


progress : Pivot Step -> ( Int, Int )
progress steps =
    ( Pivot.lengthL steps, Pivot.lengthA steps )



-- MSG ###############################################################


type Msg
    = NewContentSize ( Float, Float )
    | ResourcesMsg Resources.Msg
    | PointerEventAnnotation Pointer
    | ScribblesMsg Scribbles.Msg
    | NextStep
    | SendToServer
    | SentToServer (Result Http.Error Int)



-- ENCODE ############################################################


encode : Serialized -> Encode.Value
encode serialized =
    Encode.object
        [ ( "toolOrder", Encode.list <| List.map Encode.string serialized.toolOrder )
        , ( "trainRectangle", trainEncode Rectangle.encode serialized.trainRectangle )
        , ( "trainOutline", trainEncode Outline.encode serialized.trainOutline )
        , ( "trainScribbles", trainEncode Scribbles.encode serialized.trainScribbles )
        , ( "rectangle", Encode.list <| List.map (annEncode Rectangle.encode) serialized.rectangle )
        , ( "outline", Encode.list <| List.map (annEncode Outline.encode) serialized.outline )
        , ( "scribbles", Encode.list <| List.map (annEncode Scribbles.encode) serialized.scribbles )
        ]


trainEncode : (a -> Encode.Value) -> Maybe ( String, Train a ) -> Encode.Value
trainEncode encoder train =
    case train of
        Nothing ->
            Encode.null

        Just ( imageUrl, Train a ) ->
            annEncode encoder ( imageUrl, a )


annEncode : (a -> Encode.Value) -> ( String, a ) -> Encode.Value
annEncode encoder ( imageUrl, a ) =
    Encode.object
        [ ( "image", Encode.string imageUrl )
        , ( "annotations", encoder a )
        ]


type alias Serialized =
    { toolOrder : List String
    , trainRectangle : Maybe ( String, Train Rectangle )
    , trainOutline : Maybe ( String, Train Outline )
    , trainScribbles : Maybe ( String, Train Scribbles )
    , rectangle : List ( String, Rectangle )
    , outline : List ( String, Outline )
    , scribbles : List ( String, Scribbles )
    }


tripletToList : ( a, a, a ) -> List a
tripletToList ( a, b, c ) =
    [ a, b, c ]


serialize : Resources.Data -> Pivot Step -> Serialized
serialize data steps =
    let
        stepsList =
            Pivot.getA steps

        ( trainRectangle, trainOutline, trainScribbles ) =
            ( List.find (getTrainRectStep >> (/=) Nothing) stepsList
                |> Maybe.andThen getTrainRectStep
            , List.find (getTrainOutStep >> (/=) Nothing) stepsList
                |> Maybe.andThen getTrainOutStep
            , List.find (getTrainScribStep >> (/=) Nothing) stepsList
                |> Maybe.andThen getTrainScribStep
            )

        ( rectangle, outline, scribbles ) =
            ( List.filterMap getRectangleStep stepsList
            , List.filterMap getOutlineStep stepsList
            , List.filterMap getScribblesStep stepsList
            )
    in
        { toolOrder = List.map Resources.toolString (tripletToList data.toolOrder)
        , trainRectangle = trainRectangle
        , trainOutline = trainOutline
        , trainScribbles = trainScribbles
        , rectangle = rectangle
        , outline = outline
        , scribbles = scribbles
        }


getRectangleStep : Step -> Maybe ( String, Rectangle )
getRectangleStep step =
    case step of
        RectangleStep a ->
            Just a

        _ ->
            Nothing


getOutlineStep : Step -> Maybe ( String, Outline )
getOutlineStep step =
    case step of
        OutlineStep a ->
            Just a

        _ ->
            Nothing


getScribblesStep : Step -> Maybe ( String, Scribbles )
getScribblesStep step =
    case step of
        ScribblesStep a ->
            Just a

        _ ->
            Nothing


getTrainRectStep : Step -> Maybe ( String, Train Rectangle )
getTrainRectStep step =
    case step of
        TrainRectStep a ->
            Just a

        _ ->
            Nothing


getTrainOutStep : Step -> Maybe ( String, Train Outline )
getTrainOutStep step =
    case step of
        TrainOutStep a ->
            Just a

        _ ->
            Nothing


getTrainScribStep : Step -> Maybe ( String, Train Scribbles )
getTrainScribStep step =
    case step of
        TrainScribStep a ->
            Just a

        _ ->
            Nothing



-- RectangleStep ( String, Rectangle )
-- OutlineStep ( String, Outline )
-- ScribblesStep ( String, Scribbles )
-- TrainRectStep ( String, Train Rectangle )
-- TrainOutStep ( String, Train Outline )
-- TrainScribStep ( String, Train Scribbles )
