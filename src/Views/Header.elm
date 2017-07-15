module Views.Header exposing (..)

import Types exposing (Model, Msg)
import Types.Study as Study
import Types.Route as Route exposing (Route)
import Route
import Html exposing (..)
import Html.Attributes exposing (..)


view : Model -> Html Msg
view model =
    case model.study.status of
        Study.SavedOnServer _ ->
            header []
                [ nav []
                    [ navItem Route.Home "Home"
                    , navSep
                    , navItem Route.Study "Study"
                    , navSep
                    , navItem Route.Thanks "Thanks"
                    ]
                ]

        _ ->
            header []
                [ nav []
                    [ navItem Route.Home "Home"
                    , navSep
                    , navItem Route.Study "Study"
                    ]
                ]


navItem : Route -> String -> Html msg
navItem route description =
    a [ href (Route.toUrl route) ] [ span [] [ text description ] ]


navSep : Html msg
navSep =
    div [ class "nav-sep" ] []
