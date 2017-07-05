function [err,data] = test(opt,olddata)
% Check that supplying a pseudopotential energy function to stochtraj 
% generates a proper distribution of orientations

% generate Euler angle grids
N = 50;
agrid = linspace(-180, 180, N)/180*pi;
bgrid = linspace(0, 180, N)/180*pi;
ggrid = linspace(-180, 180, N)/180*pi;
% [Agrid, Bgrid, Ggrid] = meshgrid(agrid, bgrid, ggrid);

fwhma = 60/180*pi;
fwhmb = 60/180*pi;
fwhmg = 60/180*pi;

% [funa, funb, fung] = meshgrid(gaussian(agrid, 0, fwhma), ...
%                               gaussian(bgrid, 0, fwhma), ...
%                               gaussian(ggrid, 0, fwhma));

[funa, funb, fung] = meshgrid(wrappedgaussian(agrid, 0, fwhma), ...
                              wrappedgaussian(bgrid, 0, fwhmb, [0,pi]), ...
                              wrappedgaussian(ggrid, 0, fwhmg));

PotFun = funa.*funb.*fung;

Sys.tcorr = 10*1e-9;
Sys.PseudoPotFun = PotFun;

Par.dt = Sys.tcorr/10;
Par.nSteps = ceil(400*Sys.tcorr/Par.dt);
Par.nTraj = 400;

nTraj = Par.nTraj;
nSteps = Par.nSteps;

nBins = N;

AlphaBins = linspace(-pi, pi, nBins);
BetaBins = linspace(0, pi, nBins);
GammaBins = linspace(-pi, pi, nBins);

% form grids to be acted upon by Boltzmann distribution function
% expressions
[Agrid,Bgrid,Ggrid] = meshgrid(AlphaBins,BetaBins,GammaBins);

% pre-allocate array for 3D histograms
% note that the output will be of size (nBins,nBins,nBins), rather than the 
% typical (nBins-1,nBins-1,nBins-1) size output from MATLAB's hist
% functions
Hist3D = zeros(nBins, nBins, nBins, nTraj);
     
err = 0;

[~, ~, qTraj] = stochtraj(Sys,Par);  % extract quaternions from trajectories

N = round(nSteps/2);

for iTraj=1:nTraj
  % use a "burn-in method" by taking last half of each trajectory
  [alpha, beta, gamma] = quat2euler(qTraj(:,iTraj,N:end));
  alpha = squeeze(alpha);
  beta = squeeze(beta);
  gamma = squeeze(gamma);
  
  % calculate 3D histogram using function obtained from Mathworks File Exchange
  [Hist3D(:,:,:,iTraj),~] = histcnd([alpha,beta,gamma],{AlphaBins,BetaBins,GammaBins});
end

% Hist3D = permute(Hist3D, [2, 1, 3, 4]);
Hist3D = mean(Hist3D, 4);  % average over all trajectories
Hist3D = Hist3D/sum(Hist3D(:));  % normalize
rmsd = calc_rmsd(PotFun,Hist3D,Agrid,Bgrid,Ggrid);

if rmsd>1e-2||any(isnan(Hist3D(:)))
  % numerical result does not match analytical result
  err = 1;
end

data = [];


% Helper function to compare numerical result with analytic expression
% -------------------------------------------------------------------------

function rmsd = calc_rmsd(PotFun, Hist3D, Agrid, Bgrid, Ggrid)

residuals = Hist3D - PotFun;
rmsd = sqrt(mean(reshape(residuals.^2,[1,numel(Hist3D)])));

end

end
