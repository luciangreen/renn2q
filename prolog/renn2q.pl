% renn2q: take a boolean function recovered by RENN (as a truth table), build its quantum oracle
% (one multi-controlled NOT per true input, with X gates for the zero bits), check the oracle
% computes the function, and say whether Grover search would beat classical search on it.
% A truth table on N bits is a list of 2^N values 0/1, index = the input read as a binary number.
%?- oracle([0,1,1,0], C).                          % C = [mcx([x(0),n(1)]), mcx([n(0),x(1)])]: XOR on 2 bits
%?- run_oracle(C, 2, 1, 0, Y).                     % Y = 1: f(01) = 1 written into the target
%?- advantage([0,0,0,0,0,0,0,1], A).               % A = grover(queries(2), classical(8))
%?- success_permille(3, 1, 2, P).                  % P = 945: two iterations find it 94.5% of the time
%?- oracle_merged([0,1,1,1], C).                   % C = [mcx([n(0),x(1)]), mcx([x(0)])]: two gates for or, not three
:- module(renn2q, [oracle_merged/2, success_permille/4, oracle/2, run_oracle/5, bit/3, marked/2, grover_iterations/3, advantage/2, gate_count/2]).
:- use_module(library(lists)).
:- use_module(library(apply)).

bit(X, I, B) :- B is (X >> I) /\ 1.

% oracle(+Table, -Circuit): for each input with f = 1, a multi-controlled NOT on the target with
% controls x(I) (bit must be 1) or n(I) (bit must be 0).
oracle(T, C) :- length(T, L), nbits(L, N), Top is L - 1,
    findall(mcx(Cs), ( between(0, Top, X), nth0(X, T, 1), Bt is N - 1, numlist0(Bt, Is), maplist([I, Ctl]>>( bit(X, I, B), ( B =:= 1 -> Ctl = x(I) ; Ctl = n(I) ) ), Is, Cs) ), C0),
    C = C0.
nbits(L, N) :- L > 0, N is msb(L), L =:= 1 << N.
numlist0(Top, Is) :- ( Top < 0 -> Is = [] ; numlist(0, Top, Is) ).

% run_oracle(+Circuit, +N, +X, +Y0, -Y): the target bit after the circuit on input X.
run_oracle(C, _, X, Y0, Y) :- foldl([mcx(Cs), A, B]>>( forall(member(Ct, Cs), fires(Ct, X)) -> B is 1 - A ; B = A ), C, Y0, Y1), Y = Y1.
fires(x(I), X) :- bit(X, I, 1).
fires(n(I), X) :- bit(X, I, 0).

marked(T, M) :- include(==(1), T, Ones), length(Ones, M).

% grover_iterations(+N, +M, -K): the best number of Grover iterations, floor(pi/4 * sqrt(2^N / M)).
grover_iterations(N, M, K) :- ( M =:= 0 -> K = 0 ; K is floor(pi / 4 * sqrt((1 << N) / M)) ).

% advantage(+Table, -A): grover(queries(K), classical(Worst)) when Grover uses fewer queries
% than the classical worst case (2^N - M + 1 tries), else classical(Worst).
advantage(T, A) :- length(T, L), nbits(L, N), marked(T, M),
    W is L - M + 1, grover_iterations(N, M, K0), K is max(1, K0),
    ( M > 0, K < W -> A = grover(queries(K), classical(W)) ; A = classical(W) ).

% oracle_merged(+Table, -Circuit): the same oracle with fewer gates. Two gates whose controls are the same
% except that one needs bit I to be 1 and the other 0 are replaced by one gate without that control, again and
% again. The gates stay disjoint (no input fires two), so the target is still flipped exactly when f = 1.
oracle_merged(T, C) :- oracle(T, C0), maplist([mcx(Cs), S]>>msort(Cs, S), C0, Cubes0), merge_cubes(Cubes0, Cubes), maplist([Cs, mcx(Cs)]>>true, Cubes, C).
merge_cubes(Cs0, Cs) :- ( select(A, Cs0, R1), select(B, R1, R2), one_apart(A, B, M) -> merge_cubes([M|R2], Cs1), msort(Cs1, Cs) ; msort(Cs0, Cs) ).
one_apart(A, B, M) :- select(x(I), A, Rest), select(n(I), B, Rest2), Rest == Rest2, M = Rest.

% success_permille(+N, +M, +K, -P): the chance, in thousandths, that K Grover iterations on 2^N inputs with M
% marked find a marked one: sin^2((2K + 1) * asin(sqrt(M / 2^N))), rounded.
success_permille(N, M, K, P) :- ( M =:= 0 -> P = 0 ; Th is asin(sqrt(M / (1 << N))), P is round(1000 * sin((2 * K + 1) * Th) ** 2) ).

gate_count(C, counts(mcx(G), x_gates(X))) :- length(C, G), foldl([mcx(Cs), A, B]>>( include([Ct]>>(Ct = n(_)), Cs, Ns), length(Ns, K), B is A + 2 * K ), C, 0, X).
