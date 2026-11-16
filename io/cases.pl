:- module(cases, [title/1, case/3]).
:- use_module('../prolog/renn2q').
:- use_module(engine).
title('renn2q').
table_g(N, T) :- rnd_int(1, 4, N), L is 1 << N, length(T, L), rnd_int(5, 50, P), maplist([B]>>( rnd_chance(P) -> B = 1 ; B = 0 ), T).
case(oracle, [T], oracle) :- table_g(_, T).
case(run_oracle, [C, N, X, Y], run_oracle) :- table_g(N, T), oracle(T, C), L is (1 << N) - 1, rnd_int(0, L, X), rnd_int(0, 1, Y).
case(advantage, [T], advantage) :- table_g(_, T).
case(gate_count, [C], gate_count) :- table_g(_, T), oracle(T, C).
case(grover_iterations, [N, M], grover_iterations) :- rnd_int(1, 10, N), L is 1 << N, rnd_int(0, L, M).
