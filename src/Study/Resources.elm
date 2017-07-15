module Study.Resources exposing (..)

import Types exposing (Model, Msg(..))
import Types.Study as Study
import Types.Study.Resources as Resources exposing (Resources, Mapping, Data, ToolType(..), TrainingData, RandomConfig)
import Types.Study.API as API
import Study.API as API
import Study.Random as Random
import Random
import Http
import Dict
import Image exposing (Image)
import Helpers


-- MODEL #############################################################


emptyTraining : TrainingData
emptyTraining =
    { rectangle = ( Nothing, Nothing )
    , outline = ( Nothing, Nothing )
    , scribbles = ( Nothing, Nothing )
    }


emptyData : ( ToolType, ToolType, ToolType ) -> Data
emptyData toolOrder =
    Data toolOrder emptyTraining Dict.empty Dict.empty Dict.empty



-- HELPERS ###########################################################


setIn : Model -> Resources -> Model
setIn model resources =
    resources
        |> Study.asResourcesIn model.study
        |> Types.asStudyIn model


tagger : Resources.Msg -> Msg
tagger =
    StudyMsg << Study.ResourcesMsg



-- UPDATE ############################################################


update : Resources.Msg -> Model -> ( Model, Cmd Msg, Resources.Notif )
update msg model =
    case ( msg, model.study.resources ) of
        ( Resources.URLs (Ok apiResources), Resources.NotFetched ) ->
            ( Resources.Randomizing apiResources |> setIn model
            , randomize apiResources
            , Resources.NoNotif
            )

        ( Resources.URLs (Err httpError), Resources.NotFetched ) ->
            ( model, Cmd.none, Resources.NoNotif )
                |> Helpers.logAndReturn "Http error" httpError

        ( Resources.NewRandomConfig randomConfig, Resources.Randomizing apiResources ) ->
            ( createMapping apiResources randomConfig
                |> Resources.Fetching (emptyData randomConfig.toolOrder)
                |> setIn model
            , Cmd.batch
                [ API.getAllImages apiResources
                ]
            , Resources.NoNotif
            )

        ( Resources.ImageLoaded ( tool, name, url, ( width, height ) ), Resources.Fetching data mapping ) ->
            let
                image =
                    Image url width height

                toolType =
                    Resources.toolType tool

                newData =
                    insertImageData toolType name image mapping data
            in
                ( Resources.Fetching newData mapping |> setIn model
                , Cmd.none
                , if allFetched newData mapping then
                    Resources.AllFetched newData
                  else
                    Resources.LoadingProgress (loadingProgress newData mapping)
                )

        ( Resources.TrainImageLoaded ( tool, name, url, ( width, height ) ), Resources.Fetching data mapping ) ->
            let
                image =
                    Image url width height

                toolType =
                    Resources.toolType tool

                newData =
                    insertTrainingImage toolType name image data
            in
                ( Resources.Fetching newData mapping |> setIn model
                , Cmd.none
                , if allFetched newData mapping then
                    Resources.AllFetched newData
                  else
                    Resources.LoadingProgress (loadingProgress newData mapping)
                )

        _ ->
            ( model, Cmd.none, Resources.NoNotif )



-- HELPERS ###########################################################


randomize : API.Resources -> Cmd Msg
randomize apiResources =
    let
        ( nbRectangle, nbOutline, nbScribbles ) =
            ( List.length apiResources.rectangle.images
            , List.length apiResources.outline.images
            , List.length apiResources.scribbles.images
            )
    in
        Random.generate
            (tagger << Resources.NewRandomConfig)
            (Random.config nbRectangle nbOutline nbScribbles)


createMapping : API.Resources -> RandomConfig -> Mapping
createMapping urls randomConfig =
    let
        dict urls order =
            Dict.fromList (List.map2 (,) urls order)
    in
        { rectangle = dict urls.rectangle.images randomConfig.rectangle
        , outline = dict urls.outline.images randomConfig.outline
        , scribbles = dict urls.scribbles.images randomConfig.scribbles
        }


insertImageData : Maybe ToolType -> String -> Image -> Mapping -> Data -> Data
insertImageData tool url image mapping data =
    case tool of
        Just Rectangle ->
            Dict.get url mapping.rectangle
                |> Maybe.map (\id -> Dict.insert id ( url, image ) data.rectangle)
                |> Maybe.map (Resources.asRectangleIn data)
                |> Maybe.withDefault data

        Just Outline ->
            Dict.get url mapping.outline
                |> Maybe.map (\id -> Dict.insert id ( url, image ) data.outline)
                |> Maybe.map (Resources.asOutlineIn data)
                |> Maybe.withDefault data

        Just Scribbles ->
            Dict.get url mapping.scribbles
                |> Maybe.map (\id -> Dict.insert id ( url, image ) data.scribbles)
                |> Maybe.map (Resources.asScribblesIn data)
                |> Maybe.withDefault data

        Nothing ->
            data


insertTrainingImage : Maybe ToolType -> String -> Image -> Data -> Data
insertTrainingImage tool url image data =
    case tool of
        Just Rectangle ->
            changeTrainImage url image
                |> Resources.asRectangleIn data.training
                |> Resources.asTrainingIn data

        Just Outline ->
            changeTrainImage url image
                |> Resources.asOutlineIn data.training
                |> Resources.asTrainingIn data

        Just Scribbles ->
            changeTrainImage url image
                |> Resources.asScribblesIn data.training
                |> Resources.asTrainingIn data

        Nothing ->
            data


changeTrainImage : String -> Image -> ( Maybe String, Maybe Image )
changeTrainImage url image =
    ( Just url, Just image )


allFetched : Data -> Mapping -> Bool
allFetched data mapping =
    (trainingFetchedCount data == 3)
        && (Dict.size data.rectangle == Dict.size mapping.rectangle)
        && (Dict.size data.outline == Dict.size mapping.outline)
        && (Dict.size data.scribbles == Dict.size mapping.scribbles)


trainingFetchedCount : Data -> Int
trainingFetchedCount { training } =
    let
        both ( a, b ) =
            if a /= Nothing && b /= Nothing then
                1
            else
                0
    in
        both training.rectangle + both training.outline + both training.scribbles


loadingProgress : Data -> Mapping -> ( Int, Int )
loadingProgress data mapping =
    ( [ data.rectangle, data.outline, data.scribbles ]
        |> List.map Dict.size
        |> List.sum
        |> (+) (trainingFetchedCount data)
    , [ mapping.rectangle, mapping.outline, mapping.scribbles ]
        |> List.map Dict.size
        |> List.sum
        |> (+) 3
    )
