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
        Just (Route.Home) ->
            ( { model | currentRoute = Route.Home }
            , Task.perform (log Route.Home) Time.now
            )

        Just (Route.Study) ->
            ( { model | currentRoute = Route.Study }
            , Cmd.batch
                [ Ports.askContentSize ()
                , Task.perform (log Route.Study) Time.now
                ]
            )

        Just (Route.Thanks) ->
            ( { model | currentRoute = Route.Thanks }
            , Task.perform (log Route.Thanks) Time.now
            )

        Just (Route.Error) ->
            ( { model | currentRoute = Route.Error }
            , Task.perform (log Route.Error) Time.now
            )

        Nothing ->
            ( model, modifyUrl Route.Error )


toUrl : Route -> String
toUrl route =
    let
        hash =
            case route of
                Route.Home ->
                    "/"

                Route.Study ->
                    "/study"

                Route.Thanks ->
                    "/thanks"

                Route.Error ->
                    "/error"
    in
        "/#" ++ hash


parser : Parser (Route -> a) a
parser =
    Parse.oneOf
        [ Parse.map Route.Home (Parse.top)
        , Parse.map Route.Study (Parse.s "study")
        , Parse.map Route.Thanks (Parse.s "thanks")
        , Parse.map Route.Error (Parse.s "error")
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
