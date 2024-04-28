function LEA_main(DemoMode)

workingdir = pwd ;
testdir = ls('testf*') ;
if ~isempty(testdir), cd(testdir), end

[testfcn,testdir] = uigetfile('*.m','Load demo function for LEA') ;
if ~testfcn
    cd(workingdir)
    return
elseif isempty(regexp(testfcn,'\.m(?!.)','once'))
    error('Test function must be m-file')
else
    cd(testdir)
end

fitnessfcn = str2func(testfcn(1:regexp(testfcn,'\.m(?!.)')-1)) ;
cd(workingdir)

options = fitnessfcn('init') ;

if any(isfield(options,{'options','Aineq','Aeq','LB'}))
    % Then the test function gave us a (partial) problem structure.
    problem = options ;
else
    % Aineq = [1 1] ; bineq = [1.2] ; % Test case for linear constraint
    problem.options = options ;
    problem.Aineq = [] ; problem.bineq = [] ;
    problem.Aeq = [] ; problem.beq = [] ;
    problem.LB = [] ; problem.UB = [] ;
    problem.nonlcon = [] ;
end

problem.fitnessfcn = fitnessfcn ;
problem.nvars = 2 ;

if ~nargin
    problem.options.DemoMode = 'pretty' ;
else
    problem.options.DemoMode = DemoMode ;
end
problem.options.PlotFcns = {@LEAplotbestf,@LEAplotswarmsurf} ;
% problem.options.VelocityLimit = 0.2 ;
problem.options.HybridFcn = @fmincon ;
% problem.options.Display = 'off' ;

LEA(problem)