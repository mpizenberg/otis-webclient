module Types.Route exposing (..)

import Navigation exposing (Location)


-- MODEL #############################################################


type Route
    = Study



-- MSG ###############################################################


type Msg
    = UrlChange Location
