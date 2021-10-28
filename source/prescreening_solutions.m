function [chosen_X, others_X, chosen_pred, index_SSM, info] = prescreening_solutions(pop_X, P, N, n, lb, ub, params, info)
% PRESCREENING_SOLUTIONS: Select solutions to evaluate on 
% original function.
%
% Input: 
%   pop_X: Current populaton of EA
%   P: A structure with the offspring solutions for each solution
%   in the population.
%   pool: Pool of solutions
%   N: Size of pop_X
%   n: Number of variables
%   lb: Lower bounds
%   ub: Upper bounds
%   params:  A structure with fields that keep parameters used by the SAEA
%       (including toolboxes ooDACE and SRGTSToolbox)
%   info: A structure used to keep the progress of the SAEA algorithm
% 
% Output:
%   chosen_X: N solutions selected from structure P
%   others_X: Structure with the remaining solutions
%   chose_pred: Evaluate on fpred of each row in chosen_X
%   info: A structure used to keep the progress of the SAEA algorithm   

% Identify some parameters
type = params.metamodel;            % Type of metamodel
sample_size = params.sample_size;   % Metamodel sample size.
std_tol = params.tol_std;           % Threshold value of the variance

% Identify the rule to choose sample
rule_choose_sample = params.choose_sample.rule;

% Identify the pool of solutions
pool = info.pool;

% Used only for 'k_nearest'
index_SSM = [];

% Choose the sample, build the metamodel and choose N solutions from P (one solution per subpopulation)
switch rule_choose_sample
    case 'kmeans'
        % Select a sample to build/update the metamodel
        [sample_X, sample_y] = choose_kmeans(pop_X, pool, sample_size, std_tol);
        
         % Build the metamodel and choose N solutions from P (one solution per subpopulation)
        [chosen_X, others_X, chosen_pred, info] = using_one_metamodel(P, sample_X, sample_y, N, n, lb, ub, type, params, info);
    case 'lowest'
        % Select a sample to build/update the metamodel
        [sample_X, sample_y] = choose_lowest(pool, sample_size, std_tol);
        
         % Build the metamodel and choose N solutions from P (one solution per subpopulation)
        [chosen_X, others_X, chosen_pred, info] = using_one_metamodel(P, sample_X, sample_y, N, n, lb, ub, type, params, info);
    case 'nearest'
        % Number of nearest solutions
        n_nearest = params.choose_sample.nearest_points;

        % Select a sample to build/update the metamodel
        [sample_X, sample_y] = choose_nearest(pop_X, pool, n_nearest, sample_size, std_tol);
        
        % Build the metamodel and choose N solutions from P (one solution per subpopulation)
        [chosen_X, others_X, chosen_pred, info] = using_one_metamodel(P, sample_X, sample_y, N, n, lb, ub, type, params, info);
    case 'newest'
        % Select a sample to build/update the metamodel
        [sample_X, sample_y] = choose_newest(pool, sample_size, std_tol);
        
        % Build the metamodel and choose N solutions from P (one solution per subpopulation)
        [chosen_X, others_X, chosen_pred, info] = using_one_metamodel(P, sample_X, sample_y, N, n, lb, ub, type, params, info);
        
    case 'k_nearest'
        % Number of nearest solutions
        k_nearest = params.choose_sample.nearest_points;
        
        % Build the metamodel and choose N solutions from P (one solution per subpopulation)
        [chosen_X, others_X, chosen_pred, index_SSM, info] = using_several_metamodels(P, pool, N, n, lb, ub, std_tol, k_nearest, type, params, info);

end


end

% -------------------------------------------------------------------------
% Auxiliar functions
% -------------------------------------------------------------------------
%
function [X,y] = choose_kmeans(pop_X, pool, sample_size, std_tol)
% CHOOSE_KMEANS: Choose a sample to create/update the metamodel.
% This function chooses the solutions with the lowest distances of centroid
% of current population to compose the sample.
%
% Input: 
%   pop_X: Current population of EA
%   pool: Pool of solutions
%   sample_size: Metamodel sample size
%   std_tol: Threshold value of the variance
% 
% Output:
%   X: The sample selected to build the metamodel (rows are entries 
%       and coluns are the variables).
%   y: Evaluate of each row in X.
% 

% Calculate the centroid
c = mean(pop_X,1);

% Calculate distances of centroid
[~,~,~,D] = kmeans(pool.X,1,'start',c);
[~,idb] = sort(D,'ascend');
auxpool_X = pool.X(idb,:);
auxpool_y = pool.y(idb);

% Select the sample_size points with the lowest distance
X = pool.X(idb(1:sample_size),:);
y = pool.y(idb(1:sample_size));
 
% Number of solutions in the pool
pool_size = size(auxpool_X,1);

% If standart deviation of X or y is zero, then the metamodel sample must be redefined.
while (any(std(X) < std_tol) || any(isnan(std(X))) || std(y) < std_tol || isnan(std(y))) && sample_size < pool_size
    sample_size = sample_size + 1;
    X = auxpool_X(1:sample_size,:);
    y = auxpool_y(1:sample_size);
end

end
%
function [X,y] = choose_lowest(pool, sample_size, std_tol)
% CHOOSE_LOWEST: Choose a sample to create/update the metamodel.
% This function chooses the solutions with the lowest functions values into
% the pool to compose the sample.
%
% Input: 
%   pool: Pool of solutions
%   sample_size: Metamodel sample size
%   std_tol: Threshold value of the variance
% 
% Output:
%   X: The sample selected to build the metamodel (rows are entries 
%       and coluns are the variables).
%   y: Evaluate of each row in X.

% Sort solutions by their fitness
[~,idx] = sort(pool.y,'ascend');
auxpool_X = pool.X(idx,:);
auxpool_y = pool.y(idx);
 
% Select the sample_size lowest solution
X = auxpool_X(1:sample_size,:);
y = auxpool_y(1:sample_size);
 
% Number of solutions in the pool
pool_size = size(auxpool_X,1);

% If standart deviation of X or y is zero, then the metamodel sample must be redefined.
while (any(std(X) < std_tol) || any(isnan(std(X))) || std(y) < std_tol || isnan(std(y))) && sample_size < pool_size
    sample_size = sample_size + 1;
    X = auxpool_X(1:sample_size,:);
    y = auxpool_y(1:sample_size);
end

end
%
function [X,y] = choose_nearest(pop_X, pool, n_nearest, sample_size, std_tol)
% CHOOSE_NEAREST: Choose a sample to create/update the metamodel.
% This function chooses the nearest solutions, for each solution in pop_X
%
% Input: 
%   pop_X: Current population of EA
%   pool: Pool of solutions
%   in the population
%   n_nearest: Number of nearest solutions
%   sample_size: Metamodel sample size
%   std_tol: Threshold value of the variance
% 
% Output:
%   X: The sample selected to build the metamodel (rows are entries 
%       and coluns are the variables).
%   y: Evaluate of each row in X.
% 

% Pool size N_pool
[N_pool, n] = size(pool.X);

% pop_X size N_pop
[N_pop, ~] = size(pop_X);

% Distance between pop_X and pool, for each solution in pop_X
d_pop_pool = zeros(N_pop, N_pool);

% Initialize the array
index_pop_pool = zeros(n_nearest,N_pop);
index_sample = [];

% Identify the nearest solution, for each centroids of P
for i = 1:N_pop
    d_pop_pool(i,:) = sqrt(sum((repmat(pop_X(i,:), N_pool, 1) - pool.X) .^ 2, 2));
    [~, index_sort] = sort(d_pop_pool(i,:),'ascend');
    
    for j = 1:n_nearest
        count_index = 1;
        [ir,~] = find(index_pop_pool == index_sort(count_index));
        while ~isempty(ir)
            count_index = count_index + 1;
            [ir,~] = find(index_pop_pool == index_sort(count_index));
        end
        index_pop_pool(j,i) = index_sort(count_index);
        index_sample = [index_sample;index_pop_pool(j,i)];
    end
    
end

% Stores in X the solutions identified by index_sample
X = pool.X(index_sample,:);
y = pool.y(index_sample);

% Number of solutions in the pool
auxpool_X = pool.X;
auxpool_y = pool.y;
auxpool_X(index_sample,:) = [];
auxpool_y(index_sample) = [];
auxpool_X = [X;auxpool_X];
auxpool_y = [y;auxpool_y];
pool_size = size(auxpool_X,1);

sample_size = length(index_sample);
% If standart deviation of X or y is zero, then the metamodel sample must be redefined.
while (any(std(X) < std_tol) || any(isnan(std(X))) || std(y) < std_tol || isnan(std(y))) && sample_size < pool_size
    sample_size = sample_size + 1;
    X = auxpool_X(1:sample_size,:);
    y = auxpool_y(1:sample_size);
end


end
%
function [X,y] = choose_newest(pool,sample_size, std_tol)
% CHOOSE_METAMODEL_SAMPLE: Choose a sample to create/update the metamodel.
% This function chooses the newest solutions into the pool to compose the
% sample.
%
% Input: 
%   pool: Pool of solutions.
%   n_nearest: Number of nearest solutions
%   sample_size: Metamodel sample size
%   std_tol: Threshold value of the variance
% 
% Output:
%   X: The sample selected to build the metamodel (rows are entries 
%       and coluns are the variables).
%   y: Evaluate of each row in X.
% 

% Sort solutions by their age
[~,idx] = sort(pool.age,'descend');
auxpool_X = pool.X(idx,:);
auxpool_y = pool.y(idx);
 
% Select the sample_size newest solution
X = auxpool_X(1:sample_size,:);
y = auxpool_y(1:sample_size);
 
% Number of solutions in the pool
pool_size = size(auxpool_X,1);

% If standart deviation of X or y is zero, then the metamodel sample must be redefined.
while (any(std(X) < std_tol) || any(isnan(std(X))) || std(y) < std_tol || isnan(std(y))) && sample_size < pool_size
    sample_size = sample_size + 1;
    X = auxpool_X(1:sample_size,:);
    y = auxpool_y(1:sample_size);
end

end