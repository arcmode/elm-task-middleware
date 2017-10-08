## Task.Middleware

This library provides a middleware abstraction that can be used to run tasks in a pre-defined sequence.

### Definition

	type alias Middleware x a =
        a -> Task x (Step a)

Represent a middleware unit with an associated task. A middleware task has a companion value to inform the runner to continue with the next task or to end the sequence.

Middleware units are designed to do work on some "payload" similarly as a reducer works on Redux applications.

    -- A middleware that does almost nothing looks like this.
    \name -> end (Task.succeed "hello " ++ name)


### Error a

	type Error a = NeverEnded
                 | Middleware a

Represent the unexpected situation when we forget to call `end` in the sequence or a middleware task failed

## Common Helpers

### next : Task x a -> Task x (Step a)

Transform a `Task` into a return value for a middleware unit choosing to continue

    next (Task.succeed 200)

### end : Task x a -> Task x (Step a)

Transform a `Task` into a return value for a middleware unit choosing to end

    end (Task.fail 420)

### mapError : (x -> y) -> Middleware) x a -> Middleware y a

Map a failing middleware error to some other type of error

## Chaining Middleware

### connect : -> List (Middleware x a) -> a -> Task (Error x) a

Connect a list of middleware units into a single task

    connect
        [ (\n -> next (Task.succeed n))
        , (n -> end (Task.succeed (* n n)))
        ]
        2
