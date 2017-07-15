module Main exposing (..)

import Types exposing (Model, Msg(..))
import Types.Route as Route
import Types.Study as Study
import Types.Study.Resources as Resources
import Types.Log as Log
import Study.Resources as Resources
import Study.API as API
import Route
import Study
import Log
import Navigation exposing (Location)
import Return
import Html exposing (Html)
import Ports
import Http
import Window
import Views.Home as Home
import Views.Study as Study
import Views.Thanks as Thanks
import Views.Error as Error


main : Program Never Model Msg
main =
    Navigation.program (RouteMsg << Route.UrlChange)
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL #############################################################


initialModel : Model
initialModel =
    { currentRoute = Route.Home
    , study = Study.init
    , log = Log.empty
    }


init : Location -> ( Model, Cmd Msg )
init location =
    initialModel
        |> Route.urlUpdate location
        |> Return.command (Http.send (Resources.tagger << Resources.URLs) API.getResources)



-- UPDATE ############################################################


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WindowResizes ->
            ( model, Ports.askContentSize () )

        RouteMsg routeMsg ->
            Route.update routeMsg model

        StudyMsg studyMsg ->
            Study.update studyMsg model

        LogMsg logMsg ->
            Log.update logMsg model


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        baseSubs =
            [ Ports.contentSize (StudyMsg << Study.NewContentSize)
            , Ports.imageFetched (Resources.tagger << Resources.ImageLoaded)
            , Ports.trainImageFetched (Resources.tagger << Resources.TrainImageLoaded)
            ]
    in
        case model.currentRoute of
            Route.Study ->
                Sub.batch <| (Window.resizes <| always WindowResizes) :: baseSubs

            _ ->
                Sub.batch baseSubs



-- VIEW ##############################################################


view : Model -> Html Msg
view model =
    case model.currentRoute of
        Route.Home ->
            Home.view model

        Route.Study ->
            Study.view model

        Route.Thanks ->
            Thanks.view model

        Route.Error ->
            Error.view model
