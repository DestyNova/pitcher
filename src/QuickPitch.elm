port module QuickPitch exposing (Model, Msg(..), update, view)

import Array
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Utilities.Spacing as Spacing
import Browser
import Browser.Events exposing (..)
import Delay
import Dict exposing (Dict)
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
    , scores : Dict String Int
    , targetNoteProbability : Float
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
      , scores = Dict.fromList <| List.map (\note -> ( note, 0 )) noteNames
      , targetNoteProbability = 25
      }
    , Cmd.none
    )


type Msg
    = Start
    | TargetNote Int
    | Play
    | Timeout
    | NextNote ( Float, ( Int, Int ) )
    | Submit
    | KeyDown KeyInput
    | ChangeTarget String
    | ChangeTargetProbability String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Start ->
            ( model, Random.generate TargetNote (Random.int 24 64) )

        TargetNote i ->
            ( { model | mode = GameStarted, targetNote = i }, tone (E.float <| noteToFrequency i) )

        Play ->
            -- 1. chance for target note: 25%, else, uniform among the other 11
            -- 2. octave: +(0, 1, 2, 3)
            -- 3. note (if not target)
            ( model, Random.generate NextNote (Random.pair (Random.float 0 100) (Random.pair (Random.int 0 3) (Random.int 1 11))) )

        NextNote ( targetCheck, ( octave, note ) ) ->
            let
                baseNote =
                    modBy 12 <|
                        if targetCheck < model.targetNoteProbability then
                            model.targetNote

                        else
                            note

                newNote =
                    baseNote + 12 * (octave + 2)
            in
            ( { model | note = newNote, mode = Waiting }, Cmd.batch [ tone (E.float <| noteToFrequency newNote), Delay.after 1.25 Delay.Second Timeout ] )

        Timeout ->
            if model.mode == Waiting then
                let
                    m =
                        if modBy 12 model.note == modBy 12 model.targetNote then
                            { model | scores = addToScore model.targetNote -1 model.scores, mode = Ready False }

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
                        { model | scores = addToScore model.targetNote 1 model.scores, mode = Ready True }

                    else
                        { model | scores = addToScore model.targetNote -1 model.scores, mode = Ready False }
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

        ChangeTargetProbability value ->
            let
                p =
                    Maybe.withDefault 25 (String.toFloat value)
            in
            ( { model | targetNoteProbability = p }, Cmd.none )


addToScore : Int -> Int -> Dict String Int -> Dict String Int
addToScore note increment scores =
    Dict.update (noteToName note)
        (\v ->
            case v of
                Nothing ->
                    Nothing

                Just score ->
                    Just (Basics.max 0 (score + increment))
        )
        scores


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


getScoreFor : String -> Dict String Int -> Int
getScoreFor note scores =
    case Dict.get note scores of
        Nothing ->
            0

        Just score ->
            score



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
            , Grid.row []
                [ Grid.col [ Col.xs2 ]
                    [ h5 [ Spacing.mb2 ]
                        [ a [ A.href "https://github.com/destynova/pitcher" ] [ Badge.badgeSecondary [] [ text "Source code" ] ]
                        ]
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
                    (List.map
                        (\note ->
                            Grid.col [ Col.xs1 ]
                                [ Badge.badgeSecondary [ Spacing.mb2 ]
                                    [ text (note ++ ": " ++ (String.fromInt <| getScoreFor note model.scores))
                                    ]
                                ]
                        )
                        noteNames
                    )
                , Grid.row []
                    [ Grid.col [ Col.xs2 ]
                        [ div [ Spacing.mb2 ]
                            [ case model.mode of
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
                            ]
                        ]
                    , Grid.col [ Col.xs10 ] [ div [] [] ]
                    ]
                , Grid.row []
                    [ Grid.col [ Col.xs8 ]
                        [ div
                            [ A.class "input-group" ]
                            [ div [ A.class "input-group-prepend" ] [ span [ A.class "input-group-text" ] [ text "Target note" ] ]
                            , Select.select [ Select.onChange ChangeTarget ]
                                (List.map (\note -> Select.item [] [ text note ]) ("Choose a note..." :: noteNames))
                            ]
                        ]
                    , Grid.col [ Col.xs4 ]
                        [ div []
                            [ InputGroup.config
                                (InputGroup.number [ Input.onInput ChangeTargetProbability, Input.placeholder "25" ])
                                |> InputGroup.predecessors
                                    [ InputGroup.span [] [ text "Target note probability" ] ]
                                |> InputGroup.successors
                                    [ InputGroup.span [] [ text "%" ] ]
                                |> InputGroup.view
                            ]
                        ]
                    ]
                ]
            ]
        ]
