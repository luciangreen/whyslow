% Runs every theorem/1 in a module and reports. A theorem is proved by exhaustion: it is
% checked for every case in a finite domain that covers every branch of the definitions.
% If a counterexample/2 is given for a theorem, a failure prints one.
:- module(prove, [prove_all/1, iff/2]).
:- meta_predicate iff(0, 0).

iff(A, B) :- ( call(A) -> call(B) ; \+ call(B) ).

prove_all(M) :-
    findall(T, clause(M:theorem(T), _), Ts),
    foldl(prove_one(M), Ts, 0, Failed),
    length(Ts, N),
    (   Failed =:= 0 -> format("~w theorems proved.~n", [N])
    ;   format("~w of ~w theorems failed.~n", [Failed, N]), halt(1) ).

prove_one(M, T, F0, F) :-
    (   catch(M:theorem(T), E, (print_message(error, E), fail))
    ->  format("proved  ~w~n", [T]), F = F0
    ;   format("FAILED  ~w~n", [T]),
        ( catch(M:counterexample(T, X), _, fail) -> format("  counterexample: ~q~n", [X]) ; true ),
        F is F0 + 1 ).
