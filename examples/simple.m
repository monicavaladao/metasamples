% Clear all data
%clc
%clear all;
%close all;

% Add problem functions to the path
addpath('../experiments/problems');
addpath('../experiments/problems/analytic_functions');
addpath('../experiments/problems/cec2005');

problem = load_problem('ackley', 2);
%problem = load_problem('elipsoid', 2);
%problem = load_problem('griewank', 2);
%problem = load_problem('rosen', 2);
%problem = load_problem('rastrigin', 2);
%problem = load_problem('levy', 2);
%problem = load_problem('perm0db', 2);
%problem = load_problem('zakharov', 2);
%problem = load_problem('dixonpr', 2);
%problem = load_problem('stybtang', 2);

%problem = load_problem('ackley', 5);
%problem = load_problem('elipsoid', 2);
%problem = load_problem('griewank', 2);
%problem = load_problem('rosen', 5);
%problem = load_problem('rastrigin', 5);
%problem = load_problem('levy', 2);
%problem = load_problem('perm0db', 2);
%problem = load_problem('zakharov', 2);
%problem = load_problem('dixonpr', 2);
%problem = load_problem('stybtang', 2);

fobj = problem.fobj;
lb = problem.lb;
ub = problem.ub;
n = problem.n;

% Budget of function evaluation
max_eval = 1000;

% Create initial sample
rng(3, 'twister');
ssize = 80;
X = lhsdesign(ssize, n);
X = repmat(lb, ssize, 1) + repmat(ub - lb, ssize, 1) .* X;
y = feval_all(fobj, X);

evolution_control = 'exp_imp';
%evolution_control = 'metamodel';
 

% Solve the problem
 S = [];yS = [];
 [best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'OrdinaryKriging_ooDACE','EvolutionControl',evolution_control,'ChooseSample','kmeans');
 S = [S;best_x];
 yS = [yS;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'OrdinaryKriging_ooDACE','EvolutionControl',evolution_control,'ChooseSample','lowest');
S = [S;best_x];
yS = [yS;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'OrdinaryKriging_ooDACE','EvolutionControl',evolution_control,'ChooseSample','nearest');
S = [S;best_x];
yS = [yS;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'OrdinaryKriging_ooDACE','EvolutionControl',evolution_control,'ChooseSample','newest');
S = [S;best_x];
yS = [yS;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'OrdinaryKriging_ooDACE','EvolutionControl',evolution_control,'ChooseSample','k_nearest');
S = [S;best_x];
yS = [yS;best_y];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Solve the problem
R = [];yR = [];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'RBF_SRGTSToolbox','ChooseSample','kmeans');
R = [R;best_x];
yR = [yR;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'RBF_SRGTSToolbox','ChooseSample','lowest');
R = [R;best_x];
yR = [yR;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'RBF_SRGTSToolbox','ChooseSample','nearest');
R = [R;best_x];
yR = [yR;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'RBF_SRGTSToolbox','ChooseSample','newest');
R = [R;best_x];
yR = [yR;best_y];
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, max_eval, 'Metamodel', 'RBF_SRGTSToolbox','ChooseSample','k_nearest');
R = [R;best_x];
yR = [yR;best_y];
[S,R]
[yS;yR]

% % Print results
% fprintf('\n\n')
% fprintf('Best solution:\n');
% fprintf('y = %.5f\n', best_y);
% fprintf('x = ');
% fprintf('%.5f ', best_x);
% fprintf('\n');
% fprintf('\n');
% fprintf('Additional Information\n');
% printstruct(info);
