% Theorems about renn2q, proved by exhaustion. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module('../prolog/renn2q').
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).
main :- prove_all(theorems).

% Domain: every boolean function on 1, 2 and 3 bits (2 + 16 + 256 truth tables).
table(N, T) :- between(1, 3, N), L is 1 << N, length(T, L), maplist([B]>>member(B, [0, 1]), T).

% 1. The oracle computes the function: on every input X, with target 0, it writes f(X).
theorem(oracle_computes_function) :-
    forall(( table(N, T), oracle(T, C), nth0(X, T, F) ), run_oracle(C, N, X, 0, F)).

% 2. The oracle is reversible: running it twice gives the target back, for both target values.
theorem(oracle_is_its_own_inverse) :-
    forall(( table(N, T), oracle(T, C), nth0(X, T, _), member(Y, [0, 1]) ), ( run_oracle(C, N, X, Y, Y1), run_oracle(C, N, X, Y1, Y2), Y2 == Y )).

% 3. It uses one multi-controlled NOT per marked input, each with a control on every bit.
theorem(one_gate_per_marked_input) :-
    forall(( table(N, T), oracle(T, C) ), ( marked(T, M), length(C, M), forall(member(mcx(Cs), C), length(Cs, N)) )).

% 4. Grover is offered only when it uses fewer queries than the classical worst case, and never with nothing to find.
theorem(advantage_is_honest) :-
    forall(( table(_, T), advantage(T, A) ), ( A = grover(queries(K), classical(W)) -> K < W, marked(T, M), M > 0 ; true )).

% 5. The X-gate count is twice the number of zero-controls (one X before and one after each).
theorem(x_gates_wrap_zero_controls) :-
    forall(( table(_, T), oracle(T, C) ), ( gate_count(C, counts(_, x_gates(X))), findall(c, ( member(mcx(Cs), C), member(n(_), Cs) ), Zs), length(Zs, Z), X =:= 2 * Z )).
