module Examples.JoyDivision exposing (main)

import Array exposing (Array)
import Browser
import Canvas exposing (..)
import CanvasColor as Color exposing (Color)
import Grid
import Html exposing (..)
import Html.Attributes exposing (style)
import Random
import Time exposing (Posix)


main : Program Float Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


h : number
h =
    500


w : number
w =
    500


padding : number
padding =
    100


stepX =
    10


stepY =
    5


cols =
    (w - padding * 2) // stepX


rows =
    (h - padding * 2) // stepY


cells =
    rows * cols


type alias Points =
    Array { point : ( Float, Float ), random : Float }


type alias Model =
    { count : Int
    , points : Points
    }


type Msg
    = AnimationFrame Posix


coordsToIndex x y =
    -- If x is out of the grid, don't give a valid index
    if x < cols && y < rows then
        y * cols + x

    else
        -1


indexToCoords i =
    ( remainderBy cols i
    , i // cols
    )


coordsToPx ( x, y ) =
    ( x * stepX + stepX / 2 + padding
    , y * stepY + stepY / 2 + padding * 1.3
    )


moveAround r ( x, y ) =
    let
        distanceToCenter =
            abs (x - w / 2)

        maxVariance =
            150

        p =
            ((w - padding * 2 - 100) / 2) / maxVariance

        variance =
            max (-distanceToCenter / p + maxVariance) 0

        random =
            r * variance / 2 * -1
    in
    ( x, y + random )


init : Float -> ( Model, Cmd Msg )
init floatSeed =
    let
        ( randomYs, seed ) =
            Random.initialSeed (floatSeed * 100000 |> floor)
                |> Random.step (Random.list cells (Random.float 0 1))

        pointFromIndexAndRandom i r =
            { point =
                indexToCoords i
                    |> Tuple.mapBoth toFloat toFloat
                    |> coordsToPx
                    |> moveAround r
            , random = r
            }

        points =
            Array.fromList randomYs
                |> Array.indexedMap pointFromIndexAndRandom
    in
    ( { count = 0, points = points }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame delta ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )


bgColor =
    Color.hsl (degrees 260) 0.1 0.1


view : Model -> Html Msg
view model =
    Canvas.element
        w
        h
        []
        (empty
            |> fillStyle bgColor
            |> fillRect 0 0 w h
            |> strokeStyle (Color.hsl (degrees 188) 0.3 0.8)
            |> fillStyle bgColor
            |> lineWidth 1.5
            |> Grid.fold2d { cols = cols, rows = rows } (drawLines model.points)
        )


drawLines : Points -> ( Int, Int ) -> Commands -> Commands
drawLines points ( x, y ) cmds =
    let
        { point } =
            Array.get (coordsToIndex x y) points
                -- This shouldn't happen as we should always be in the matrix
                -- bounds
                |> Maybe.withDefault { point = ( 0, 0 ), random = 0 }

        ( px, py ) =
            point

        drawPoint cs =
            if x == 0 then
                cs
                    |> beginPath
                    |> moveTo px py

            else
                let
                    nextPoint =
                        points
                            |> Array.get (coordsToIndex (x + 1) y)
                            |> Maybe.withDefault { point = ( px + stepX, py ), random = 0 }

                    ( nx, ny ) =
                        nextPoint.point

                    ( xc, yc ) =
                        ( (px + nx) / 2
                        , (py + ny) / 2
                        )
                in
                cs |> quadraticCurveTo px py xc yc

        drawEol cs =
            if x == cols - 1 then
                cs
                    |> fill NonZero
                    |> stroke

            else
                cs
    in
    cmds
        |> drawPoint
        |> drawEol
