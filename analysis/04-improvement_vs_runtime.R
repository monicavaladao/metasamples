## Improvement vs. Runtime
##
## This script create plots of percentage improvment vs. iteration runtime
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

deps.list <- c("dplyr", "ggplot2", "ggforce", "grid")
deps.missing <- deps.list[!(deps.list %in% installed.packages()[,"Package"])]
if (length(deps.missing) > 0) {
  install.packages(deps.missing)
}


# =================================================================================================
# Load libraries

suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(ggforce))
suppressMessages(library(grid))

source("./libs/facet_zoom2.R")


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
  dplyr::filter(!(RULE %in% c('DE'))) %>%
  dplyr::select(PROB, NVAR, REP, RULE, ITER, NEVAL, TOTAL.TIME.S, BEST.OBJ) %>%
  dplyr::group_by(PROB, NVAR, REP, RULE) %>%
  dplyr::mutate(IMPROV.OBJ = (max(BEST.OBJ) - BEST.OBJ) / max(BEST.OBJ),
                DELTA.TIME.S = TOTAL.TIME.S / ITER) %>%
  dplyr::filter(ITER == max(ITER)) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(PROB, NVAR, REP, RULE)
  

# =================================================================================================
# Create directory in which output figures are saved

output.directory <- file.path(".", "figures", "04_improvement_vs_runtime")
dir.create(output.directory, showWarnings = FALSE, recursive = TRUE)


# =================================================================================================
# Crossbar
# Improvement vs. runtime

# Prepare data
fig.data <- aggdata %>%
  dplyr::mutate(PROB.NVAR = as.factor(sprintf("%s (%02d)", PROB, NVAR))) %>%
  dplyr::group_by(PROB.NVAR, RULE) %>%
  dplyr::summarise(IMPROV.OBJ = mean(IMPROV.OBJ),
                   DELTA.TIME.S = mean(DELTA.TIME.S)) %>%
  dplyr::group_by(RULE) %>%
  dplyr::summarise(MEAN.IMPROV.OBJ = mean(IMPROV.OBJ),
                   SE.IMPROV.OBJ = sd(IMPROV.OBJ) / sqrt(n()),
                   MEAN.DELTA.TIME.S = mean(DELTA.TIME.S), 
                   SE.DELTA.TIME.S = sd(DELTA.TIME.S) / sqrt(n())) %>%
  dplyr::arrange(RULE)

# Create figure
fig <- ggplot2::ggplot(fig.data, 
                       aes(x = MEAN.DELTA.TIME.S,
                           xmin = MEAN.DELTA.TIME.S - SE.DELTA.TIME.S,
                           xmax = MEAN.DELTA.TIME.S + SE.DELTA.TIME.S,
                           y = MEAN.IMPROV.OBJ, 
                           ymin = MEAN.IMPROV.OBJ - SE.IMPROV.OBJ, 
                           ymax = MEAN.IMPROV.OBJ + SE.IMPROV.OBJ,
                           color = RULE)) +
  ggplot2::geom_point(shape = 22, size = 3) +
  ggplot2::geom_errorbarh(height = 0, size = 0.75) +
  ggplot2::geom_errorbar(width = 0, size = 0.75) +
  ggplot2::xlab("Mean runtime per iteration (in seconds)") +
  ggplot2::ylab("Mean improv. over the best initial solution (%)") +
  ggplot2::scale_color_discrete(name = "Strategy: ") + 
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "bottom",
                 legend.title = element_text(size = 14),
                 legend.text = element_text(size = 14),
                 axis.title = element_text(size = 14),
                 axis.text = element_text(size = 12, margin = margin(t = 6, b = 6))) +
  facet_zoom2(xlim = c(0.1, 0.3), ylim = c(0.95, 0.99), 
  #facet_zoom2(xlim = c(5, 11), ylim = c(0.965, 0.99),            
              zoom.size = 1, show.area = TRUE, shrink = TRUE, split = FALSE)

# Save figure as PDF
ggplot2::ggsave(file.path(output.directory, "improvement_vs_runtime-crossbar.pdf"),
                plot = fig, width = 10, height = 5)

# Save figure as PNG
ggplot2::ggsave(file.path(output.directory, "improvement_vs_runtime-crossbar.png"), 
                plot = fig, width = 10, height = 5)

# Save figure as eps
ggplot2::ggsave(file.path(output.directory, "improvement_vs_runtime-crossbar.eps"), 
                plot = fig, width = 10, height = 5)
