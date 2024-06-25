port module PitchTest exposing (Model, Msg(..), update, view)

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
import Bootstrap.Table as Table
import Bootstrap.Utilities.Spacing as Spacing
import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (..)
import Html.Attributes as A
import Html.Events exposing (onClick)
import Json.Encode as E
import Random


main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { targetNote : Int
    , lowOffset : Int
    , mode : GameMode
    , errors : List ( String, String, Int )
    , round : Int
    , maxRounds : Int
    }


type GameMode
    = BeforeGame
    | GameStarted
    | Waiting
    | Completed



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { targetNote = 44
      , mode = BeforeGame
      , errors = []
      , round = 1
      , maxRounds = 20
      }
    , Cmd.none
    )


type Msg
    = Start
    | TargetNote (Int, Int)
    | NextNote
    | Guess String
    | GameOver
    | ChangeMaxRounds String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Start ->
            let
                ( startState, _ ) =
                    init ()
            in
            update NextNote { startState | maxRounds = model.maxRounds }

        NextNote ->
            ( model, Random.generate TargetNote (Random.pair (Random.int 24 64) (Random.int 100 1100) )

        TargetNote (i, lowOffset) ->
            ( { model | mode = Waiting, targetNote = i, lowOffset = -lowOffset }, tone (E.float <| noteToFrequency i) )

        Guess noteName ->
            let
                targetNote =
                    modBy 12 model.targetNote

                guessedNote =
                    modBy 12 (nameToNote noteName)

                error =
                    abs (targetNote - guessedNote)

                minError =
                    Basics.min (12 - error) error

                errors =
                    ( noteToName targetNote, noteName, minError ) :: model.errors

                round =
                    model.round + 1

                m =
                    { model | errors = errors, round = round }
            in
            if round > model.maxRounds then
                update GameOver m

            else
                update NextNote m

        GameOver ->
            ( { model | mode = Completed }, Cmd.none )

        ChangeMaxRounds s ->
            let
                n =
                    Maybe.withDefault 32 (String.toInt s)
            in
            ( { model | maxRounds = n }, Cmd.none )



-- SUBS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



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
            [ Grid.row [ Row.centerMd ]
                [ Grid.col []
                    [ Card.config [ Card.outlinePrimary ]
                        |> Card.block []
                            [ Block.titleH4 []
                                [ text "Pitch test"
                                ]
                            , Block.text [] [ text <| "Try to identify a sequence of " ++ String.fromInt model.maxRounds ++ " pitches with no feedback until the end." ]
                            , Block.custom <|
                                div []
                                    [ case model.mode of
                                        BeforeGame ->
                                            showStartControls model.maxRounds

                                        Completed ->
                                            div []
                                                [ showResults model.errors
                                                , showStartControls model.maxRounds
                                                ]

                                        _ ->
                                            showControls model
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


showControls : Model -> Html Msg
showControls model =
    div []
        [ h4 []
            [ text <| "Round: " ++ String.fromInt model.round ++ "/" ++ String.fromInt model.maxRounds
            , Grid.container []
                [ Grid.row [ Row.betweenXs ]
                    (List.map
                        (\note ->
                            Grid.col [ Col.xs1 ]
                                [ Badge.badgeSuccess
                                    [ Spacing.mb2, onClick (Guess note) ]
                                    [ text note ]
                                ]
                        )
                        noteNames
                    )
                ]
            ]
        ]


showResults : List ( String, String, Int ) -> Html Msg
showResults errors =
    div []
        [ div []
            [ text <| "Mean absolute error (semitones): " ++ meanError errors
            , Table.simpleTable
                ( Table.simpleThead
                    [ Table.th [] [ text "Actual note" ]
                    , Table.th [] [ text "Guessed note" ]
                    , Table.th [] [ text "Semitone error" ]
                    ]
                , Table.tbody []
                    (List.map
                        (\( note, guess, error ) ->
                            Table.tr []
                                [ Table.td []
                                    [ text note ]
                                , Table.td []
                                    [ text <| guess ]
                                , Table.td [] [ text <| String.fromInt error ]
                                ]
                        )
                        (List.reverse errors)
                    )
                )
            ]
        ]


meanError : List ( String, String, Int ) -> String
meanError xs =
    toFloat (List.sum <| List.map (\( _, _, error ) -> error) xs)
        / (toFloat <| List.length xs)
        |> String.fromFloat


showStartControls : Int -> Html Msg
showStartControls maxRounds =
    Grid.row []
        [ Grid.col []
            [ InputGroup.config
                (InputGroup.number [ Input.onInput ChangeMaxRounds, Input.placeholder (String.fromInt maxRounds) ])
                |> InputGroup.predecessors
                    [ InputGroup.span [] [ text "Rounds" ] ]
                |> InputGroup.view
            ]
        , Grid.col []
            [ Button.button [ Button.success, Button.block, Button.onClick Start ]
                [ text "Start test" ]
            ]
        ]
