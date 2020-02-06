%==========================================================================
%           ECONOMETRICS IV - SPRING 2020 - Prof. Schorfehide 
%                       REDUCED-FORM VARs                     
%
%
% Author: Juan Castellanos Silvan (from Luigi Boccola's original code)
% Date  : 02/04/2020
%==========================================================================

% Exercises 4 & 5: Means and 90% credible sets 

%=========================================================================
%                             HOUSEKEEPING
%=========================================================================

tic
close all
clear all
clc

%=========================================================================
%         GENERATE DUMMY OBSERVATIONS FROM MINNESOTA PRIOR 
%=========================================================================
mprior = 2;     % see results in hyperparam.m
vm_dummy

%=========================================================================
%     DEFINITION OF DATA, LAG STRUCTURE AND POSTERIOR SIMULATION
%=========================================================================

[Tdummy,n] = size(YYdum);
[Tobs,n]   = size(YYact);
X          = [XXact; XXdum];
Y          = [YYact; YYdum];
n          = n;                 % Number of variables in the VAR
p          = 4;                 % Number of lags in the VAR
T          = Tobs+Tdummy;
nsim       = 10000;             % Number of draws from Posterior Density
nburn      = 0.2*nsim;          % Number of draws to discart
F          = zeros(n*p,n*p);    % Matrix for Companion Form
I          = eye(n);

for i=1:p-1
    F(i*n+1:(i+1)*n,(i-1)*n+1:i*n) = I;
end


%=========================================================================
%               OLS ESTIMATOR FOR PHI AND SSR (SIGMA)
%=========================================================================

Phi_tilde = inv(X'*X)*X'*Y;
Sigma     = (Y-X*Phi_tilde)'*(Y-X*Phi_tilde);

% Matrices for collecting draws from Posterior Density

Sigmap    = zeros(nsim,n,n);
Phip      = zeros(nsim,n*p+1,n);
largeeig  = zeros(nsim,1);
counter   = 0;

%=========================================================================
%            DRAWS FROM POSTERIOR DENSITY (DIRECT SAMPLING)
%=========================================================================
disp('                                                                  ');
disp('        BAYESIAN ESTIMATION OF VAR: DIRECT SAMPLING...            ');
disp('                                                                  ');

for j=1:nsim

    
    % Draws from the density Sigma | Y
    
    sigma   = iwishrnd(Sigma,T-n*p-1);
    
    % Draws from the density vec(Phi) |Sigma(j), Y
    
    phi_new = mvnrnd(reshape(Phi_tilde,n*(n*p+1),1),kron(sigma,inv(X'*X)));
    
    % Rearrange vec(Phi) into Phi
    
    Phi     = reshape(phi_new,n*p+1,n);
        
    Sigmap(j,:,:) = sigma;
    Phip(j,:,:)   = Phi;
    
    Phi = Phi(1:n*p,:);

    
    % Calculating largest eigenvalue of Companion form
    
     F(1:n,1:n*p)    = Phi';

     eigen           = eig(F);
     eigen           = max(eigen);
     largeeig(j)     = abs(eigen);
     counter         = counter+1; 
     
     if counter==2000
        disp(['         DRAW NUMBER:   ', num2str(j)]);
        disp('                                                          ');
        disp(['     REMAINING DRAWS:   ', num2str(nsim-j)]);
        disp('                                                          ');

        counter = 0;
     
     end
     
end


%=========================================================================
%                        MARGINAL DATA DENSITY
%=========================================================================

vm_mdd

mdd = lnpYY;               % Marginal Data Density


%=========================================================================
%                        MEANS AND CREDIBLE SETS
%=========================================================================

% -----------------------
% Intercept coefficients
% -----------------------
Phi_c_bar = mean(Phip(:,end,:),1);
Phi_c_bar = reshape(Phi_c_bar, 4,1,1);

lb_c = prctile(Phip(:,end,:),5);
lb_c = reshape(lb_c, 4,1,1);

ub_c = prctile(Phip(:,end,:),95);
ub_c = reshape(ub_c,4,1,1);

% -------------------
% Largest eigenvalue
% -------------------
mean_eig = mean(largeeig);
lb_eig = prctile(largeeig, 5);
ub_eig = prctile(largeeig, 95);

% Recursive averaging
rmean = zeros(nsim,1);
r5per = zeros(nsim,1);
r95per = zeros(nsim,1);
for i=1:nsim
    rmean(i) = mean(largeeig(1:i));
    r5per(i) = prctile(largeeig(1:i),5);
    r95per(i) = prctile(largeeig(1:i),95);
end

% Density
[density,x]  = ksdensity(largeeig(nburn:end)); % density


disp(['         ELAPSED TIME:   ', num2str(toc)]);

elapsedtime=toc;
