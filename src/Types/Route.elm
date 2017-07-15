module Types.Route exposing (..)

import Navigation exposing (Location)


-- MODEL #############################################################


type Route
    = Home
    | Study
    | Thanks
    | Error



-- MSG ###############################################################


type Msg
    = UrlChange Location
