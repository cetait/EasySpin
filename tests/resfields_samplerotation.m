function ok = test()

Sys.S = 1/2;
Sys.g = [2.0 2.1 2.2];
Exp.mwFreq = 22;
Exp.Range = [0 2000];
Exp.SampleFrame = [0 0 0];

% Rotate sample such that zM, yM and xM end up along
% the static field direction zL and calculate resonance fields
rotaxis = [1 1 1];
Exp.SampleRotation = {0,rotaxis};  % zM along zL
Bz = resfields(Sys,Exp);

Exp.SampleRotation = {2*pi/3,rotaxis};  % yM along zL
By = resfields(Sys,Exp);

Exp.SampleRotation = {-2*pi/3,rotaxis};  % xM along zL
Bx = resfields(Sys,Exp);

% Reference values for resonance fields
Bref = unitconvert(Exp.mwFreq*1e3,'MHz->mT',Sys.g);

ok = areequal([Bx By Bz],Bref,1e-10,'abs');
