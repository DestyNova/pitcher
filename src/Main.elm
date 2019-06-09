port module Main exposing (Model, Msg(..), update, view)

import Browser
import Html exposing (..)
import Html.Events exposing (onClick)
import Json.Encode as E


main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { note : Int }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { note = 0 }, Cmd.none )


type Msg
    = Play



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Play ->
            ( model, tone (E.float 440) )



-- SUBS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- PORTS


port tone : E.Value -> Cmd msg



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ button [ onClick Play ] [ text "Play" ] ]
