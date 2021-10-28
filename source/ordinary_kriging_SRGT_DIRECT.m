% Ordinary Kriging Metamodel using SRGTSToolbox
function [model_info] = ordinary_kriging_SRGT_DIRECT(sample_X, sample_y, lb, ub)

[N,~] = size(sample_X);
n = 1;
FIT_Fn = @dace_fit;
KRG_RegressionModel = @dace_regpoly0; 
KRG_CorrelationModel = @dace_corrgauss;
KRG_Theta0 = (N.^(-1/n))*ones(1, n);
KRG_LowerBound = 0.01;  % lower bound theta
KRG_UpperBound = 20;  % upper bound theta
srgtstoolbox_opts  = srgtsKRGSetOptions(sample_X, sample_y,FIT_Fn, KRG_RegressionModel, KRG_CorrelationModel, KRG_Theta0, KRG_LowerBound, KRG_UpperBound);
[ModeloSRTSTolbox] = srgtsKRGFit_DIRECT(srgtstoolbox_opts);  
model_info.SRTSToolbox = ModeloSRTSTolbox;
model_info.Theta = ModeloSRTSTolbox.KRG_DACEModel.theta; % Here, theta is 10.^Theta
model_info.Lower = lb;
model_info.Upper = ub;
model_info.p = 2*ones(1,n);     
model_info.fobjPredicao = @(x)(srgtsKRGEvaluate(x,model_info.SRTSToolbox));
model_info.fobjEI = @(x)(expimp_SRGTSToolbox(x,sample_y,model_info));

end