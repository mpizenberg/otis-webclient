module Views.Thanks exposing (..)

import Types exposing (Model, Msg)
import Html exposing (..)
import Html.Attributes exposing (..)
import Views.Header as Header


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ Header.view model
        ]
