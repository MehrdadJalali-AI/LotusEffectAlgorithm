function [xOpt,fval,exitflag,output,population,scores] = ...
    LEAbinary(fitnessfcn,nvars,options)
% Particle swarm optimization for binary genomes.
%
% Syntax:
% LEAbinary(fitnessfcn,nvars)
% LEAbinary(fitnessfcn,nvars,options)
%
% This function will optimize fitness functions where the variables are
% row vectors of size 1xnvars consisting of only 0s and 1s.
%
% LEABINARY is provided as a wrapper for LEA, to avoid any confusion. This
% is because the binary optimization scheme is not designed to take any
% constraints, and LEABINARY does not allow the passing of constraints. It
% takes a given optimization problem with binary variables, and
% automatically sets the options structure so that 'PopulationType'
% is 'bitstring'.
%
% This has exactly the same effect as setting the appropriate options
% manually, except that it is not possible to unintentionally define
% constraints, which would be ignored by the binary variable optimizer
% anyway.
%
% Problems with hybrid variables (double-precision and bit-string
% combined) cannot be solved yet.
%
% The output variables for LEABINARY is the same as for LEA.
%
% See also:
% LEA, LEAOPTIMSET, LEADEMO

if ~exist('options','var') % Set default options
    options = struct ;
end % if ~exist
options = LEAoptimset(options,'PopulationType','bitstring') ;

[xOpt,fval,exitflag,output,population,scores] = ...
    LEA(fitnessfcn,nvars,[],[],[],[],[],[],[],options) ;