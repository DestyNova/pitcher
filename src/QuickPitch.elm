port module QuickPitch exposing (Model, Msg(..), update, view)

import Array
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Utilities.Spacing as Spacing
import Browser
import Browser.Events exposing (onKeyDown)
import Delay
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as A
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Random
import Random.List exposing (shuffle)
import Svg as S
import Svg.Attributes exposing (..)


main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { playedNote : Bool
    , targetNote : Int
    , mode : GameMode
    , scores : Dict String Int
    , targetNoteProbability : Float
    , timeout : Int
    , chordSize : Int
    }


type GameMode
    = BeforeGame
    | GameStarted
    | Ready Bool
    | Waiting
    | Completed


type KeyInput
    = Continue
    | SelectNextTarget
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

        "n" ->
            SelectNextTarget

        "N" ->
            SelectNextTarget

        _ ->
            Other



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { playedNote = False
      , targetNote = 44
      , mode = BeforeGame
      , scores = Dict.fromList <| List.map (\note -> ( note, 0 )) noteNames
      , targetNoteProbability = 50
      , timeout = 1250
      , chordSize = 1
      }
    , Cmd.none
    )


type Msg
    = Start
    | TargetNote Int
    | Play
    | Timeout
    | NextNote ( Float, ( List Int, List Int ) )
    | Submit
    | KeyDown KeyInput
    | ChangeTarget String
    | ChangeTargetProbability String
    | ChangeTimeout String
    | ChangeChordSize String



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
            ( model, Random.generate NextNote (Random.pair (Random.float 0 100) (Random.pair (Random.list 12 (Random.int 2 5)) (shuffle (List.range 1 11)))) )

        NextNote ( targetCheck, ( octaves, notes ) ) ->
            let
                playNote =
                    targetCheck < model.targetNoteProbability

                chord =
                    List.take model.chordSize <|
                        (if playNote then
                            [ 0 ]

                         else
                            []
                        )
                            ++ notes

                frequencies =
                    List.map2
                        (\octave note ->
                            noteToFrequency (modBy 12 (model.targetNote + note) + 12 * octave)
                        )
                        octaves
                        chord

                _ =
                    Debug.log "frequencies:" frequencies
            in
            ( { model | playedNote = playNote, mode = Waiting }, Cmd.batch [ playTones (E.list E.float frequencies), Delay.after (toFloat model.timeout) Delay.Millisecond Timeout ] )

        Timeout ->
            if model.mode == Waiting then
                let
                    m =
                        if model.playedNote then
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
                    if model.playedNote then
                        { model | scores = addToScore model.targetNote 1 model.scores, mode = Ready True }

                    else
                        { model | scores = addToScore model.targetNote -1 model.scores, mode = Ready False }
            in
            ( m, Cmd.none )

        KeyDown k ->
            case ( k, model.mode ) of
                ( Continue, Waiting ) ->
                    update Submit model

                ( Continue, GameStarted ) ->
                    update Play model

                ( Continue, Ready _ ) ->
                    update Play model

                ( SelectNextTarget, _ ) ->
                    update (TargetNote (44 + (modBy 12 <| model.targetNote - 44 + 5))) model

                _ ->
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

        ChangeTimeout value ->
            let
                d =
                    Maybe.withDefault 1250 (String.toInt value)
            in
            ( { model | timeout = d }, Cmd.none )

        ChangeChordSize value ->
            let
                d =
                    Maybe.withDefault 1 (String.toInt value)
            in
            ( { model | chordSize = d }, Cmd.none )


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


port playTones : E.Value -> Cmd msg



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
            [ Grid.row [ Row.centerMd ]
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
            , Grid.row [ Row.centerMd ]
                [ Grid.col []
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
                [ Grid.row [ Row.betweenXs ]
                    (List.map
                        (\note ->
                            Grid.col [ Col.xs1 ]
                                [ getScoreBadgeType note
                                    (noteToName model.targetNote)
                                    model.mode
                                    [ Spacing.mb2, onClick (ChangeTarget note) ]
                                    [ text (note ++ ": " ++ (String.fromInt <| getScoreFor note model.scores))
                                    ]
                                ]
                        )
                        noteNames
                    )
                , Grid.row []
                    [ Grid.col []
                        [ div []
                            [ InputGroup.config
                                (InputGroup.number [ Input.onInput ChangeTargetProbability, Input.placeholder "50" ])
                                |> InputGroup.predecessors
                                    [ InputGroup.span [] [ text "Target note probability" ] ]
                                |> InputGroup.successors
                                    [ InputGroup.span [] [ text "%" ] ]
                                |> InputGroup.view
                            ]
                        ]
                    , Grid.col []
                        [ div []
                            [ InputGroup.config
                                (InputGroup.number [ Input.onInput ChangeTimeout, Input.placeholder "1250" ])
                                |> InputGroup.predecessors
                                    [ InputGroup.span [] [ text "Time to answer" ] ]
                                |> InputGroup.successors
                                    [ InputGroup.span [] [ text "ms" ] ]
                                |> InputGroup.view
                            ]
                        ]
                    , Grid.col []
                        [ div []
                            [ InputGroup.config
                                (InputGroup.number
                                    [ Input.onInput ChangeChordSize
                                    , Input.placeholder "1"
                                    , Input.attrs [ A.attribute "min" "1", A.attribute "max" "12" ]
                                    ]
                                )
                                |> InputGroup.predecessors
                                    [ InputGroup.span [] [ text "Notes in chord" ] ]
                                |> InputGroup.view
                            ]
                        ]
                    ]
                ]
            ]
        ]


getScoreBadgeType note targetNote mode =
    if note == targetNote then
        case mode of
            Ready True ->
                Badge.badgeSuccess

            Ready False ->
                Badge.badgeDanger

            Waiting ->
                Badge.badgeWarning

            GameStarted ->
                Badge.badgeInfo

            _ ->
                Badge.badgeSecondary

    else
        Badge.badgeSecondary
