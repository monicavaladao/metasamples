function [chosen_X, others_X, chosen_pred, info] = using_one_metamodel(P, sample_X, sample_y, N, n, lb, ub, type, params, info)
% USING_ONE_METAMODEL: Build the metamodel and choose N solutions from P 
% (one solution per subpopulation)
%
% Input: 
%   P: Structure with the offspring solutions for each solution
%   in the population.
%   sample_X: The sample selected to build the metamodel (rows are entries 
%       and coluns are the variables)
%   sample_y: Evaluate of each row in sample_X
%   N: Size of pop_X
%   n: Number of variables
%   lb: Lower bounds
%   ub: Upper bounds
%   type: Type of metamodel
%   params:  A structure with fields that keep parameters used by the SAEA
%       (including toolboxes ooDACE and SRGTSToolbox)
%   info: A structure used to keep the progress of the SAEA algorithm
% Output:
%   chosen_X: N solutions selected from structure P
%   others_X: Structure with the remaining solutions
%   chose_pred: Evaluate on fpred of each row in chosen_X
%   info: A structure used to keep the progress of the SAEA algorithm 

% Build the metamodel
tt0_start = cputime;
model_info = build_metamodel(sample_X, sample_y, lb, ub, type, params);
tt0_end = cputime - tt0_start;

info.history.metamodel_runtime = [info.history.metamodel_runtime, tt0_end];
info.metamodel = model_info;

% Choose N solutions from P (one solution per subpopulation)
[chosen_X, others_X, chosen_pred] = select_solutions(P, N, n, lb, ub, params.evolution_control, model_info, params.metamodel);


end