function options = LEAoptimset(varargin)
% Creates an options structure for LEA.
%
% Syntax:
% LEAoptimset
% options = LEAoptimset
% options = LEAoptimset(@LEA)
% options = LEAoptimset(@LEAmultiobj)
% options = LEAoptimset('param1',value1,'param2',value2,...)
% options = LEAoptimset(oldopts,'param1',value1,...)
% options = LEAoptimset(oldopts,newopts)
%
% Description:
% LEAoptimset with no input or output arguments displays a complete list of
% parameters with their valid values.
% 
% options = LEAoptimset (with no input arguments) creates a structure
% called options that contains the options, or parameters, for the LEA
% algorithm and sets parameters to [], indicating default values will be
% used.
% 
% options = LEAoptimset(@LEA) creates a structure called options that
% contains the default options for the genetic algorithm.
% 
% options = LEAoptimset(@LEAmultiobj) creates a structure called options
% that contains the default options for LEAmultiobj. Not yet implemented
% 
% options = LEAoptimset('param1',value1,'param2',value2,...) creates a
% structure options and sets the value of 'param1' to value1, 'param2' to
% value2, and so on. Any unspecified parameters are set to their default
% values. Case is ignored for parameter names.
% 
% options = LEAoptimset(oldopts,'param1',value1,...) creates a copy of
% oldopts, modifying the specified parameters with the specified values.
% 
% options = LEAoptimset(oldopts,newopts) combines an existing options
% structure, oldopts, with a new options structure, newopts. Any parameters
% in newopts with nonempty values overwrite the corresponding old
% parameters in oldopts.
%
% Again, type >> LEAoptimset with no input arguments to display a list of
% options which may be set.
%
% NOTE regarding the ConstrBoundary option:
% A 'soft' boundary allows particles to leave problem bounds, but sets
% their fitness scores to Inf if they do. Other acceptable options are
% 'reflect' and 'absorb', which prevents them from travelling outside the
% problem bounds at all.
%
% See also:
% LEA, LEAdemo

% Default options
options.CognitiveAttraction = 0.5 ;
options.ConstrBoundary = 'soft' ; 
options.DemoMode = 'off' ;
options.Display = 'final' ;
options.FitnessLimit = -inf ;
options.Generations = 200 ;
options.HybridFcn = [] ;
options.InitialPopulation = [] ;
options.InitialVelocities = [] ;
options.KnownMin = [] ;
options.OutputFcns = [] ;
options.PlotFcns = {} ;
options.PlotInterval = 1 ;
options.PopInitRange = [0;1] ;
options.PopulationSize = 40 ;
options.PopulationType = 'doubleVector' ;
options.SocialAttraction = 1.5 ;
options.StallGenLimit = 50 ;
options.TolCon = 1e-6 ;
options.TolFun = 1e-6 ;
options.Vectorized = 'off' ;
options.VelocityLimit = [] ;

if ~nargin && ~nargout
    fprintf('\n')
    fprintf('CognitiveAttraction: [Positive scalar | {%g}]\n',...
        options.CognitiveAttraction) ;
    fprintf('     ConstrBoundary: [soft | reflect | absorb | {''%s''}]\n',...
        options.ConstrBoundary) ;
    fprintf('            Display: [''off'' | ''final'' | {''%s''}]\n',...
        options.Display) ;
    fprintf('           DemoMode: [''fast'' | ''pretty'' | ''on'' | ''off'' | {''%s''}]\n',...
        options.DemoMode) ;
    fprintf('       FitnessLimit: [Scalar | {%g}]\n',...
        options.FitnessLimit) ;
    fprintf('        Generations: [Positive integer | {%g}]\n',...
        options.Generations) ;
    msg = sprintf('          HybridFcn: [@fminsearch | @patternsearch |');
    fprintf('%s @fminunc | @fmincon | {[]}]\n',msg)
    fprintf('  InitialPopulation: [nxnvars matrix | {[]}]\n')
    fprintf('  InitialVelocities: [nxnvars matrix | {[]}]\n')
    % PlotFcns, a bit tricky to turn into a string:
    % ---------------------------------------------------------------------
    if ~isempty(options.PlotFcns)
        msg = '{' ;
        for i = 1:length(options.PlotFcns)
            msg = sprintf('%s@%s, ',msg,func2str(options.PlotFcns{i})) ;
        end % for i
        msg = sprintf('%s\b\b}',msg) ;
    else
        msg = '{}' ;
    end
    fprintf('           PlotFcns: [Cell array of fcn handles | {%s}]\n',...
        msg) ;
    % ---------------------------------------------------------------------
    fprintf('       PlotInterval: [Positive integer | {%g}]\n',...
        options.PlotInterval) ;
    fprintf('       PopInitRange: [2x1 vector | 2xnvars matrix | {%s}]\n',...
        mat2str(options.PopInitRange)) ;
    fprintf('     PopulationSize: [Positive integer | {%g}]\n',...
        options.PopulationSize) ;
    fprintf('     PopulationType: [''bitstring'' | ''doubleVector'' | {''%s''}]\n',...
        options.PopulationType) ;
    fprintf('   SocialAttraction: [Positive scalar | {%g}]\n',...
        options.SocialAttraction) ;
    fprintf('      StallGenLimit: [Positive integer | {%g} ]\n',...
        options.StallGenLimit) ;
    fprintf('             TolFun: [Positive scalar | {%g}]\n',...
        options.TolFun) ;
    fprintf('             TolCon: [Positive scalar | {%g}]\n',...
        options.TolCon) ;
    fprintf('         Vectorized: [''on'' | ''off'' | {''%s''}]\n',...
        options.Vectorized) ;
    fprintf('      VelocityLimit: [Positive scalar | {[]}]\n');
    fprintf('\n')
    clear options
    return
end

if ~nargin || isequal(varargin{1},@LEA)
    return
elseif isstruct(varargin{1})
    oldoptions = varargin{1} ;
    fieldsprovided = fieldnames(oldoptions) ;
    if nargin == 2 && isstruct(varargin{2})
        newoptions = varargin{2} ;
        newfields = fieldnames(newoptions) ;
    end
end

requiredfields = fieldnames(options) ;

% Find any input arguments that match valid field names. If they exist,
% replace the default values with them.
for i = 1:size(requiredfields,1)
    idx = find(cellfun(@(varargin)strcmpi(varargin,requiredfields{i,1}),...
        varargin)) ;
    if ~isempty(idx)
        options.(requiredfields{i,1}) = varargin(idx(end) + 1) ;
        options.(requiredfields{i,1}) = options.(requiredfields{i,1}){:} ;
    elseif exist('fieldsprovided','var')
        fieldidx = find(cellfun(@(fieldsprovided)strcmp(fieldsprovided,...
            requiredfields{i,1}),...
            fieldsprovided)) ;
        if ~isempty(fieldidx)
            options.(requiredfields{i,1}) = ...
                oldoptions.(fieldsprovided{fieldidx}) ;
        end
        if exist('newfields','var')
            newfieldidx = find(cellfun(@(newfields)strcmp(newfields,...
                requiredfields{i,1}),...
                newfields)) ;
            if ~isempty(newfieldidx)
                options.(requiredfields{i,1}) = ...
                    newoptions.(newfields{newfieldidx}) ;
            end
        end
    end % if ~isempty
end % for i

% Some robustness
if isequal(size(options.PopInitRange),[1 2])
    options.PopInitRange = options.PopInitRange' ;
end