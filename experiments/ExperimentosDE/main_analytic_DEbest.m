% Clear MATLAB workspace
clear all
close all
clc

% -------------------------------------------------------------------------
% Add problem functions to the path

addpath(genpath('./problems'));
addpath(genpath('./DEBestNormalizado'));


% -------------------------------------------------------------------------
% Output directory in which results will be saved

dir_output = './results/analytic_DEBest';

% -------------------------------------------------------------------------
% Algorithm
alg = 'DEbest';


% -------------------------------------------------------------------------
% Repetitions of the experiment

repetitions = 20;

% -------------------------------------------------------------------------
% Problems to solve

nvars = [2, 5, 10, 15, 20];
npop = [20 20 20 50 50];
neval = [1000 2000 3000 5000 5000];

problem_names = {'ackley', 'elipsoid', 'griewank', 'rosen', 'rastrigin', ...
    'levy', 'perm0db', 'zakharov', 'dixonpr', 'stybtang'};

idx = 1;
problems = struct();
for i = 1:length(problem_names)
    for j = 1:length(nvars)
        aux = load_analytic_problem(problem_names{i}, nvars(j));
        problems(idx).name = problem_names{i};
        problems(idx).n = aux.n;
        problems(idx).lb = aux.lb;
        problems(idx).ub = aux.ub;
        problems(idx).fobj = aux.fobj;
        problems(idx).npop = npop(j);
        problems(idx).neval = neval(j);
        idx = idx + 1;
    end
end



% -------------------------------------------------------------------------
% Entries (tuples <problem x metamodel x repetition>)

idx = 1;
for rep = 1:repetitions
    for j = 1:length(problems)
        filename = sprintf('%s-%02d-%02d.csv', problems(j).name, problems(j).n, rep);
        if ~exist(filename, 'file')
            entry = struct();
            entry.filename = filename;
            entry.problem = problems(j);
            entry.rep = rep;
            entries(idx) = entry;
            idx = idx + 1;
        end
    end
end

% -------------------------------------------------------------------------
% Launch algorithms (in parallel)
nthreads = 8;               % num. of threads to use
c = parcluster();            % cluster
p = parpool(c, nthreads);    % pool
for i = 1:length(entries)
    f(i) = parfeval(p, @launch_DEbest, 0, entries(i).problem, alg, ...
        entries(i).rep, strcat(dir_output, '/all'), entries(i).filename);
end

% Wait for all parallel jobs to finish
counter = 0;
for i = 1:length(f)
    try
        [idx] = fetchNext(f);
        counter = counter + 1;
        fprintf('(%6.2f%%) Completed: %s (%d vars) using %s metamodel (rep. %d)\n', ...
            100.0 * (counter / length(f)), ...
            entries(idx).problem.name, entries(idx).problem.n, ...
            alg, entries(idx).rep);
    catch ex
        warning(ex.message);
    end
end

% Release parallel resources
delete(p);

% -------------------------------------------------------------------------
% Get all CSV files into a single one
fprintf('Joining CSV files into a single file...\n');

% List of files with individual results
files = dir(strcat(dir_output, '/all/*.csv'));

% Write file with all results
fid = fopen(strcat(dir_output, '/resultsDE.csv'), 'w+');
fprintf(fid, 'METAMODEL,PROB,NVAR,REP,NEVAL,ITER,BEST.OBJ,TOTAL.TIME.S\n');

for i = 1:size(files, 1)
    filename = fullfile(files(i).folder, files(i).name);
    if exist(filename, 'file')
        cfid = fopen(filename, 'r');
        cline = fgetl(cfid); % ignore CSV header
        cline = fgetl(cfid); % first line after header
        while ischar(cline) && ~isempty(cline)
            fprintf(fid, cline); % write line
            fprintf(fid, '\n');
            cline = fgetl(cfid); % read next line
        end
        fclose(cfid);
    end
end

fclose(fid);


