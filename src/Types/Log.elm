module Types.Log exposing (..)

import Types.Route as Route exposing (Route)
import Time exposing (Time)
import Dict exposing (Dict)
import Json.Encode as Encode


-- MODEL #############################################################


type alias Log =
    { navigation : List (Timed Route)
    , study : StudyLog
    }


type Timed a
    = Timed Time a


type alias StudyLog =
    { trainRectangle : List (Timed Mouse)
    , trainOutline : List (Timed Mouse)
    , trainScribbles : ScribblesLog
    , rectangle : Dict String (List (Timed Mouse))
    , outline : Dict String (List (Timed Mouse))
    , scribbles : Dict String ScribblesLog
    , next : List Time
    }


type Mouse
    = Down
    | Up


type alias ScribblesLog =
    { mouse : List (Timed Mouse)
    , msg : List (Timed ScribbleMsg)
    }


type ScribbleMsg
    = Delete
    | ToolFG
    | ToolBG



-- INIT ##############################################################


empty : Log
empty =
    { navigation = []
    , study = emptyStudyLog
    }


emptyStudyLog : StudyLog
emptyStudyLog =
    { trainRectangle = []
    , trainOutline = []
    , trainScribbles = ScribblesLog [] []
    , rectangle = Dict.empty
    , outline = Dict.empty
    , scribbles = Dict.empty
    , next = []
    }



-- HELPERS ###########################################################


asNavigationIn : Log -> List (Timed Route) -> Log
asNavigationIn log navigation =
    { log | navigation = navigation }


asStudyIn : Log -> StudyLog -> Log
asStudyIn log study =
    { log | study = study }


asTrainRectangleIn : StudyLog -> List (Timed Mouse) -> StudyLog
asTrainRectangleIn studyLog a =
    { studyLog | trainRectangle = a }


asTrainOutlineIn : StudyLog -> List (Timed Mouse) -> StudyLog
asTrainOutlineIn studyLog a =
    { studyLog | trainOutline = a }


asTrainScribblesIn : StudyLog -> ScribblesLog -> StudyLog
asTrainScribblesIn studyLog a =
    { studyLog | trainScribbles = a }


asRectangleIn : StudyLog -> Dict String (List (Timed Mouse)) -> StudyLog
asRectangleIn studyLog a =
    { studyLog | rectangle = a }


asOutlineIn : StudyLog -> Dict String (List (Timed Mouse)) -> StudyLog
asOutlineIn studyLog a =
    { studyLog | outline = a }


asScribblesIn : StudyLog -> Dict String ScribblesLog -> StudyLog
asScribblesIn studyLog a =
    { studyLog | scribbles = a }


asMouseIn : ScribblesLog -> List (Timed Mouse) -> ScribblesLog
asMouseIn scribblesLog a =
    { scribblesLog | mouse = a }


asMsgIn : ScribblesLog -> List (Timed ScribbleMsg) -> ScribblesLog
asMsgIn scribblesLog a =
    { scribblesLog | msg = a }


asNextIn : StudyLog -> List Time -> StudyLog
asNextIn studyLog a =
    { studyLog | next = a }



-- MSG ###############################################################


type Msg
    = NavMsg (Timed Route)
    | TrainRectMsg (Timed Mouse)
    | TrainOutMsg (Timed Mouse)
    | TrainScribMouseMsg (Timed Mouse)
    | TrainScribMsg (Timed ScribbleMsg)
    | RectMsg String (Timed Mouse)
    | OutMsg String (Timed Mouse)
    | ScribMouseMsg String (Timed Mouse)
    | ScribMsg String (Timed ScribbleMsg)
    | NextMsg Time



-- ENCODE ############################################################


encode : Log -> Encode.Value
encode log =
    Encode.object
        [ ( "navigation", encodeNavigation log.navigation )
        , ( "study", encodeStudy log.study )
        ]


encodeTimed : (a -> Encode.Value) -> Timed a -> Encode.Value
encodeTimed encoder (Timed time a) =
    Encode.object
        [ ( "time", Encode.float (Time.inSeconds time) )
        , ( "event", encoder a )
        ]


encodeDict :
    (comparable -> Encode.Value)
    -> (b -> Encode.Value)
    -> Dict comparable b
    -> Encode.Value
encodeDict encoderKey encoderValue dict =
    Dict.toList dict
        |> List.map (\( key, value ) -> Encode.list [ encoderKey key, encoderValue value ])
        |> Encode.list


encodeNavigation : List (Timed Route) -> Encode.Value
encodeNavigation navigation =
    List.map (encodeTimed encodeRoute) navigation
        |> Encode.list


encodeRoute : Route -> Encode.Value
encodeRoute route =
    case route of
        Route.Study ->
            Encode.string "study"


encodeStudy : StudyLog -> Encode.Value
encodeStudy study =
    Encode.object
        [ ( "trainRectangle", encodeSelections study.trainRectangle )
        , ( "trainOutline", encodeSelections study.trainOutline )
        , ( "trainScribbles", encodeScribbles study.trainScribbles )
        , ( "rectangle", encodeDict Encode.string encodeSelections study.rectangle )
        , ( "outline", encodeDict Encode.string encodeSelections study.outline )
        , ( "scribbles", encodeDict Encode.string encodeScribbles study.scribbles )
        , ( "next", Encode.list <| List.map (Time.inSeconds >> Encode.float) study.next )
        ]


encodeSelections : List (Timed Mouse) -> Encode.Value
encodeSelections selections =
    List.map (encodeTimed encodeMouse) selections
        |> Encode.list


encodeMouse : Mouse -> Encode.Value
encodeMouse mouse =
    case mouse of
        Down ->
            Encode.string "down"

        Up ->
            Encode.string "up"


encodeScribbles : ScribblesLog -> Encode.Value
encodeScribbles scribbles =
    Encode.object
        [ ( "mouse", encodeSelections scribbles.mouse )
        , ( "msg", Encode.list <| List.map (encodeTimed encodeScribbleMsg) scribbles.msg )
        ]


encodeScribbleMsg : ScribbleMsg -> Encode.Value
encodeScribbleMsg msg =
    case msg of
        Delete ->
            Encode.string "delete"

        ToolFG ->
            Encode.string "toolFG"

        ToolBG ->
            Encode.string "toolBG"
