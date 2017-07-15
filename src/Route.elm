module Route exposing (..)

import Types exposing (Model, Msg)
import Types.Route as Route exposing (Route)
import Types.Log as Log exposing (Log)
import Navigation exposing (Location)
import UrlParser as Parse exposing (Parser, (</>))
import Ports
import Time exposing (Time)
import Task


update : Route.Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Route.UrlChange location ->
            urlUpdate location model


urlUpdate : Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    case parse location of
        Just Route.Study ->
            ( { model | currentRoute = Route.Study }
            , Cmd.batch
                [ Ports.askContentSize ()
                , Task.perform (log Route.Study) Time.now
                ]
            )

        Nothing ->
            ( model, modifyUrl Route.Study )


toUrl : Route -> String
toUrl route =
    let
        hash =
            case route of
                Route.Study ->
                    "/study"
    in
        "/#" ++ hash


parser : Parser (Route -> a) a
parser =
    Parse.oneOf
        [ Parse.map Route.Study (Parse.s "study")
        ]


parse : Location -> Maybe Route
parse location =
    Parse.parseHash parser location


modifyUrl : Route -> Cmd msg
modifyUrl =
    toUrl >> Navigation.modifyUrl


newUrl : Route -> Cmd msg
newUrl =
    toUrl >> Navigation.newUrl


log : Route -> Time -> Msg
log route time =
    Log.NavMsg (Log.Timed time route)
        |> Types.LogMsg
