% ctafft  Cross-term averaged FFT 
%
%   FD = ctafft(TD,Averages)
%   FD = ctafft(TD,Averages,N)
%
%   Similar to a magnitude FFT, but removes
%   dead-time artefacts using cross-term
%   averging.
%   TD: Time-domain data. For matrices
%      TD, ctafft works along columns.
%   Averages: Starting indices for the FFTs
%     for TD(Averages(i):end). IF Averages is
%     a single number, it stands for 1:Averages.
%   N: Length of FFT. If omitted, N is set to
%     the length of TD (or its columns).

function FD = ctafft(TD,Averages,N)

if nargin==0, help(mfilename); return; end

% Set default for third (optional) argument N.
if nargin<3, N = size(TD,1); end

if any(Averages<0) || any(mod(Averages,1))
  error('Averages must contain positive integers!');
end

if numel(Averages)==1
  Averages = 1:Averages;
end

% Convert row vector to column vector.
RowVec = (numel(TD)==size(TD,2));
if RowVec, TD = TD.'; end

if any(Averages>=size(TD,1))
  error('Entries in Averages cannot be larger than the length of TD!');
end

% Do the cross-term averaging.
FD = zeros(N,size(TD,2));
for k = 1:numel(Averages)
  newFD = fft(TD(Averages(k):end,:),N);
  FD = FD + abs(newFD).^2;
end
FD = sqrt(FD/numel(Averages));

% Convert column vector back to row.
if RowVec, FD = FD.'; end

return
