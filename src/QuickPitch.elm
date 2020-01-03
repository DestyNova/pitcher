port module QuickPitch exposing (Model, Msg(..), update, view)

import Array
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Browser
import Browser.Events exposing (..)
import Delay
import Html exposing (..)
import Html.Attributes as A
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Random
import Svg as S
import Svg.Attributes exposing (..)


main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { note : Int
    , targetNote : Int
    , mode : GameMode
    , score : Int
    }


type GameMode
    = BeforeGame
    | GameStarted
    | Ready Bool
    | Waiting
    | Completed


type KeyInput
    = Continue
    | Other


keyDecoder : D.Decoder KeyInput
keyDecoder =
    D.map toKeyInput (D.field "key" D.string)


toKeyInput : String -> KeyInput
toKeyInput s =
    case s of
        "x" ->
            Continue

        "X" ->
            Continue

        _ ->
            Other



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { note = 44
      , targetNote = 44
      , mode = BeforeGame
      , score = 0
      }
    , Cmd.none
    )


type Msg
    = Start
    | TargetNote Int
    | Play
    | Timeout
    | NextNote Int
    | Submit
    | KeyDown KeyInput
    | ChangeTarget String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Start ->
            ( model, Random.generate TargetNote (Random.int 24 64) )

        TargetNote i ->
            ( { model | mode = GameStarted, targetNote = i }, tone (E.float <| noteToFrequency i) )

        Play ->
            ( model, Random.generate NextNote (Random.int 24 64) )

        NextNote i ->
            ( { model | note = i, mode = Waiting }, Cmd.batch [ tone (E.float <| noteToFrequency i), Delay.after 1.5 Delay.Second Timeout ] )

        Timeout ->
            if model.mode == Waiting then
                let
                    m =
                        if modBy 12 model.note == modBy 12 model.targetNote then
                            { model | score = clamp 0 100 (model.score - 1), mode = Ready False }

                        else
                            { model | mode = Ready True }
                in
                ( m, Cmd.none )

            else
                ( model, Cmd.none )

        Submit ->
            let
                m =
                    if modBy 12 model.note == modBy 12 model.targetNote then
                        { model | score = clamp 0 100 (model.score + 1), mode = Ready True }

                    else
                        { model | score = clamp 0 100 (model.score - 1), mode = Ready False }
            in
            ( m, Cmd.none )

        KeyDown k ->
            if k == Continue && model.mode == Waiting then
                update Submit model

            else
                ( model, Cmd.none )

        ChangeTarget noteName ->
            let
                n =
                    nameToNote noteName
            in
            update (TargetNote n) model


clamp : Int -> Int -> Int -> Int
clamp low high x =
    Basics.min high (Basics.max low x)



-- SUBS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyDown (D.map KeyDown keyDecoder) ]



-- PORTS


port tone : E.Value -> Cmd msg



-- helpers
-- A4 = 48 semitones up from low A (A1)


noteToFrequency : Int -> Float
noteToFrequency i =
    let
        a =
            2 ^ (1 / 12)

        n =
            toFloat i - 48
    in
    440.0 * a ^ n


findIndex : List a -> a -> Maybe Int
findIndex xs y =
    findIndexRec xs y 0


findIndexRec items y i =
    case items of
        [] ->
            Nothing

        x :: xs ->
            if x == y then
                Just i

            else
                findIndexRec xs y (i + 1)


noteNames =
    [ "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#" ]


noteToName : Int -> String
noteToName i =
    let
        n =
            modBy 12 i
    in
    case Array.get n (Array.fromList noteNames) of
        Nothing ->
            "Error: impossible unless " ++ String.fromInt i ++ " was negative..."

        Just s ->
            s


nameToNote : String -> Int
nameToNote s =
    let
        lowA =
            48
    in
    case findIndex noteNames s of
        Nothing ->
            lowA

        Just i ->
            lowA + i



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Grid.container []
            [ Grid.row []
                [ Grid.col []
                    [ Card.config [ Card.outlinePrimary ]
                        |> Card.block []
                            [ Block.custom <| showStatus model ]
                        |> Card.block []
                            [ Block.custom <|
                                Grid.row []
                                    [ Grid.col []
                                        [ case model.mode of
                                            Waiting ->
                                                Button.button [ Button.warning, Button.block, Button.onClick Submit ]
                                                    [ text "Matches target!" ]

                                            Ready _ ->
                                                Button.button [ Button.success, Button.block, Button.onClick Play ]
                                                    [ text "Next note" ]

                                            GameStarted ->
                                                Button.button [ Button.success, Button.block, Button.onClick Play ]
                                                    [ text "Play note" ]

                                            _ ->
                                                Button.button [ Button.success, Button.block, Button.onClick Start ]
                                                    [ text "Start game" ]
                                        ]
                                    ]
                            ]
                        |> Card.view
                    ]
                ]
            ]
        ]


showStatus : Model -> Html Msg
showStatus model =
    div []
        [ h4 []
            [ Grid.container []
                [ Grid.row []
                    [ Grid.col [ Col.xs10 ]
                        [ div []
                            [ Badge.badgePrimary [] [ text <| "Score: " ++ String.fromInt model.score ]
                            , case model.mode of
                                Ready True ->
                                    Badge.badgeSuccess [] [ text "Correct!" ]

                                Ready False ->
                                    Badge.badgeDanger [] [ text "Wrong!" ]

                                Completed ->
                                    Badge.badgeDanger [] [ text "Level complete!" ]

                                Waiting ->
                                    Badge.badgeWarning [] [ text "Waiting" ]

                                _ ->
                                    text ""
                            , br [] []
                            , text <| "Target note"
                            , Select.select [ Select.onChange ChangeTarget ]
                                (List.map (\note -> Select.item [] [ text note ]) ("Choose a note..." :: noteNames))
                            ]
                        ]
                    , Grid.col [ Col.xs2 ] [ a [ A.href "https://github.com/destynova/pitcher" ] [ Badge.badgeDark [] [ text "Source code" ] ] ]
                    ]
                ]
            ]
        ]
