module Types.Study.Resources exposing (..)

import Dict exposing (Dict)
import Image exposing (Image)
import Types.Study.API as API
import Http


-- MODEL #############################################################


type Resources
    = NotFetched
    | Randomizing API.Resources
    | Fetching Data Mapping
    | Fetched Data


type alias Mapping =
    { rectangle : Dict String Int
    , outline : Dict String Int
    , scribbles : Dict String Int
    }


type alias Data =
    { toolOrder : ( ToolType, ToolType, ToolType )
    , training : TrainingData
    , rectangle : Dict Int ( String, Image )
    , outline : Dict Int ( String, Image )
    , scribbles : Dict Int ( String, Image )
    }


type ToolType
    = Rectangle
    | Outline
    | Scribbles


type alias TrainingData =
    { rectangle : ( Maybe String, Maybe Image )
    , outline : ( Maybe String, Maybe Image )
    , scribbles : ( Maybe String, Maybe Image )
    }


type Notif
    = NoNotif
    | LoadingProgress ( Int, Int )
    | AllFetched Data


type alias RandomConfig =
    { toolOrder : ( ToolType, ToolType, ToolType )
    , rectangle : List Int
    , outline : List Int
    , scribbles : List Int
    }



-- HELPERS ###########################################################


asRectangleIn : { a | rectangle : rect } -> rect -> { a | rectangle : rect }
asRectangleIn parent rect =
    { parent | rectangle = rect }


asOutlineIn : { a | outline : out } -> out -> { a | outline : out }
asOutlineIn parent out =
    { parent | outline = out }


asScribblesIn : { a | scribbles : scrib } -> scrib -> { a | scribbles : scrib }
asScribblesIn parent scrib =
    { parent | scribbles = scrib }


asTrainingIn : { a | training : train } -> train -> { a | training : train }
asTrainingIn parent train =
    { parent | training = train }


toolGetter : ToolType -> { a | rectangle : b, outline : b, scribbles : b } -> b
toolGetter tool =
    case tool of
        Rectangle ->
            .rectangle

        Outline ->
            .outline

        Scribbles ->
            .scribbles


toolType : String -> Maybe ToolType
toolType str =
    case str of
        "rectangle" ->
            Just Rectangle

        "outline" ->
            Just Outline

        "scribbles" ->
            Just Scribbles

        _ ->
            Nothing


toolString : ToolType -> String
toolString tool =
    case tool of
        Rectangle ->
            "rectangle"

        Outline ->
            "outline"

        Scribbles ->
            "scribbles"



-- MSG ###############################################################


type Msg
    = URLs (Result Http.Error API.Resources)
    | NewRandomConfig RandomConfig
    | ImageLoaded ( String, String, String, ( Int, Int ) )
    | TrainImageLoaded ( String, String, String, ( Int, Int ) )



-- ENCODE ############################################################
