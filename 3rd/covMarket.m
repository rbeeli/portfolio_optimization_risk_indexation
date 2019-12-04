function [sigma,shrinkage]=covMarket(x,shrink)

% function sigma=covmarket(x)
% x (t*n): t iid observations on n random variables
% sigma (n*n): invertible covariance matrix estimator
%
% This estimator is a weighted average of the sample
% covariance matrix and a "prior" or "shrinkage target".
% Here, the prior is given by a one-factor model.
% The factor is equal to the cross-sectional average
% of all the random variables.

% The notation follows Ledoit and Wolf (2003)
% This version: 04/2014

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is released under the BSD 2-clause license.

% Copyright (c) 2014, Olivier Ledoit and Michael Wolf 
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% de-mean returns
t=size(x,1);
n=size(x,2);
meanx=mean(x);
x=x-meanx(ones(t,1),:);
xmkt=mean(x')';

sample=cov([x xmkt])*(t-1)/t;
covmkt=sample(1:n,n+1);
varmkt=sample(n+1,n+1);
sample(:,n+1)=[];
sample(n+1,:)=[];
prior=covmkt*covmkt'./varmkt;
prior(logical(eye(n)))=diag(sample);

if (nargin < 2 | shrink == -1) % compute shrinkage parameters
  c=norm(sample-prior,'fro')^2;
  y=x.^2;
  p=1/t*sum(sum(y'*y))-sum(sum(sample.^2));
  % r is divided into diagonal
  % and off-diagonal terms, and the off-diagonal term
  % is itself divided into smaller terms 
  rdiag=1/t*sum(sum(y.^2))-sum(diag(sample).^2);
  z=x.*xmkt(:,ones(1,n));
  v1=1/t*y'*z-covmkt(:,ones(1,n)).*sample;
  roff1=sum(sum(v1.*covmkt(:,ones(1,n))'))/varmkt...
	  -sum(diag(v1).*covmkt)/varmkt;
  v3=1/t*z'*z-varmkt*sample;
  roff3=sum(sum(v3.*(covmkt*covmkt')))/varmkt^2 ...
	  -sum(diag(v3).*covmkt.^2)/varmkt^2;
  roff=2*roff1-roff3;
  r=rdiag+roff;
  % compute shrinkage constant
  k=(p-r)/c;
  shrinkage=max(0,min(1,k/t))
else % use specified number
  shrinkage = shrink;
end

% compute the estimator
sigma=shrinkage*prior+(1-shrinkage)*sample;




