## This script calls other scripts that performs the experiments
## of this work.
##
## Contributors:
## - Mônica A. C. Valadão
## - André L. Maravilha
## - Lucas S. Batista


# =================================================================================================
# Run all scripts

# Solution quality
source("./01-solution_quality.R")

# Convergence
source("./02-convergence.R")

# Runtime
source("./03-runtime.R")

# Improvement vs. runtime
source("./04-improvement_vs_runtime.R")
