% esfit_grid   Function minimization using grid search
%
%  xfit = esfit_grid(fcn,lb,ub)
%  ...  = esfit_grid(fcn,lb,ub,opt)
%  [xfit,info] = ...
%
%  Finds x that minimzes fcn(x), running over a grid of parameter values.
%
%  Input:
%    fcn     function handle of fcn(x) to minimize
%    lb      lower bounds of parameters
%    ub      lower bounds of parameters
%    opt     structure with algorithm parameters
%      .TolFun
%      .GridSize
%      .randGrid
%      .maxGridPoints
%      .IterFcn   function that is called after each iteration

function [bestx,info] = esfit_grid(fcn,lb,ub,opt)

% Supplement default values for options
if ~isfield(opt,'TolFun'), opt.TolFun = 1e-5; end
if ~isfield(opt,'GridSize'), opt.GridSize = 7; end
if ~isfield(opt,'randGrid'), opt.randGrid = true; end
if ~isfield(opt,'maxGridPoints'), opt.maxGridPoints = 1e5; end

if ~isfield(opt,'IterFcn') || isempty(opt.IterFcn)
  opt.IterFcn = @(info)false;
end

% Process parameter bounds
lb = lb(:);
ub = ub(:);
if numel(lb)~=numel(ub)
  error('Arrays for lower and upper bound must have the same number of elements.');
end
if any(lb>ub)
  error('Lower bounds must not be greater than upper bounds.');
end
nParams = numel(lb);

% Process grid
GridSize = opt.GridSize;
if numel(GridSize)==1
  GridSize = GridSize*ones(1,nParams);
end
if numel(GridSize)~=nParams
  error('FitOpt.GridSize must have as many elements as there are fitting parameters.');
end
if any(GridSize<2)
  error('At least two grid points per parameter are needed.');
end
nGridPoints = prod(GridSize);
if nGridPoints>opt.maxGridPoints
  error('Cannot do grid search with more than %d points. Reduce number of parameters.',opt.maxGridPoints);
end

if opt.Verbosity
  fprintf('%d parameters, %d grid points total\n',nParams,nGridPoints);
end

if ~isempty(opt.IterFcn) && ~isa(opt.IterFcn,'function_handle')
  error('Opt.IterFcn must be a function handle.');
end

% Set up grid
%--------------------------------------------------------------------------
gridvals = cell(1,nParams);
for p = 1:nParams
  gridvals{p} = linspace(lb(p),ub(p),GridSize(p));
end
X = cell(1,nParams);
[X{:}] = ndgrid(gridvals{:});
for p = 1:nParams
  X{p} = X{p}(:);
end
X = [X{:}].'; % each column represents one point in parameter space

% Randomize order of gridpoints if requested
if opt.randGrid
  X = X(:,randperm(nGridPoints));
end

% Evaluate function over grid
%--------------------------------------------------------------------------
minF = inf;
bestx = NaN(nParams,1);
startTime = cputime;
stopCode = 0;
nEvals = 0;
iIteration = 0;
for idx = 1:nGridPoints
  
  F = fcn(X(:,idx));
  nEvals = nEvals+1;
  iIteration = iIteration+1;
  
  newbest = F<minF;
  if newbest
    minF = F;
    bestx = X(:,idx);
    if opt.Verbosity
      str = sprintf('  Point %4d/%d:   error %0.5e  best so far',iIteration,nGridPoints,F);
      opt.IterationPrintFunction(str);
    end
  end
  
  info.currx = X(:,idx);
  info.currF = F;
  info.bestx = bestx;
  info.minF = minF;
  info.nEvals = nEvals;
  info.iter = iIteration;
  info.newbest = newbest;
  UserStop = opt.IterFcn(info);
  
  elapsedTime = (cputime-startTime)/60;
  if elapsedTime>opt.maxTime, stopCode = 1; end
  if UserStop, stopCode = 2; end
  if minF<opt.TolFun, stopCode = 3; end
  
  if stopCode~=0, break; end
  
end

if opt.Verbosity>1
  switch stopCode
    case 0, msg = 'Terminated: all grid points searched.';
    case 1, msg = sprintf('Terminated: Time limit of %f minutes reached.',opt.maxTime);
    case 2, msg = 'Terminated: Stopped by user.';
    case 3, msg = sprintf('Terminated: Found a parameter set with error less than %g.',opt.TolFun);
  end
  disp(msg);
  info.msg = msg;
end

info.stop = stopCode;

end
