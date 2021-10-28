function [model_info] = build_metamodel_OK_SRGT_DIRECT(sample_X, sample_y)
% METAMODEL_OK_UNIDIMENSIONAL: Constrói um metamodelo OK unidimensional por
% meio das toolboxes SRGTSToolbox e DIRECTalgorithm.

% Build a Simplified Kriging metamodel.
lb_d1 = -1; % To build on one-dimension - the correct value is defined in build_metamodel_DIRECT.
ub_d1 = 1;  % To build on one-dimension - the correct value is defined in build_metamodel_DIRECT.
[model_info] = ordinary_kriging_SRGT_DIRECT(sample_X, sample_y, lb_d1, ub_d1);

end