:- module(cases, [title/1, case/3]).
:- use_module('../prolog/whyslow').
:- use_module(engine).
title('whyslow').
ops_g(ops(Ps)) :- kinds(Ks), rnd_subset(Ks, Sub), maplist([K, K-N]>>rnd_int(0, 500, N), Sub, Ps).
case(explain, [O], explain) :- ops_g(O).
case(gap, [O], gap) :- ops_g(O).
case(total_c, [c, O], total) :- ops_g(O).
case(total_detlog, [detlog, O], total) :- ops_g(O).
