% fftso3   Fast Fourier transform over the rotation group SO(3)
%
%   c = fftso3(fcn,Lmax)
%   [LMK,vals] = fftso3(fcn,Lmax)
%   [c,LMK,vals] = fftso3(fcn,Lmax)
%
% Takes the function fcn(alpha,beta,gamma) defined over the Euler angles
% 0<=alpha<2*pi, 0<=beta<=pi, 0<=gamma<2*pi and calculates the coefficients
% c^L_MK of its tuncated expansion in terms of Wigner D-functions, D^L_MK:
%
%    fcn(alpha,beta,gamma) = sum_(L,M,K) c^L_MK * D^L_MK(alpha,beta,gamma)
%
% where L = 0,..,Lmax, M = -L,..,L, K = -L,..,L.
%
% Input:
%   fcn   function handle for function fcn(alpha,beta,gamma), with angles
%         in units of radians; it should be vectorized and accept array
%         inputs for alpha and gamma
%   Lmax  maximum L for expansion
%
% Output:
%   c     (Lmax+1)-element cell array of Fourier coefficients, L = 0 .. Lmax
%         c{L+1} contains the (2L+1)x(2L+1)-dimensional matrix of expansion
%         coefficients c^L_MK, with M and K ordered in ascending order: M,K =
%         -L,-L+1,..,L.
%   LMK   L, M, and K values of the non-zero coefficients
%   vals  values of the non-zero coefficients

% References:
% 1) P. J. Kostelec, D. N. Rockmore
%    FFTs on the Rotation Group
%    J.Fourier.Anal.Appl. 2008, 14, 145/179
%    https://doi.org/10.1007/s00041-008-9013-5
% 2) D.-M. Lux, C. Wülker, G. S. Chirikjian,
%    Parallelization of the FFT on SO(3)
%    arXiv:1808.00896 [cs.DC]
%    https://arxiv.org/abs/1808.00896

function varargout = fftso3(fcn,Lmax)

if nargin==0
  help(mfilename);
end

if nargin~=2
  error('Two inputs are required (fcn, Lmax).');
end

B = Lmax+1; % bandwidth (0 <=L < B)

% Set up sampling grid over (alpha,beta,gamma)
k = 0:2*B-2;
alpha = 2*pi*k/(2*B-1); % radians
gamma = 2*pi*k/(2*B-1); % radians
[alpha,gamma] = ndgrid(alpha,gamma); % 2D array for function evaluations

k = 0:2*B-1;
beta = pi*(2*k+1)/(4*B); % radians
nbeta = numel(beta);

% Calculate 2D inverse FFT along alpha and gamma, one for each beta
S = cell(1,nbeta);
for j = 1:nbeta
  f = fcn(alpha,beta(j),gamma); % evaluate function over (alpha,gamma) grid
  S_ = (2*B)^2*ifft2(f); % remove the prefactor included by ifft2()
  S_ = fftshift(S_); % reorder to M1,M2 = -B, -B+1, ..., 0, ..., B-1
  S{j} = S_;
end

% Calculate beta weights
q = 0:B-1; % summation index
wB = zeros(1,nbeta);
for j = 1:nbeta
  wB(j) = 2*pi/B^2 * sin(beta(j)) * sum(sin((2*q+1)*beta(j))./(2*q+1));
end

% Calculate Wigner d-function values for all L and beta, with matrix exponential
d = cell(Lmax+1,nbeta);
for L = 0:Lmax
  v = sqrt((1:2*L).*(2*L:-1:1))/2i; % off-diagonals of Jy matrix
  Jy = diag(v,-1) - diag(v,1); % Jy matrix (M1,M2 = -Lmax,-Lmax+1,...,Lmax)
  [U,LL] = eig(Jy);
  LL = diag(LL).'; % equal to -L:L
  for j = 1:nbeta
    e = exp(-1i*beta(j)*LL);
    d{L+1,j} = (U .* e) * U'; % equivalent to U*diag(e)*U'
  end
end

% Calculate Fourier coefficients
c = cell(Lmax+1,1);
for L = 0:Lmax
  c_ = zeros(2*L+1);
  idx = (Lmax+1)+(-L:L); % to access the range M,K = -L:L
  for j = 1:nbeta % run over all beta values
    c_ = c_ + wB(j)*d{L+1,j}.*S{j}(idx,idx);
  end
  c{L+1} = (2*L+1)/(8*pi*B)*c_;
end

% Remove numerical noise
maxcoeff = cellfun(@(x)max(abs(x),[],'all'),c);
threshold = 1e-13*max(maxcoeff);
for L = 0:Lmax
  idx = abs(c{L+1})<threshold;
  c{L+1}(idx) = 0;
end

% Return full matrices or list of non-zero coefficients
returnList = nargout>1;
if returnList
  % Convert to [L M K value] list
  LMK = [];
  vals = [];
  for L = 0:Lmax
    [idxK,idxM,vals_] = find(c{L+1}.'); % transpose to assure lexicographic order of L,M,K
    nNonzero = numel(vals_);
    if nNonzero>0
      LMK = [LMK; repmat(L,nNonzero,1) idxM-L-1 idxK-L-1];
      vals = [vals; vals_];
    end
  end
end

% Organize output
switch nargout
  case 1, varargout = {c};
  case 2, varargout = {LMK,vals};
  case 3, varargout = {c,LMK,vals};
end

end
