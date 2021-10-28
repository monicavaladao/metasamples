function [chosen_X, others_X, chosen_pred] = select_solutions(P, N, n, lb, ub, evolution_control, model_info, metamodel_type)
% SELECT_SOLUTIONS: Select solutions to evaluate on original function.
%
% Input: 
%   P: Structure with cadidate solutions.
%   N: Number of solutions to select.
%   n: Number of variables.
%   model_info: Structure of the metamodel
%   evolution_control: Way to perform the evolution control
%   metamodel_type: Type of metamodel
%
% Output:
%   chosen_X: N solutions selected from structure P
%   others_X: Structure with the remaining solutions
%   chose_pred: Evaluate on fpred of each row in chosen_X


% If the input P is not a structure (it is the case when N = 1)
if N == 1
   aux_P = struct();
   aux_P.solution = P;
   P = [];
   P = aux_P;
end

chosen_X = zeros(N,n);
chosen_pred = zeros(N,1);
chosen_EI = zeros(N,1);
others_X = P;

switch evolution_control
        
    % Select solutions based on the metamodel
    case 'metamodel'
        
        % Identify the prediction function
        fpred = model_info.fobjPredicao;
        
        % Choose one solution per sub-population
        for i = 1:N
            
            % Evaluate solutions in sub-population i
            aux_y = feval_all(fpred, P(i).solution);
            
            % Find solution with the lowest predicted value
            [pred_min, idx_min] = min(aux_y);
            
            chosen_X(i,:) = P(i).solution(idx_min,:);
            chosen_pred(i,1) = pred_min;
            others_X(i).solution(idx_min,:) = [];
        end
                    
%         % Perform local search
%         [~,idx] = min(chosen_pred);
%         x = chosen_X(idx,:);
%         [x_ls, y_ls] = patternsearch(fpred, x, [], [], [], [], lb, ub, psoptimset('Display','off'));
%         chosen_X(idx,:) = x_ls;
% 		chosen_pred(idx,1) = y_ls;
        
    case 'exp_imp'
        switch metamodel_type
            % Select solutions based on the metamodel
            case 'RBF_SRGTSToolbox'
                
                % Identify the prediction function
                fpred = model_info.fobjPredicao;

                % Choose one solution per sub-population
                for i = 1:N

                    % Evaluate solutions in sub-population i
                    aux_y = feval_all(fpred, P(i).solution);

                    % Find solution with the lowest predicted value
                    [pred_min, idx_min] = min(aux_y);

                    chosen_X(i,:) = P(i).solution(idx_min,:);
                    chosen_pred(i,1) = pred_min;
                    others_X(i).solution(idx_min,:) = [];
                end

%                 % Perform local search
%                 [~,idx] = min(chosen_pred);
%                 x = chosen_X(idx,:);
%                 [x_ls, y_ls] = patternsearch(fpred, x, [], [], [], [], lb, ub, psoptimset('Display','off'));
%                 chosen_X(idx,:) = x_ls;
%                 chosen_pred(idx,1) = y_ls;
            % Select solutions based on the Expected Improvement value
            otherwise
                % Identify the prediction function
                fpred = model_info.fobjPredicao;

                % Identify the Expcted Improvement function
                f_EI = model_info.fobjEI;
                % Choose one solution per sub-population
                
                for i = 1:N
                
                    % Evaluate solutions in sub-population i
                    [aux_EI, aux_y] = feval_all_two_output(f_EI, P(i).solution);

                    % Find the solution with the highest value of Expected
                    % Improvement
                    [EI_max, idx_max] = max(aux_EI);
                     
                    chosen_X(i,:) = P(i).solution(idx_max,:);
                    chosen_pred(i,1) = aux_y(idx_max);
                    chosen_EI(i,1) = EI_max;
                    others_X(i).solution(idx_max,:) = [];
                
                end
                
%                 % Perform local search
%                 [~,idx] = max(chosen_EI);
%                 x = chosen_X(idx,:);
%                 [x_ls, y_ls] = patternsearch(@(x)(-f_EI(x)), x, [], [], [], [], lb, ub, psoptimset('Display','off'));
%                 chosen_X(idx,:) = x_ls;
%                 chosen_pred(idx,1) = fpred(y_ls);
                
        end
        
        
    % Randomly select solutions
    otherwise
        for i = 1:N
            % Identify the prediction function
            fpred = model_info.fobjPredicao;
           
            % Choose a solution from sub-population i
            idx = randi(size(P(i).solution, 1));
            chosen_X(i,:) = P(i).solution(idx,:);
            others_X(i).solution(idx,:) = [];

            % Evaluates the chosen solution on the metamodel
            chosen_pred(i,1) = feval_all(fpred, chosen_X(i,:));
        end
end

end
