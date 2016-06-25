function [err,data] = test(opt,olddata)

%=======================================================
% simple MOMD simulation
%=======================================================

Nitroxide.g = [2.008,2.006,2.003];
Nitroxide.Nucs = '14N';
Nitroxide.A = [20,20,85];
Nitroxide.lw = 0.3;
Nitroxide.tcorr = 1e-8;
Nitroxide.lambda = 1;

Experiment.mwFreq = 9.5;
Experiment.CenterSweep = [338 20];

Options.Verbosity = opt.Verbosity;

[x,y] = chili(Nitroxide,Experiment,opt);

y = y.'/max(abs(y));

data.x = x;
data.y = y;

if ~isempty(olddata)
  if opt.Display
    subplot(4,1,[1,2,3]);
    plot(x,data.y,'r',x,olddata.y,'g');
    subplot(4,1,4);
    plot(x,data.y-olddata.y);
  end
  ok = areequal(y,olddata.y,1e-4);
  err = ~ok;
else
  err = [];
end