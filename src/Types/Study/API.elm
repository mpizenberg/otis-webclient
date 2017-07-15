module Types.Study.API exposing (..)

import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)


type alias Resources =
    { rectangle : InteractionResources
    , outline : InteractionResources
    , scribbles : InteractionResources
    }


type alias InteractionResources =
    { trainingImage : String
    , images : List String
    }



-- CODECS ############################################################


decodeResources : Decoder Resources
decodeResources =
    Decode.map3 Resources
        (Decode.field "rectangle" decodeInteractionResources)
        (Decode.field "outline" decodeInteractionResources)
        (Decode.field "scribbles" decodeInteractionResources)


decodeInteractionResources : Decoder InteractionResources
decodeInteractionResources =
    Decode.map2 InteractionResources
        (Decode.field "training-image" Decode.string)
        (Decode.field "images" <| Decode.list Decode.string)



-- HTTP ##############################################################


type alias Request a =
    { method : String
    , token : Maybe String
    , url : String
    , body : Http.Body
    , expect : Http.Expect a
    }


get : String -> Http.Expect a -> Request a
get url expect =
    { method = "GET"
    , token = Nothing
    , url = url
    , body = Http.emptyBody
    , expect = expect
    }


post : String -> Http.Expect a -> Encode.Value -> Request a
post url expect value =
    { method = "POST"
    , token = Nothing
    , url = url
    , body = Http.jsonBody value
    , expect = expect
    }


setToken : Maybe String -> Request a -> Request a
setToken token request =
    { request | token = token }


http : Request a -> Http.Request a
http request =
    Http.request
        { method = request.method
        , headers =
            case request.token of
                Nothing ->
                    []

                Just token ->
                    [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = request.url
        , body = request.body
        , expect = request.expect
        , timeout = Nothing
        , withCredentials = False
        }
