function [xOpt,fval,exitflag,output,population,scores] = ...
    LEA(fitnessfcn,nvars,Aineq,bineq,Aeq,beq,LB,UB,nonlcon,options)


if ~nargin % Rosenbrock's banana function by default, as a demonstration
    fitnessfcn = @(x)-exp(-0.2.*sqrt((x(1)).^2+(x(2)).^2)+1.5.*(cos(2*x(1))+sin(2*x(2))));

 
    nvars = 2 ;
    LB = [-5,-5] ;
    UB = [5,5] ;
    options.PopInitRange = [[-2;4],[-1;2]] ;
    options.PlotFcns = {@LEAplotbestf,@LEAplotswarmsurf} ;
    options.Generations = 200 ;
    options.DemoMode = 'on' ;
    options.KnownMin = [1 1] ;
elseif isstruct(fitnessfcn)
    nvars = fitnessfcn.nvars ;
    Aineq = fitnessfcn.Aineq ;
    bineq = fitnessfcn.bineq ;
    Aeq = fitnessfcn.Aeq ;
    beq = fitnessfcn.beq ;
    LB = fitnessfcn.LB ;
    UB = fitnessfcn.UB ;
    nonlcon = fitnessfcn.nonlcon ;
    if ischar(nonlcon) && ~isempty(nonlcon)
        nonlcon = str2func(nonlcon) ;
    end
    options = fitnessfcn.options ;
    fitnessfcn = fitnessfcn.fitnessfcn ;
elseif nargin < 2
    msg = 'LEA requires at least two input arguments' ;
    error('%s, or a problem structure. Type >> help LEA for details',...
        msg)
end % if ~nargin

if ~exist('options','var') % Set default options
    options = struct ;
end % if ~exist

options = LEAoptimset(options) ;

options.Verbosity = 1 ; % For options.Display == 'final' (default)
if strncmpi(options.Display,'off',3)
    options.Verbosity = 0 ;
elseif strncmpi(options.Display,'iter',4)
    options.Verbosity = 2 ;
elseif strncmpi(options.Display,'diag',4)
    options.Verbosity = 3 ;
end

if ~exist('Aineq','var'), Aineq = [] ; end
if ~exist('bineq','var'), bineq = [] ; end
if ~exist('Aeq','var'), Aeq = [] ; end
if ~exist('beq','var'), beq = [] ; end
if ~exist('LB','var'), LB = [] ; end
if ~exist('UB','var'), UB = [] ; end
if ~exist('nonlcon','var'), nonlcon = [] ; end
% Check for constraints and bit string population type
if strncmpi(options.PopulationType,'bitstring',2)
    if ~isempty([Aineq,bineq]) || ~isempty([Aeq,beq]) || ...
            ~isempty(nonlcon) || ~isempty([LB,UB])
        Aineq = [] ; bineq = [] ; Aeq = [] ; beq = [] ; nonlcon = [] ;
        LB = [] ; UB = [] ;
        msg = sprintf('Warning: Constraints will be ignored') ;
        msg = sprintf('%s for options.PopulationType ''bitstring''',msg) ;
        disp(msg)
    end
end
% Change this when nonlcon gets fully implemented:
if ~isempty(nonlcon) && strcmpi(options.ConstrBoundary,'reflect')
    msg = 'Non-linear constraints don''t have ''reflect'' boundaries' ;
    warning('LEA:main:nonlcon',...
        '%s implemented. Changing options.ConstrBoundary to ''soft''.',...
        msg)
    options.ConstrBoundary = 'soft' ;
end

% Is options.PopInitRange reconcilable with LB and UB constraints?
% -------------------------------------------------------------------------
% Resize PopInitRange in case it was given as one range for all dimensions
if size(options.PopInitRange,2) == 1 && nvars > 1
    options.PopInitRange = repmat(options.PopInitRange,1,nvars) ;
end

% Check initial population with respect to bound constraints
% Is this really desirable? Maybe there are some situations where the user
% specifically does not want an uniform inital population covering all of
% LB and UB?
if ~isempty(LB) || ~isempty(UB)
    options.LinearConstr.type = 'boundconstraints' ;
    options.PopInitRange = ...
        LEAcheckpopulationinitrange(options.PopInitRange,LB,UB) ;
end
% -------------------------------------------------------------------------

% Check validity of VelocityLimit
if all(~isfinite(options.VelocityLimit))
    options.VelocityLimit = [] ;
elseif isscalar(options.VelocityLimit)
    options.VelocityLimit = repmat(options.VelocityLimit,1,nvars) ;
elseif ~isempty(length(options.VelocityLimit)) && ...
        ~isequal(length(options.VelocityLimit),nvars)
    msg = 'options.VelocityLimit must be either a positive scalar' ;
    error('%s, or a vector of size 1xnvars.',msg)
end % if isscalar
options.VelocityLimit = abs(options.VelocityLimit) ;

% Generate swarm initial state (this line must not be moved)
if strncmpi(options.PopulationType,'double',2)
    state = LEAcreationuniform(options,nvars) ;
elseif strncmpi(options.PopulationType,'bi',2)
    state = LEAcreationbinary(options,nvars) ;
end

% Check initial population with respect to linear and nonlinear constraints
% -------------------------------------------------------------------------
if ~isempty(Aeq) || ~isempty(Aineq) || ~isempty(nonlcon)
    options.LinearConstr.type = 'linearconstraints' ;
    if ~isempty(nonlcon)
        options.LinearConstr.type = 'nonlinearconstraints' ;
    end
    if strcmpi(options.ConstrBoundary,'reflect')
        options.ConstrBoundary = 'soft' ;
        msg = sprintf('Constraint boundary behavior ''reflect''') ;
        msg = sprintf('%s is not yet supported for linear constraints.',...
            msg) ;
        msg = sprintf('%s Switching boundary behavior to ''soft''.',msg) ;
        warning('LEA:mainfcn:constraintbounds',...
            '%s',msg)
    end
    [state,options] = LEAcheckinitialpopulation(state,...
        Aineq,bineq,Aeq,beq,...
        LB,UB,...
        nonlcon,...
        options) ;
end
% -------------------------------------------------------------------------

n = options.PopulationSize ;
itr = options.Generations ;

if ~isempty(options.PlotFcns)
    close(findobj('Tag','Swarm Plots','Type','figure'))
    state.hfigure = figure('NumberTitle','off',...
        'Name','LEA Progress',...
        'Tag','Swarm Plots') ;
end % if ~isempty

if options.Verbosity > 0, fprintf('\nSwarming...'), end
exitflag = 0 ; % Default exitflag, for max iterations reached.
flag = 'init' ;

% Iterate swarm
state.fitnessfcn = fitnessfcn ;
state.LastImprovement = 1 ;
state.ParticleInertia = 0.9 ; % Initial inertia
% alpha = 0 ;
for k = 1:itr
    state.Score = inf*ones(n,1) ; % Reset fitness vector
    state.Generation = k ;
    state.OutOfBounds = false(options.PopulationSize,1) ;
    
    % Check bounds before proceeding
    % ---------------------------------------------------------------------
    if ~all([isempty([Aineq,bineq]), isempty([Aeq,beq]), ...
            isempty([LB;UB]), isempty(nonlcon)])
        state = LEAcheckbounds(options,state,Aineq,bineq,Aeq,beq,...
            LB,UB,nonlcon) ;
    end % if ~isempty
    % ---------------------------------------------------------------------
    
    % Evaluate fitness, update the local bests
    % ---------------------------------------------------------------------
    if strcmpi(options.Vectorized,'off')
        for i = setdiff(1:n,find(state.OutOfBounds))
            state.Score(i) = fitnessfcn(state.Population(i,:)) ;
        end % for i
    else % Vectorized fitness function
        state.Score(setdiff(1:n,find(state.OutOfBounds))) = ...
            fitnessfcn(state.Population(setdiff(1:n,...
            find(state.OutOfBounds)),:)) ;
    end % if strcmpi
    
    betterindex = state.Score < state.fLocalBests ;
    state.fLocalBests(betterindex) = state.Score(betterindex) ;
    state.xLocalBests(betterindex,:) = ...
        state.Population(betterindex,:) ;
    % ---------------------------------------------------------------------
    
    % Update the global best and its fitness, then check for termination
    % ---------------------------------------------------------------------
    [minfitness, minfitnessindex] = min(state.Score) ;
    
%     alpha = alpha + (1/k) * ...
%         ((1/n)*sum((state.Velocities*state.Velocities')^2) ./ ...
%         ((1/n)*sum(state.Velocities*state.Velocities')).^2) ;
%     tempchk = alpha <= 1.6 ;
    if minfitness < state.fGlobalBest
        state.fGlobalBest(k) = minfitness ;
        state.xGlobalBest = state.Population(minfitnessindex,:) ;
        state.LastImprovement = k ;
        imprvchk = k > options.StallGenLimit && ...
            (state.fGlobalBest(k - options.StallGenLimit) - ...
                state.fGlobalBest(k)) / (k - options.StallGenLimit) < ...
                options.TolFun ;
        if imprvchk
            exitflag = 1 ;
            flag = 'done' ;
        elseif state.fGlobalBest(k) < options.FitnessLimit
            exitflag = 2 ;
            flag = 'done' ;
        end % if k
    else % No improvement from last iteration
        state.fGlobalBest(k) = state.fGlobalBest(k-1) ;
    end % if minfitness
    
    stallchk = k - state.LastImprovement >= options.StallGenLimit ;
    if stallchk
        % No improvement for StallGenLimit generations
        exitflag = 3 ;
        flag = 'done' ;
    end
    % ---------------------------------------------------------------------
    
    % Update flags, state and plots before updating positions
    % ---------------------------------------------------------------------
    if k == 2
        flag = 'iter' ;
    elseif k == itr
        flag = 'done' ;
        exitflag = 0 ;
    end
    
    if ~isempty(options.PlotFcns) && ~mod(k,options.PlotInterval)
        % Exit gracefully if user has closed the figure
        if isempty(findobj('Tag','Swarm Plots','Type','figure'))
            exitflag = -1 ;
            break
        end % if isempty
        % Find a good size for subplot array
        rows = floor(sqrt(length(options.PlotFcns))) ;
        cols = ceil(length(options.PlotFcns) / rows) ;
        % Cycle through plotting functions
        if strcmpi(flag,'init')
            haxes = zeros(length(options.PlotFcns),1) ;
        end % if strcmpi
        for i = 1:length(options.PlotFcns)
            if strcmpi(flag,'init')
                haxes(i) = subplot(rows,cols,i,...
                    'Parent',state.hfigure) ;
                set(gca,'NextPlot','replacechildren')
            else
                subplot(haxes(i))
            end % if strcmpi
            state = options.PlotFcns{i}(options,state,flag) ;
        end % for i
        drawnow
    end % if ~isempty
    
    if ~isempty(options.OutputFcns) && ~mod(k,options.PlotInterval)
        for i = 1:length(options.Output)
            state = options.OutputFcns{i}(options,state,flag) ;
        end % for i
    end % if ~isempty
    
    if strcmpi(flag,'done')
        break
    end % if strcmpi
    % ---------------------------------------------------------------------
    
    % Update the particle velocities and positions
    state = LEAiterate(state,options) ;
end % for k

% Assign output variables and generate output
% -------------------------------------------------------------------------
xOpt = state.xGlobalBest ;
fval = state.fGlobalBest(k) ; % Best fitness value
% Final population: (hopefully very close to each other)
population = state.Population ;
scores = state.Score ; % Final scores (NOT local bests)
output.generations = k ; % Number of iterations performed
clear state

output.message = LEAgenerateoutputmessage(options,output,exitflag) ;
if options.Verbosity > 0, fprintf('\n\n%s\n',output.message) ; end
% -------------------------------------------------------------------------

% Check for hybrid function, run if necessary
% -------------------------------------------------------------------------
if ~isempty(options.HybridFcn) && exitflag ~= -1
    [xOpt,fval] = LEArunhybridfcn(fitnessfcn,xOpt,Aineq,bineq,...
        Aeq,beq,LB,UB,nonlcon,options) ;
end
% -------------------------------------------------------------------------

% Wrap up
% -------------------------------------------------------------------------
if options.Verbosity > 0
    if exitflag == -1
        fprintf('\nBest point found: %s\n\n',mat2str(xOpt,5))
    else
        fprintf('\nFinal best point: %s\n\n',mat2str(xOpt,5))
    end
end % if options.Verbosity

if ~nargout, clear all, end
% -------------------------------------------------------------------------