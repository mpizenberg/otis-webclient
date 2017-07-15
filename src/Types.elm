module Types exposing (..)

import Types.Route as Route exposing (Route)
import Types.Study as Study exposing (Study)
import Types.Log as Log exposing (Log)


-- MODEL #############################################################


type alias Model =
    { currentRoute : Route
    , study : Study
    , log : Log
    }



-- HELPERS ###########################################################


asStudyIn : Model -> Study -> Model
asStudyIn model study =
    { model | study = study }


asLogIn : Model -> Log -> Model
asLogIn model log =
    { model | log = log }



-- MSG ###############################################################


type Msg
    = WindowResizes
    | RouteMsg Route.Msg
    | StudyMsg Study.Msg
    | LogMsg Log.Msg
