# ==============================================================================
# Clear workspace

rm(list = ls())


# ==============================================================================
# Install dependencies

dependencies.list <- c(
  "dplyr",
  "ggplot2",
  "xtable",
  "PMCMR"
)

dependencies.missing <- dependencies.list[!(dependencies.list %in% installed.packages()[,"Package"])]
if (length(dependencies.missing) > 0) {
  
  # Notify for missing libraries
  print("The following packages are required but are not installed:")
  print(dependencies.missing)
  dependencies.install <- readline(prompt = "Do you want them to be installed (Y/n)? ")
  if (any(tolower(dependencies.install) == c("y", "yes"))) {
    install.packages(dependencies.missing)
  }
}


# ==============================================================================
# Load libraries

suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(xtable))
suppressMessages(library(PMCMR))


# ==============================================================================
# Read data from files

# Read data file
data.results <- read.csv("./data/metamodels.csv", header = TRUE)


# Factors rule
rule.factors <- list(S1 = "kmeans",
                     S2 = "lowest",
                     S3 = "nearest",
                     S4 = "k_nearest",
                     S5 = "newest")

levels(data.results$RULE) <- rule.factors

# Compute objective function improvement
data.results <- data.results %>%
  dplyr::filter(!(PROB %in% c('perm0db'))) %>%
  dplyr::group_by(PROB, NVAR, METAMODEL, RULE, REP) %>%
  dplyr::mutate(IMPROV.OBJ = 100 * ((max(BEST.OBJ) - BEST.OBJ) / max(BEST.OBJ))) %>%
  dplyr::ungroup()

data.results$PROB <- factor(data.results$PROB, unique(data.results$PROB))

# ===========================================================================
# Tables: Best value of objective function

# Pre-process data
aggdata <- data.results %>%
  dplyr::group_by(PROB, NVAR, METAMODEL, RULE, REP) %>%
  dplyr::filter(ITER == max(ITER)) %>%
  dplyr::group_by(PROB, NVAR, RULE) %>%
  dplyr::summarise(MEAN.BEST.OBJ = mean(BEST.OBJ), 
                   STD.BEST.OBJ = sd(BEST.OBJ)) %>%
  dplyr::arrange(PROB, NVAR, RULE)

table.results <- with(aggdata,
                      cbind(PROB     = aggdata$PROB[aggdata$RULE == "S1"],
                            NVAR     = aggdata$NVAR[aggdata$RULE == "S1"],
                            S1.MEAN  = aggdata$MEAN.BEST.OBJ[aggdata$RULE == "S1"],
                            S1.STD   = aggdata$STD.BEST.OBJ[aggdata$RULE == "S1"],
                            S2.MEAN = aggdata$MEAN.BEST.OBJ[aggdata$RULE == "S2"],
                            S2.STD  = aggdata$STD.BEST.OBJ[aggdata$RULE == "S2"],
                            S3.MEAN = aggdata$MEAN.BEST.OBJ[aggdata$RULE == "S3"],
                            S3.STD  = aggdata$STD.BEST.OBJ[aggdata$RULE == "S3"],
                            S4.MEAN  = aggdata$MEAN.BEST.OBJ[aggdata$RULE == "S4"],
                            S4.STD   = aggdata$STD.BEST.OBJ[aggdata$RULE == "S4"],
                            S5.MEAN = aggdata$MEAN.BEST.OBJ[aggdata$RULE == "S5"],
                            S5.STD = aggdata$STD.BEST.OBJ[aggdata$RULE == "S5"]))

xtable(table.results, digits = c(0,0,0,4,4,4,4,4,4,4,4,4,4))
