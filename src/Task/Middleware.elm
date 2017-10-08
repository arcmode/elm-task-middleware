module Task.Middleware exposing (Middleware, Error(..), connect, mapError, next, end)

{-| This library provides a middleware abstraction that can be used to
run tasks in a pre-defined sequence.


# Definition

@docs Middleware, Error


# Common Helpers

@docs next, end, mapError


# Chaining Middleware

@docs connect

-}

import Task


{-| Represent a middleware unit with an associated task. A middleware task has a companion
value to inform the runner to continue with the next task or to end the sequence.

Middleware units are designed to do work on some "payload" similarly as a reducer
works on Redux applications.

    -- A middleware that does almost nothing looks like this.
    \name -> end (Task.succeed "hello " ++ name)

-}
type alias Middleware x a =
    a -> Task.Task x (Step a)


{-| Represent a choice to run the next middleware or to end the run
-}
type Step a
    = Next a
    | End a


{-| Represent the unexpected situations when we forget to call `end` in the sequence or some middleware
task failed
-}
type Error a
    = NeverEnded
    | Middleware a


{-| Transform a `Task` into a return value for a middleware unit choosing to continue

    next (Task.succeed 200)

-}
next : Task.Task x a -> Task.Task x (Step a)
next =
    Task.map Next


{-| Transform a `Task` into a return value for a middleware unit choosing to end

    end (Task.fail 420)

-}
end : Task.Task x a -> Task.Task x (Step a)
end =
    Task.map End


{-| Connect a list of middleware units into a single task

    connect
        [ (\n -> next (Task.succeed n))
        , (n -> end (Task.succeed (* n n)))
        ]
        2

-}
connect :
    List (Middleware x a)
    -> a
    -> Task.Task (Error x) a
connect list payload =
    case list of
        [] ->
            Task.fail NeverEnded

        first :: rest ->
            (first payload)
                |> Task.mapError Middleware
                |> Task.andThen (handleStep rest)


{-| Handles a middleware step choice by either connecting to the next unit or ending the run
-}
handleStep : List (Middleware x a) -> Step a -> Task.Task (Error x) a
handleStep list step =
    case step of
        Next payload ->
            connect list payload

        End payload ->
            Task.succeed payload


{-| Map a failing middleware error to some other type of error
-}
mapError : (x -> y) -> Middleware x a -> Middleware y a
mapError err mid =
    mid >> Task.mapError err
