% Input/output examples: runs this repo's real predicates on inputs made from a fixed seed,
% so the same 200 examples come out every time.
%   swipl -g record -t halt io/run.pl   writes io/ios.pl (one io/4 fact a line) and io/ios.txt
%   swipl -g check  -t halt io/run.pl   runs them again and fails if any output changed
% Cases are in io/cases.pl as clauses case(Name, Args, Predicate) :- <make Args from the seeded
% random numbers>. The predicate is called with those arguments plus the output. Cases take
% turns, in the order they are written, until there are 200 examples.
:- module(ioengine, [rnd_int/3, rnd_pick/2, rnd_chance/1, rnd_some/4, rnd_subset/2, make_ios/2, record/0, check/0]).
:- use_module(library(lists)).
:- use_module(library(apply)).

% ---- a small seeded random number generator (linear congruential, mod 2^31)
seed(S) :- nb_setval(io_seed, S).
next(X) :- nb_getval(io_seed, S), X is (S * 1103515245 + 12345) mod 2147483648, nb_setval(io_seed, X).
rnd_int(Lo, Hi, X) :- next(R), X is Lo + (R >> 8) mod (Hi - Lo + 1).
rnd_pick(L, X) :- length(L, N), N > 0, rnd_int(1, N, I), nth1(I, L, X).
rnd_chance(Percent) :- rnd_int(1, 100, X), X =< Percent.
rnd_some(L, Lo, Hi, Xs) :- rnd_int(Lo, Hi, N), length(Xs, N), maplist([X]>>rnd_pick(L, X), Xs).
rnd_subset([], []).
rnd_subset([X|Xs], Ys) :- ( rnd_chance(50) -> Ys = [X|Ys1] ; Ys = Ys1 ), rnd_subset(Xs, Ys1).

% ---- making the examples
make_ios(Count, Ios) :-
    seed(1),
    findall(N-P, clause(cases:case(N, _, P), _), Cases),
    length(Cases, K),
    numlist(1, Count, Ns),
    maplist(make_one(Cases, K), Ns, Ios).

make_one(Cases, K, I, io(I, Name, Args, Out)) :-
    J is (I - 1) mod K + 1, nth1(J, Cases, Name-Pred),
    ( once(cases:case(Name, Args, Pred)) -> true ; throw(error(generator_failed(Name), _)) ),
    run(Pred, Args, Out).

run(Pred, Args, Out) :-
    append(Args, [O], All), G =.. [Pred|All],
    catch(( cases:G -> Out = O ; Out = fails ), E, ( message_to_codes(E, Out) )).

message_to_codes(E, error(Msg)) :- message_to_codes_(E, Msg).
message_to_codes_(error(Formal, _), Msg) :- !, format(string(Msg), "~q", [Formal]).
message_to_codes_(E, Msg) :- format(string(Msg), "~q", [E]).

% ---- writing and checking
record :-
    make_ios(200, Ios),
    setup_call_cleanup(open('io/ios.pl', write, S, [encoding(utf8)]),
        ( format(S, "% 200 recorded inputs and outputs (swipl -g record -t halt io/run.pl writes this; check compares).~n", []),
          forall(member(Io, Ios), ( write_term(S, Io, [quoted(true), numbervars(false), ignore_ops(false), spacing(next_argument)]), write(S, '.\n') )) ), close(S)),
    write_text(Ios),
    length(Ios, N), format("~w inputs and outputs written to io/ios.pl and io/ios.txt~n", [N]).

write_text(Ios) :-
    cases:title(Title),
    setup_call_cleanup(open('io/ios.txt', write, S, [encoding(utf8)]),
        ( format(S, "~w: 200 inputs and outputs, from real runs (io/ios.pl has the same as Prolog facts).~n~n", [Title]),
          forall(member(io(N, Name, Args, Out), Ios),
                 ( args_text(Args, AT), format(S, "~w. ~w(~w)~n   => ~q~n", [N, Name, AT, Out]) )) ), close(S)).
args_text(Args, T) :- maplist([A, X]>>format(string(X), "~q", [A]), Args, Xs), atomic_list_concat(Xs, ', ', T).

check :-
    read_saved(Saved), length(Saved, N),
    ( N =:= 200 -> true ; format("Expected 200 recorded examples, found ~w~n", [N]), halt(1) ),
    make_ios(200, Now),
    foldl(compare_one, Saved, Now, 0, Bad),
    foldl(steadfast_one, Saved, 0, Bad2),
    ( Bad + Bad2 =:= 0 -> format("All 200 recorded inputs give the recorded outputs, and give them when asked to confirm them.~n")
    ; format("~w changed, ~w not steadfast.~n", [Bad, Bad2]), halt(1) ).

read_saved(Ios) :-
    setup_call_cleanup(open('io/ios.pl', read, S, [encoding(utf8)]), read_all(S, Ios), close(S)).
read_all(S, Xs) :- read_term(S, T, []), ( T == end_of_file -> Xs = [] ; Xs = [T|Ys], read_all(S, Ys) ).

compare_one(io(N, Name, A, O), io(_, _, A2, O2), B0, B) :-
    ( A-O =@= A2-O2 -> B = B0
    ; format("Example ~w (~w) changed:~n  recorded ~q -> ~q~n  now      ~q -> ~q~n", [N, Name, A, O, A2, O2]), B is B0 + 1 ).

% Asked "is the output O?" with the recorded O, the predicate must say yes.
steadfast_one(io(N, Name, A, O), B0, B) :-
    (   O = fails -> B = B0
    ;   O = error(_) -> B = B0
    ;   once(clause(cases:case(Name, _, Pred), _)), append(A, [O], All), G =.. [Pred|All],
        ( catch(cases:G, _, fail) -> B = B0 ; format("Example ~w (~w) is not steadfast: it fails when given its own output.~n", [N, Name]), B is B0 + 1 ) ).
