function [chosen_X, others_X, chosen_pred, index_SSM, info] = using_several_metamodels(P, pool, N, n, lb, ub, std_tol, k_nearest, type, params, info)
% USING_SEVERAL_METAMODELS: Build the metamodels and choose N solutions from P 
% (one solution per subpopulation)
%
% Input: 
%   P: Structure with the offspring solutions for each solution
%   in the population.
%   pool: Pool of solutions
%   N: Size of pop_X
%   n: Number of variables
%   lb: Lower bounds
%   ub: Upper bounds
%   std_tol: Threshold value of the variance
%   k_nearest: Number of nearest solutions
%   type: Type of metamodel
%   params:  A structure with fields that keep parameters used by the SAEA
%       (including toolboxes ooDACE and SRGTSToolbox)
%   info: A structure used to keep the progress of the SAEA algorithm
% Output:
%   chosen_X: N solutions selected from structure P
%   others_X: Structure with the remaining solutions
%   chose_pred: Evaluate on fpred of each row in chosen_X
%   info: A structure used to keep the progress of the SAEA algorithm 

% Initialize the array
chosen_X = zeros(N,n);
chosen_pred = zeros(N,1);
others_X = P;
index_SSM = struct('');

% Pool size N_pool
[N_pool, ~] = size(pool.X);

% Structure size N_pop
N_pop = size(P,2);

% Calculate the centroid
for k = 1:N_pop
    pop_centroid(k,:) = mean(P(k).solution,1);
end

% Distance between P and pool, for each centroid of
% pop_offspring
d_pop_pool = zeros(N_pop, N_pool);

% Choose N solutions from P (one solution per subpopulation)
for i = 1:N_pop
    % Identify the nearest solution, for each centroid of pop_offspring
    d_pop_pool(i,:) = sqrt(sum((repmat(pop_centroid(i,:), N_pool, 1) - pool.X) .^ 2, 2));
    [~, index_sort] = sort(d_pop_pool(i,:),'ascend');
  
    % Select a sample to build/update the metamodel
    X = pool.X(index_sort(1:k_nearest),:);
    y = pool.y(index_sort(1:k_nearest));
    
    % Number of solutions in the pool
    pool_size = size(pool.X,1);
    
    sample_size = k_nearest;
    % If standart deviation of X or y is zero, then the metamodel sample must be redefined.
    while (any(std(X) < std_tol) || any(isnan(std(X))) || std(y) < std_tol || isnan(std(y))) && sample_size < pool_size
        sample_size = sample_size + 1;
        X = pool.X(index_sort(1:sample_size),:);
        y = pool.y(index_sort(1:sample_size));
    end
    sample_X = X;
    sample_y = y;
    
    % Store the index of sample
    index_SSM(i).index = index_sort(1:sample_size);
    
    % Build the metamodel
    tt0_start = cputime;
    model_info = build_metamodel(sample_X, sample_y, lb, ub, type, params);
    tt0_end = cputime - tt0_start;

    info.history.metamodel_runtime = [info.history.metamodel_runtime, tt0_end];
    info.metamodel = model_info;
    
    % Choose one solution from P(i).solution
    [chosenX, othersX, chosenpred] = select_solutions(P(i).solution, 1, n, lb, ub, params.evolution_control, model_info, params.metamodel);

    chosen_X(i,:) = chosenX;
    chosen_pred(i,1) = chosenpred;
    others_X(i).solution = othersX;
    
%     fpred = model_info.fobjPredicao;
% 
%     % Evaluate solutions in sub-population i
%     aux_y = feval_all(fpred, P(i).solution);
% 
%     % Find solution with the lowest predicted value
%     [pred_min, idx_min] = min(aux_y);
% 
%     chosen_X(i,:) = P(i).solution(idx_min,:);
%     chosen_pred(i,1) = pred_min;
%     others_X(i).solution(idx_min,:) = [];
end



end