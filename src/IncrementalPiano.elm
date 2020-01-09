port module IncrementalPiano exposing (Model, Msg(..), update, view)

import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Browser
import Browser.Events exposing (..)
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
    { note : Int, mode : GameMode, level : Int, rangeStart : Int, bestScore : Int }


type GameMode
    = BeforeGame
    | Ready Bool
    | Waiting
    | GameOver


initialRange =
    36


type KeyInput
    = Left
    | Right
    | Enter
    | Other


keyDecoder : D.Decoder KeyInput
keyDecoder =
    D.map toKeyInput (D.field "key" D.string)


toKeyInput : String -> KeyInput
toKeyInput s =
    case s of
        "ArrowLeft" ->
            Left

        "ArrowRight" ->
            Right

        "Enter" ->
            Enter

        _ ->
            Other



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { note = 44, mode = BeforeGame, level = 1, rangeStart = 32, bestScore = 0 }, Cmd.none )


type Msg
    = Play
    | NextNote Int
    | Submit
    | KeyDown KeyInput
    | ClickedNote String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Play ->
            let
                m =
                    case model.mode of
                        GameOver ->
                            { model | level = 1 }

                        _ ->
                            model
            in
            ( m, Random.generate NextNote (Random.int 12 75) )

        NextNote i ->
            ( { model | note = i, mode = Waiting }, tone (E.float <| noteToFrequency i) )

        Submit ->
            let
                lower =
                    model.rangeStart

                upper =
                    model.rangeStart + selectionSize model.level

                m =
                    if lower <= model.note && model.note <= upper then
                        { model | level = model.level + 1, bestScore = Basics.max model.bestScore model.level, mode = Ready True }

                    else if model.level == 1 then
                        { model | mode = GameOver, bestScore = Basics.max model.bestScore model.level }

                    else
                        { model | level = model.level - 1, mode = Ready False }
            in
            ( m, Cmd.none )

        KeyDown k ->
            if k == Enter then
                if model.mode == Waiting then
                    update Submit model

                else
                    update Play model

            else
                let
                    desiredRangeStart =
                        model.rangeStart
                            + (case k of
                                Left ->
                                    -1

                                Right ->
                                    1

                                _ ->
                                    0
                              )
                in
                ( { model | rangeStart = clamp 0 (87 - selectionSize model.level) desiredRangeStart }, Cmd.none )

        ClickedNote id ->
            case String.toInt id of
                Nothing ->
                    ( model, Cmd.none )

                Just key ->
                    let
                        w =
                            selectionSize model.level

                        rangeStart =
                            key - w // 2
                    in
                    ( { model | rangeStart = clamp 0 (87 - w) rangeStart }, Cmd.none )


clamp : Int -> Int -> Int -> Int
clamp low high x =
    Basics.min high (Basics.max low x)


selectionSize : Int -> Int
selectionSize level =
    initialRange - level + 1



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
                            [ Block.custom <| showPiano model ]
                        |> Card.block []
                            [ Block.custom <|
                                Grid.row []
                                    [ Grid.col []
                                        [ Button.button [ Button.success, Button.block, Button.disabled (model.mode == Waiting), Button.onClick Play ]
                                            [ text "Play" ]
                                        ]
                                    , Grid.col []
                                        [ Button.button [ Button.info, Button.block, Button.disabled (model.mode /= Waiting), Button.onClick Submit ]
                                            [ text "Confirm" ]
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
                            [ Badge.badgePrimary [] [ text <| "Level " ++ String.fromInt model.level ++ "/36" ]
                            , br [] []
                            , Badge.badgeInfo [] [ text <| "Best so far " ++ String.fromInt model.bestScore ++ "/36" ]
                            , br [] []
                            , case model.mode of
                                Ready True ->
                                    Badge.badgeSuccess [] [ text "Correct!" ]

                                Ready False ->
                                    Badge.badgeDanger [] [ text "Wrong!" ]

                                GameOver ->
                                    Badge.badgeDanger [] [ text "Game over!" ]

                                Waiting ->
                                    Badge.badgeWarning [] [ text "Waiting" ]

                                _ ->
                                    text ""
                            , br [] []
                            , if model.level >= 36 then
                                Badge.badgeDark [] [ text "Master" ]

                              else
                                text ""
                            ]
                        ]
                    , Grid.col [ Col.xs2 ] [ a [ A.href "https://github.com/destynova/pitcher" ] [ Badge.badgeDark [] [ text "Source code" ] ] ]
                    ]
                ]
            ]
        ]


showPiano : Model -> Html Msg
showPiano model =
    let
        pianoRange =
            List.range 0 87

        whiteKeys =
            List.map
                (showKey model False)
                (List.indexedMap Tuple.pair (List.filter (not << isBlackKey) pianoRange))

        blackKeys =
            List.map
                (showKey model True)
                (List.indexedMap Tuple.pair (List.filter isBlackKey pianoRange))
    in
    div [ style "text-align: center" ]
        [ S.svg
            [ width "860"
            , height "200"
            , viewBox "0 0 860 200"
            ]
            (whiteKeys ++ blackKeys)
        ]


blackNotes : List Int
blackNotes =
    [ 1, 4, 6, 9, 11 ]


blackOffset : Int -> Int
blackOffset scaleNote =
    case scaleNote of
        1 ->
            0

        4 ->
            2

        6 ->
            3

        9 ->
            5

        11 ->
            6

        _ ->
            0


isBlackKey : Int -> Bool
isBlackKey key =
    List.member (modBy 12 key) blackNotes



-- 0, 3, 5, 8, 10
-- 0, 2, 3, 5, 6


noteColour : Model -> Int -> Bool -> String
noteColour model key isBlack =
    let
        lower =
            model.rangeStart

        upper =
            model.rangeStart + initialRange + 1 - model.level

        inSelection =
            model.mode /= BeforeGame && lower <= key && key <= upper
    in
    if inSelection && isBlack then
        "teal"

    else if inSelection then
        "turquoise"

    else if (model.mode == GameOver || model.mode == Ready False) && model.note < lower && key < lower then
        "red"

    else if (model.mode == GameOver || model.mode == Ready False) && model.note > upper && key > upper then
        "red"

    else if isBlack then
        "black"

    else if key == 39 then
        -- middle C... better add note names tho
        "green"

    else
        "white"


showKey : Model -> Bool -> ( Int, Int ) -> Html Msg
showKey model isBlack ( i, key ) =
    let
        keyWidth =
            16

        drawWidth =
            keyWidth
                - (if isBlack then
                    4

                   else
                    0
                  )

        scaleNote =
            modBy 12 key

        keyHeight =
            if isBlack then
                "48"

            else
                "72"

        xOffset =
            if isBlack then
                (key // 12 * 7 + blackOffset scaleNote) * keyWidth + keyWidth // 2 + 2

            else
                i * keyWidth

        status =
            noteColour model key isBlack
    in
    S.rect
        [ x (String.fromInt <| xOffset)
        , y "10"
        , width (String.fromInt drawWidth)
        , height keyHeight
        , style <|
            "stroke:black;fill:"
                ++ status
        , id (String.fromInt key)
        , noteClick
        ]
        []


noteClick : Html.Attribute Msg
noteClick =
    let
        decoder =
            D.oneOf
                [ D.map ClickedNote (D.at [ "target", "id" ] D.string)
                , D.succeed (ClickedNote "")
                ]
    in
    Html.Events.on "click" decoder
