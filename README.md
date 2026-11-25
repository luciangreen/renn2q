# renn2q

take a boolean function recovered by RENN (as a truth table), build its quantum oracle (one multi-controlled NOT per true input, with X gates for the zero bits), check the oracle computes the function, and say whether Grover search would beat classical search on it. A truth table on N bits is a list of 2^N values 0/1, index = the input read as a binary number.

## Use

```prolog
?- use_module(prolog/renn2q).
?- oracle([0,1,1,0], C).                          % C = [mcx([x(0),n(1)]), mcx([n(0),x(1)])]: XOR on 2 bits
?- run_oracle(C, 2, 1, 0, Y).                     % Y = 1: f(01) = 1 written into the target
?- advantage([0,0,0,0,0,0,0,1], A).               % A = grover(queries(2), classical(8))
?- success_permille(3, 1, 2, P).                  % P = 945: Grover's answer is right 94.5% of the time, so check it
?- oracle_merged([0,1,1,1], C).                   % C = [mcx([n(0),x(1)]), mcx([x(0)])]: two gates for or, not three
```

## Proofs

`proofs/theorems.pl` proves 6 theorems by exhaustion: each one is checked for every case in a finite domain that covers every branch of the definitions. every boolean function on 1, 2 and 3 bits (2 + 16 + 256 truth tables).

1. The oracle computes the function: on every input X, with target 0, it writes f(X).
2. The oracle is reversible: running it twice gives the target back, for both target values.
3. It uses one multi-controlled NOT per marked input, each with a control on every bit.
4. Grover is offered only when it uses fewer queries than the classical worst case, and never with nothing to find.
5. The X-gate count is twice the number of zero-controls (one X before and one after each).
6. The merged oracle computes the function with at most one gate per marked input (often far fewer), its gates never fire together, and Grover's chance of success is reported: certain for one marked input in four, 94.5% for one in eight after two iterations.

```sh
swipl -g main -t halt proofs/theorems.pl
```

## 200 inputs and outputs

`io/ios.txt` lists 200 inputs and outputs from real runs, and `io/ios.pl` has the same as Prolog facts. The inputs come from a fixed seed (`io/cases.pl`). `swipl -g check -t halt io/run.pl` runs them again. It fails if any output changes, or if a predicate doesn't confirm its own recorded output, which checks steadfastness. GitHub Actions runs the proofs and the examples on every push, and records the examples on the first push.

Licence: BSD-3-Clause.
