% whyslow: explain why C is still faster than Detlog on a program, and what optimisation is
% missing. A run is summarised by counts of each kind of operation; Detlog and C each have a
% cost per kind. The gap is split into each kind's share, largest first, and each kind comes
% with the optimisation that would close it.
%?- explain(ops([choicepoint-100, unify-400, arith-50, alloc-30]), E).
%?- gap(ops([unify-10]), G).
:- module(whyslow, [cost/3, total/3, gap/2, explain/2, fix/2, kinds/1]).
:- use_module(library(lists)).
:- use_module(library(apply)).

kinds([choicepoint, unify, arith, alloc, call, index]).
% cost(System, Kind, Units)
cost(detlog, choicepoint, 9). cost(c, choicepoint, 0).
cost(detlog, unify, 3).       cost(c, unify, 1).
cost(detlog, arith, 2).       cost(c, arith, 1).
cost(detlog, alloc, 6).       cost(c, alloc, 2).
cost(detlog, call, 4).        cost(c, call, 2).
cost(detlog, index, 1).       cost(c, index, 1).

fix(choicepoint, "remove the choicepoint: convert it to a deterministic splice (detlog2)").
fix(unify, "specialise unification on known modes, so it becomes plain assignment").
fix(arith, "unbox the numbers and compile the arithmetic directly").
fix(alloc, "allocate in regions instead of on the heap (regionmem)").
fix(call, "inline the small predicate").
fix(index, "nothing: indexing already costs the same").

total(Sys, ops(Ps), T) :- foldl([K-N, A0, A]>>( cost(Sys, K, C), A is A0 + N * C ), Ps, 0, T).
gap(Ops, G) :- total(detlog, Ops, D), total(c, Ops, C), G is D - C.

% explain(+Ops, -Explanation): gap(G, Shares) with Shares = [Kind-Share-Fix], largest share first, zero shares left out.
explain(ops(Ps), gap(G, Shares)) :- gap(ops(Ps), G),
    findall(S-(K-S-F), ( member(K-N, Ps), cost(detlog, K, D), cost(c, K, C), S is N * (D - C), S > 0, fix(K, F) ), L0),
    keysort(L0, L1), reverse(L1, L2), pairs_values(L2, Shares).
