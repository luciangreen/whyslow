% Theorems, proved by exhaustion. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).
main :- prove_all(theorems).
:- use_module('../prolog/whyslow').

% Domain: every count 0..2 of every kind (3^6 runs).
ops(ops(Ps)) :- kinds(Ks), maplist([K, K-N]>>between(0, 2, N), Ks, Ps).

% 1. The shares add up to the whole gap.
theorem(shares_sum_to_gap) :- forall(ops(O), ( explain(O, gap(G, Ss)), aggregate_all(sum(S), member(_-S-_, Ss), T), T =:= G )).

% 2. Largest share first.
theorem(largest_first) :- forall(ops(O), ( explain(O, gap(_, Ss)), \+ ( nextto(_-A-_, _-B-_, Ss), A < B ) )).

% 3. Only kinds that cost more in Detlog and actually happened are reported, each with a fix.
theorem(only_real_costs_reported) :- forall(( ops(O), O = ops(Ps), explain(O, gap(_, Ss)), member(K-S-F, Ss) ), ( S > 0, memberchk(K-N, Ps), N > 0, string(F) )).

% 4. C is never slower: the gap is never negative, and zero exactly when nothing costly happened.
theorem(gap_is_nonnegative) :- forall(ops(O), ( gap(O, G), G >= 0, explain(O, gap(_, Ss)), iff(G =:= 0, Ss == []) )).
