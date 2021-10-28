% Clear MATLAB workspace
clear all
close all
clc

% -------------------------------------------------------------------------
% Add dependencies (toolboxes)

addpath(genpath('../toolboxes/ooDACE'));
addpath(genpath('../toolboxes/SRGTSToolbox_DIRECT'));
addpath(genpath('../DIRECTalgorithm'));
addpath(genpath('../source'));

% -------------------------------------------------------------------------
% Add problem functions to the path

addpath(genpath('./problems'));


% -------------------------------------------------------------------------
% Output directory in which results will be saved

dir_output = './results/analytic';


% -------------------------------------------------------------------------
% Repetitions of the experiment

repetitions = 20;


% -------------------------------------------------------------------------
% Metamodels to use

metamodels = struct();

metamodels(1).name = 'ordinary-kriging';
metamodels(1).params = {'Metamodel', 'OrdinaryKriging_SRGTSToolbox', 'Verbose', false};


% -------------------------------------------------------------------------
% Way to choose de metamodel sample

rule = struct();

rule(1).name = 'kmeans';
rule(1).choose_sample = {'ChooseSample','kmeans', 'Verbose', false};

rule(2).name = 'lowest';
rule(2).choose_sample = {'ChooseSample','lowest', 'Verbose', false};

rule(3).name = 'nearest';
rule(3).choose_sample = {'ChooseSample','nearest', 'Verbose', false};

rule(4).name = 'k_nearest';
rule(4).choose_sample = {'ChooseSample','k_nearest', 'Verbose', false};

rule(5).name = 'newest';
rule(5).choose_sample = {'ChooseSample','newest', 'Verbose', false};


%--------------------------------------------------------------------------
% Kind of evolution control

evolution_control = struct();
evolution_control.type = {'EvolutionControl', 'exp_imp', 'Verbose', false};


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
% Entries to launch (tuples <problem x metamodel x repetition>)

idx = 1;
for rep = 1:repetitions
    for i = 1:length(metamodels)
        for j = 1:length(problems)
            for k = 1:length(rule)
                filename = sprintf('%s-%s-%s-%02d-%02d.csv', metamodels(i).name, rule(k).name, problems(j).name, problems(j).n, rep);
                if ~exist(filename, 'file')
                    entry = struct();
                    entry.filename = filename;
                    entry.metamodel = metamodels(i);
                    entry.problem = problems(j);
                    entry.rule = rule(k);
                    entry.rep = rep;
                    entry.evolutioncontrol = evolution_control.type;
                    entries(idx) = entry;
                    idx = idx + 1;
                end
            end  
        end
    end
end


% -------------------------------------------------------------------------
% Launch algorithms (in parallel)
nthreads = 8;                % num. of threads to use
c = parcluster();            % cluster
p = parpool(c, nthreads);    % pool
for i = 1:length(entries)
    f(i) = parfeval(p, @launch_SRGT_DIRECT, 0, entries(i).problem, ...
        entries(i).metamodel, entries(i).rule, entries(i).rep, ...
        entries(i).evolutioncontrol, strcat(dir_output, '/all'), ...
        entries(i).filename);
end

% Wait for all parallel jobs to finish
counter = 0;
for i = 1:length(f)
    try
        [idx] = fetchNext(f);
        counter = counter + 1;
        fprintf('(%6.2f%%) Completed: %s (%d vars) using %s metamodel whith %s rule (rep. %d)\n', ...
            100.0 * (counter / length(f)), ...
            entries(idx).problem.name, entries(idx).problem.n, ...
            entries(idx).metamodel.name, entries(idx).rule.name, entries(idx).rep);
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
fid = fopen(strcat(dir_output, '/results.csv'), 'w+');
fprintf(fid, 'METAMODEL,RULE,PROB,NVAR,REP,NEVAL,ITER,BEST.OBJ,MEAN.DIFF,METAMODEL.TIME.S,TOTAL.TIME.S\n');

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
