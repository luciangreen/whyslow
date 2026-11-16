# whyslow

explain why C is still faster than Detlog on a program, and what optimisation is missing. A run is summarised by counts of each kind of operation; Detlog and C each have a cost per kind. The gap is split into each kind's share, largest first, and each kind comes with the optimisation that would close it.

## Use

```prolog
?- use_module(prolog/whyslow).
?- explain(ops([choicepoint-100, unify-400, arith-50, alloc-30]), E).
?- gap(ops([unify-10]), G).
```

## Proofs

`proofs/theorems.pl` proves 4 theorems by exhaustion: each one is checked for every case in a finite domain that covers every branch of the definitions. every count 0..2 of every kind (3^6 runs).

1. The shares add up to the whole gap.
2. Largest share first.
3. Only kinds that cost more in Detlog and actually happened are reported, each with a fix.
4. C is never slower: the gap is never negative, and zero exactly when nothing costly happened.

```sh
swipl -g main -t halt proofs/theorems.pl
```

## 200 inputs and outputs

`io/ios.txt` lists 200 inputs and outputs from real runs, and `io/ios.pl` has the same as Prolog facts. The inputs come from a fixed seed (`io/cases.pl`). `swipl -g check -t halt io/run.pl` runs them again. It fails if any output changes, or if a predicate doesn't confirm its own recorded output, which checks steadfastness. GitHub Actions runs the proofs and the examples on every push, and records the examples on the first push.

Licence: BSD-3-Clause.
