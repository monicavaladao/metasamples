function [] = launch(problem, metamodel, rule, seed, evolutioncontrol, dir_output, filename)

% Get problem data
n = problem.n;
lb = problem.lb;
ub = problem.ub;
fobj = problem.fobj;
npop = problem.npop;
neval = problem.neval;

% Create initial sample
rng(seed, 'twister');
ssize = 4 * npop;
X = lhsdesign(ssize, n);
X = repmat(lb, ssize, 1) + repmat(ub - lb, ssize, 1) .* X;
y = feval_all(fobj, X);

% Solve the problem
[best_x, best_y, info] = surrogate_saea(fobj, X, y, lb, ub, neval, metamodel.params{:}, rule.choose_sample{:}, evolutioncontrol{:});

% Save results in a CSV file
if ~exist(dir_output, 'dir')
    mkdir(dir_output);
end

fid = fopen(strcat(dir_output, '/', filename), 'w+');
fprintf(fid, 'METAMODEL,RULE,PROB,NVAR,REP,NEVAL,ITER,BEST.OBJ,MEAN.DIFF,METAMODEL.TIME.S,TOTAL.TIME.S\n');

history = info.history;
for i = 1:length(history.iterations)
    fprintf(fid, '"%s","%s","%s",%d,%d,%d,%d,%.6f,%.6f,%.6f,%.6f\n', ...
        metamodel.name, rule.name, problem.name, n, seed, history.neval(i), ...
        history.iterations(i), history.best_y(i), history.mean_diff(i), ...
        history.metamodel_runtime(i), history.saea_runtime(i));
end

fclose(fid);

% Save history in a MAT file
filename_mat = strrep(filename, '.csv', '.mat');
save(strcat(dir_output, '/', filename_mat), 'history');

end
