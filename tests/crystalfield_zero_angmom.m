function ok = test()

% Make sure crystalfield tolerates one zero orbital angular momentum.

clear, clc

S = [3/2 1/2];
L = [1 0];

Sys.S = S;
Sys.L = L;
Sys.soc = [1e4; 0]; 
Sys.J = 1e3; 

stev2 = [0 0 100 0 0];
Sys.CF2 = [stev2;stev2*0];

H = crystalfield(Sys);

ok = length(H)==prod(2*S+1)*prod(2*L+1);