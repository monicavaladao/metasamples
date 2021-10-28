## Convergence
##
## This script perform some exploratory analysis and statistical tests to investigate
## the convergence of the different approaches evaluated in this work towards regions 
## of good quality solutions.
##
## Contributors:
## - Mônica A. C. Valadão
## - André L. Maravilha
## - Lucas S. Batista


# =================================================================================================
# Clear workspace

rm(list = ls())


# =================================================================================================
# Install dependencies

deps.list <- c("dplyr", "ggplot2", "MESS", "boot")
deps.missing <- deps.list[!(deps.list %in% installed.packages()[,"Package"])]
if (length(deps.missing) > 0) {
  install.packages(deps.missing)
}


# =================================================================================================
# Load libraries

suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(MESS))
suppressMessages(library(boot))


# =================================================================================================
# Load and pre-process data

# Load "metamodels" and "DE" data
mm.results <- read.csv("./data/metamodels.csv", header = TRUE, stringsAsFactors = FALSE)
de.results <- read.csv("./data/de.csv", header = TRUE, stringsAsFactors = FALSE)

# Join "metamodels" and "DE" data
de.results["MEAN.DIFF"] = numeric()
de.results["METAMODEL.TIME.S"] = numeric()
de.results["RULE"] = de.results$METAMODEL

aggdata <- union(mm.results, de.results)
aggdata$PROB <- factor(aggdata$PROB, unique(aggdata$PROB))
aggdata$RULE <- factor(aggdata$RULE, unique(aggdata$RULE))

# Rename levels of the factor RULE
levels(aggdata$RULE) <- list(DE = "DEbest", S1 = "kmeans", S2 = "lowest", 
                             S3 = "nearest", S4 = "k_nearest", S5 = "newest")

# Pre-process data
aggdata <- aggdata %>%
  dplyr::filter(!(PROB %in% c('perm0db'))) %>%
  dplyr::select(PROB, NVAR, REP, RULE, ITER, NEVAL, BEST.OBJ) %>%
  dplyr::group_by(PROB, NVAR, REP, RULE) %>%
  dplyr::mutate(IMPROV.OBJ = (max(BEST.OBJ) - BEST.OBJ) / max(BEST.OBJ),
                PERC.NEVAL = NEVAL / max(NEVAL)) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(PROB, NVAR, REP, RULE, ITER)


# =================================================================================================
# Create directory in which output figures are saved

output.directory <- file.path(".", "figures", "02_convergence")
dir.create(output.directory, showWarnings = FALSE, recursive = TRUE)


# =================================================================================================
# Auxiliary functions

# This function return an array of boolean values, in which the i-th value of the returned 
# array is TRUE if the i-th value in the input parameter x is an outlier, FALSE otherwise.
is_outlier <- function(x) {
  outliers <- x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x)
  return(outliers)
}


# =================================================================================================
# Convergence plot
# Plots stratified by problem and problem size

# Prepare data
fig.data <- aggdata %>%
  dplyr::group_by(PROB, NVAR, RULE, PERC.NEVAL) %>%
  dplyr::summarise(MEAN.IMPROV.OBJ = mean(IMPROV.OBJ),
                   SD.IMPROV.OBJ = sd(IMPROV.OBJ)) %>%
  dplyr::arrange(PROB, NVAR, RULE, PERC.NEVAL)

# Create figure
fig <- ggplot2::ggplot(fig.data, aes(x = 100 * PERC.NEVAL, y = 100 * MEAN.IMPROV.OBJ, 
                                     ymin = MEAN.IMPROV.OBJ - SD.IMPROV.OBJ, 
                                     ymax = MEAN.IMPROV.OBJ + SD.IMPROV.OBJ, 
                                     color = RULE, fill = RULE)) +
  ggplot2::geom_line(size = 0.25) +
  #ggplot2::geom_ribbon(alpha=0.5) + 
  ggplot2::facet_grid(PROB ~ NVAR, scales = "fixed") +
  ggplot2::xlab("Budget used for function evaluations (%)") +
  ggplot2::ylab("Mean improv. over the best initial solution (%)") +
  ggplot2::scale_color_discrete(name = "Strategy: ") + 
  ggplot2::scale_fill_discrete(name = "Strategy: ") +
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "bottom",
                 legend.title = element_text(size = 12),
                 legend.text = element_text(size = 12),
                 axis.title = element_text(size = 14),
                 axis.text = element_text(size = 8, margin = margin(t = 6, b = 6)),
                 axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
                 strip.text = element_text(size = 12),
                 strip.background = element_blank()) +
  ggplot2::guides(colour = ggplot2::guide_legend(nrow = 1))

# Save figure as PDF
ggplot2::ggsave(file.path(output.directory, "convergence-by_function_and_size.pdf"), 
                plot = fig, width = 210, height = 290, units = "mm")

# Save figure as PNG
ggplot2::ggsave(file.path(output.directory, "convergence-by_function_and_size.png"), 
                plot = fig, width = 210, height = 290, units = "mm")

# Save figure as eps
ggplot2::ggsave(file.path(output.directory, "convergence-by_function_and_size.eps"), 
                plot = fig, width = 210, height = 290, units = "mm")
# =================================================================================================
# Boxplot
# Mean area under the improvement curve (AUC) vs. strategy

# Prepare data
fig.data <- aggdata %>%
  dplyr::mutate(PROB.NVAR = as.factor(sprintf("%s (%02d)", PROB, NVAR))) %>%
  dplyr::group_by(PROB.NVAR, REP, RULE) %>%
  dplyr::summarise(AUC = MESS::auc(PERC.NEVAL, IMPROV.OBJ)) %>%
  dplyr::group_by(PROB.NVAR, RULE) %>%
  dplyr::summarise(AUC = mean(AUC)) %>%
  dplyr::group_by(RULE) %>%
  dplyr::mutate(IS.OUTLIER = is_outlier(AUC)) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(PROB.NVAR, RULE)

# Create figure
fig <- ggplot2::ggplot(fig.data, aes(x = RULE, y = AUC, label = PROB.NVAR, fill = RULE)) +
  ggplot2::geom_boxplot() +
  ggplot2::geom_text(data = subset(fig.data, IS.OUTLIER == TRUE), 
                     size = 2, hjust = 0, nudge_x = 0.05, check_overlap = FALSE) +
  ggplot2::xlab("Strategy") +
  ggplot2::ylab("Mean area under the improvement curve") +
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "none",
                 axis.title = element_text(size = 16),
                 axis.text = element_text(size = 12, margin = margin(t = 6, b = 6)))

# Save figure as PDF
ggplot2::ggsave(file.path(output.directory, "auc-boxplot-overall.pdf"),
                plot = fig, width = 10, height = 7)

# Save figure as PNG
ggplot2::ggsave(file.path(output.directory, "auc-boxplot-overall.png"), 
                plot = fig, width = 10, height = 7)

# Save figure as eps
ggplot2::ggsave(file.path(output.directory, "auc-boxplot-overall.eps"), 
                plot = fig, width = 10, height = 7)
# =================================================================================================
# Boxplot
# Mean area under the improvement curve (AUC) vs. strategy
# Plots stratified by function and size

# Prepare data
fig.data <- aggdata %>%
  dplyr::mutate(PROB.NVAR = as.factor(sprintf("%s (%02d)", PROB, NVAR))) %>%
  dplyr::group_by(PROB.NVAR, RULE, REP) %>%
  dplyr::summarise(AUC = MESS::auc(PERC.NEVAL, IMPROV.OBJ)) %>%
  dplyr::arrange(PROB.NVAR, RULE, REP)

# Create figure
fig <- ggplot2::ggplot(fig.data, aes(x = AUC, y = RULE, fill = RULE)) +
  ggplot2::geom_boxplot() +
  ggplot2::facet_wrap(~PROB.NVAR, ncol = 5, scales = "free") +
  ggplot2::scale_x_continuous(labels = function(x) {sprintf("%.2f", x)} ) +
  ggplot2::xlab("Mean area under the improvement curve") +
  ggplot2::ylab("Strategy") +
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "none",
                 axis.title = element_text(size = 12),
                 axis.text = element_text(size = 6, margin = margin(t = 6, b = 6)),
                 axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
                 strip.text = element_text(size = 8),
                 strip.background = element_blank()) + 
  ggplot2::coord_flip()

# Save figure as PDF
ggplot2::ggsave(file.path(output.directory, "auc-boxplot-by_function_and_size.pdf"),
                plot = fig, width = 210, height = 290, units = "mm")

# Save figure as PNG
ggplot2::ggsave(file.path(output.directory, "auc-boxplot-by_function_and_size.png"), 
                plot = fig, width = 210, height = 290, units = "mm")

# Save figure as eps
ggplot2::ggsave(file.path(output.directory, "auc-boxplot-by_function_and_size.eps"), 
                plot = fig, width = 210, height = 290, units = "mm")
# =================================================================================================
# Inference using Bootstrap CIs (Bonferroni-corrected)

# Prepare data
mc.data <- aggdata %>%
  #dplyr::filter(!RULE %in% c("DE")) %>%
  dplyr::mutate(PROB.NVAR = as.factor(sprintf("%s (%02d)", PROB, NVAR))) %>%
  dplyr::group_by(PROB.NVAR, REP, RULE) %>%
  dplyr::summarise(AUC = MESS::auc(PERC.NEVAL, IMPROV.OBJ)) %>%
  dplyr::group_by(PROB.NVAR, RULE) %>%
  dplyr::summarise(AUC = mean(AUC)) %>%
  dplyr::arrange(PROB.NVAR, RULE)

# Bonferroni correction for 95% confidence level (alpha = 0.05)
num.levels <- length(unique(mc.data$RULE))
num.tests <- (num.levels * (num.levels - 1)) / 2
conf <- 1 - (0.5 / num.tests)

# Prepare structure to store the Bootstrap CIs of paired differences
mc.ci <- data.frame(pair = character(0),  stats = numeric(),  lci = numeric(),  uci = numeric(), 
                    stringsAsFactors = FALSE)

# Compute Bootstrap CIs for each paired difference
for (i1 in 1:num.levels) {
  for (i2 in 1:num.levels) {
    if (i1 < i2) {
      
      # Get paired difference sample
      x1 <- unique(mc.data$RULE)[i1]
      x2 <- unique(mc.data$RULE)[i2]
      paired.diff <- mc.data$AUC[mc.data$RULE == x1] - mc.data$AUC[mc.data$RULE == x2]
      
      # Get Bootstrap replicates
      reps <- boot::boot(paired.diff, statistic = function(x, i){mean(x[i])}, R = 9999)
      
      # Compute Bootstrap CI
      ci <- boot::boot.ci(reps, conf = conf, type = "basic")
      
      # Store the Bootstrap CI
      mc.ci[nrow(mc.ci) + 1,] <- list(pair = sprintf("%s vs. %s", x1, x2),
                                      stats = ci$t0, lci = ci$basic[4], uci = ci$basic[5])
    }
  }
}

# Create figure with multiple CIs
fig <- ggplot2::ggplot(mc.ci, 
                       aes(x = factor(pair, levels = rev(pair), ordered = TRUE), 
                           y = stats, 
                           ymin = lci, ymax = uci)) +
  ggplot2::geom_hline(yintercept = 0, size = 1.25, col = 2, linetype = 2) + 
  ggplot2::geom_pointrange(fatten = 3, size = 1.25) + 
  ggplot2::coord_flip() + 
  xlab("Comparison") +
  ylab("Difference in mean area under the improvement curve") +
  ggplot2::theme_bw() +
  ggplot2::theme(axis.text = element_text(size = 16), 
                 axis.title = element_text(size = 16), 
                 axis.title.x = element_text(size = 18, margin = margin(t = 15)),
                 axis.title.y = element_text(size = 18, margin = margin(r = 10)),
                 legend.position = "none",
                 #panel.background = element_blank(),
                 panel.border = element_rect(colour = "black", fill = NA, size = 1))

# Save figure as PDF
ggplot2::ggsave(file.path(output.directory, "auc-ci.pdf"), 
                plot = fig, width = 10, height = 7)

# Save figure as PNG
ggplot2::ggsave(file.path(output.directory, "auc-ci.png"), 
                plot = fig, width = 10, height = 7)

# Save figure as eps
ggplot2::ggsave(file.path(output.directory, "auc-ci.eps"), 
                plot = fig, width = 10, height = 7)
