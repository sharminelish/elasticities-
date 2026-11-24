# =============================================================================
# Run everything: figures t1-t6 for "Bangladeshi T-shirts in Brazil (HS 6109)"
#
# Usage (R or RStudio):
#   setwd("E:/elasticities")      # the folder that contains this file
#   source("run_all.R")
#
# Author: Elish Sharmin  |  github.com/sharminelish
# =============================================================================

# Install any missing packages
pkgs <- c("data.table", "ggplot2", "scales", "haven", "fixest")
missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) install.packages(missing)

# Check the input files are here
inputs <- c("brazil_6109_import_shares.csv", "final_tariff_HS4.dta")
absent <- inputs[!file.exists(inputs)]
if (length(absent) > 0) {
  stop("Missing input file(s): ", paste(absent, collapse = ", "),
       "\nWorking directory is: ", getwd(),
       "\nUse setwd() to point R at the elasticities folder.")
}

message("1/2  T-shirt analysis: figures t1-t5")
source("tshirt_6109_analysis.R")

message("2/2  Monte Carlo (200 PPML regressions, about 30 s to 3 min): figure t6")
source("monte_carlo_6109.R")

message("Done. Figures are in: ", normalizePath("figures"))
