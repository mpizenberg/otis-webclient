module Views.Study exposing (..)

import Types exposing (Model, Msg)
import Types.Study as Study
import Types.Study.Train as Train exposing (Train(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Views.Header as Header
import Views.Study.Rectangle as Rectangle
import Views.Study.Outline as Outline
import Views.Study.Scribbles as Scribbles
import Views.Study.TrainRectangle as TrainRectangle
import Views.Study.TrainOutline as TrainOutline
import Views.Study.TrainScribbles as TrainScribbles
import Pivot


view : Model -> Html Msg
view model =
    case model.study.status of
        Study.LoadingResources n total ->
            div [ id "app" ]
                [ Header.view model
                , div [ id "content", class "content" ]
                    [ p []
                        [ text "Loading resources ...  "
                        , progress [ value (toString n), Html.Attributes.max (toString total) ] []
                        ]
                    ]
                ]

        Study.Progressing steps ->
            case Pivot.getC steps of
                Study.RectangleStep ( imageUrl, rectangle ) ->
                    Rectangle.view (Study.progress steps) model imageUrl rectangle

                Study.OutlineStep ( imageUrl, outline ) ->
                    Outline.view (Study.progress steps) model imageUrl outline

                Study.ScribblesStep ( imageUrl, scribbles ) ->
                    Scribbles.view (Study.progress steps) model imageUrl scribbles

                Study.TrainRectStep ( imageUrl, Train rectangle ) ->
                    TrainRectangle.view (Study.progress steps) model imageUrl rectangle

                Study.TrainOutStep ( imageUrl, Train outline ) ->
                    TrainOutline.view (Study.progress steps) model imageUrl outline

                Study.TrainScribStep ( imageUrl, Train scribbles ) ->
                    TrainScribbles.view (Study.progress steps) model imageUrl scribbles

        Study.Finished _ ->
            div [ id "app" ]
                [ Header.view model
                , div [ id "content", class "content" ]
                    [ p [] [ saveButton ] ]
                ]

        Study.SavingError _ ->
            div [ id "app" ]
                [ Header.view model
                , div [ id "content", class "content" ]
                    [ p [] [ text "Oups, an error occurred while saving on the server, please retry" ]
                    , p [] [ saveButton ]
                    ]
                ]

        Study.SavedOnServer userId ->
            div [ id "app" ]
                [ Header.view model
                , div [ id "content", class "content" ]
                    [ p [] [ text ("Successfully saved, your id is: " ++ toString userId) ] ]
                ]


saveButton : Html Msg
saveButton =
    button
        [ class "button-save", onClick (Types.StudyMsg Study.SendToServer) ]
        [ text "Save annotations to the server" ]
