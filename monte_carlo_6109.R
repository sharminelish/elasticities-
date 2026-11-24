# =============================================================================
# Monte Carlo: what does a gravity regression on tariffs recover?
#   Customs values (excl. duty) recover -sigma; buyer spending (incl. duty)
#   recovers -theta = -(sigma - 1). True sigma set to CEPII ProTEE for HS 6109.
#
# Author: Elish Sharmin  |  github.com/sharminelish
# Runtime: about 1-3 minutes (200 PPML regressions).
# =============================================================================

library(fixest)
library(data.table)
library(ggplot2)
library(haven)

BASE <- "."   # run from the elasticities folder, e.g. setwd("E:/elasticities")
f_protee <- file.path(BASE, "final_tariff_HS4.dta")
out_dir  <- file.path(BASE, "figures")
dir.create(out_dir, showWarnings = FALSE)

set.seed(2026)
protee <- read_dta(f_protee)
SIGMA  <- -protee$epsilon_HS4[protee$HS4 == "6109"]   # 7.28
THETA  <- SIGMA - 1
R      <- 200                                          # number of simulated panels

# ---- One simulated gravity panel -------------------------------------------
# True model (CES): buyer spending  X_incl = exp(FE) * (1 + t)^(1 - sigma)
# Customs records the value before duty: X_rec = X_incl / (1 + t)
sim_panel <- function(N = 40, T = 8) {
  d <- CJ(i = 1:N, j = 1:N, yr = 1:T)[i != j]
  pair <- unique(d[, .(i, j)])
  pair[, `:=`(base_t = runif(.N, 0, 0.35),                     # initial tariff
              rta_yr = sample(c(2:T, rep(Inf, T)), .N, TRUE),   # about half liberalise
              g_ij   = rnorm(.N, 0, 1))]
  d <- merge(d, pair, by = c("i", "j"))
  d[, tariff := pmax(0, ifelse(yr >= rta_yr, 0, base_t) + rnorm(.N, 0, 0.02))]
  ex <- CJ(i = 1:N, yr = 1:T)[, a := rnorm(.N, 5, 1)]
  im <- CJ(j = 1:N, yr = 1:T)[, b := rnorm(.N, 0, 1)]
  d <- merge(merge(d, ex, by = c("i", "yr")), im, by = c("j", "yr"))
  eps <- rgamma(nrow(d), shape = 2, rate = 2)                   # mean-1 noise
  d[, X_incl := exp(a + b + g_ij) * (1 + tariff)^(1 - SIGMA) * eps]
  d[, X_rec  := X_incl / (1 + tariff)]
  d[]
}

# ---- Estimate with PPML on both valuations ---------------------------------
mc <- rbindlist(lapply(seq_len(R), function(r) {
  d <- sim_panel()
  f <- function(y) coef(fepois(as.formula(paste(y,
         "~ log(1 + tariff) | i^yr + j^yr + i^j")), data = d))[1]
  data.table(rep = r, recorded = f("X_rec"), spending = f("X_incl"))
}))
print(mc[, .(mean_customs = mean(recorded), sd_customs = sd(recorded),
             mean_spending = mean(spending), sd_spending = sd(spending))])

# ---- Chart (LinkedIn 1080 x 1350) ------------------------------------------
col_main <- "#2a78d6"; col_2 <- "#eb6834"
ink <- "#0b0b0b"; ink2 <- "#52514e"; bg <- "#fcfcfb"

mcl <- melt(mc, id.vars = "rep", variable.name = "valuation", value.name = "beta")
mcl[, valuation := factor(valuation, c("recorded", "spending"),
        c("Customs value (excl. duty)", "Buyer spending (incl. duty)"))]

p <- ggplot(mcl, aes(beta, fill = valuation)) +
  geom_histogram(binwidth = 0.05, position = "identity", colour = bg,
                 linewidth = 0.2, alpha = 0.8) +
  geom_vline(xintercept = c(-SIGMA, -THETA), colour = ink, linetype = "22", linewidth = 0.4) +
  annotate("text", x = -SIGMA, y = Inf, vjust = 1.6, hjust = 1.08, size = 3.6, colour = ink,
           label = sprintf("true −σ = −%.2f", SIGMA)) +
  annotate("text", x = -THETA, y = Inf, vjust = 1.6, hjust = -0.08, size = 3.6, colour = ink,
           label = sprintf("true −θ = −%.2f", THETA)) +
  scale_fill_manual(values = c(col_main, col_2), name = NULL) +
  scale_x_continuous(breaks = seq(-9, -5, 1), limits = c(-SIGMA - 1.3, -THETA + 1.3)) +
  labs(title = "Same tariffs, same data:\nthe valuation decides what you estimate",
       subtitle = paste0("Tariff coefficients from ", R, " simulated gravity panels\n",
                         "(PPML, exporter-year, importer-year and pair fixed effects).\n",
                         "Customs data recover −σ; buyer spending recovers −θ = −(σ − 1)."),
       x = "Estimated coefficient on ln(1 + tariff)", y = "Number of simulations",
       caption = paste0("Simulated data. True σ = ", sprintf("%.2f", SIGMA),
                        ", CEPII ProTEE estimate for HS 6109 (T-shirts).\n",
                        "Code: github.com/sharminelish")) +
  theme_minimal(base_size = 13) +
  theme(plot.background  = element_rect(fill = bg, colour = NA),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#e6e5e1", linewidth = 0.3),
        plot.title       = element_text(face = "bold", size = 17, colour = ink),
        plot.subtitle    = element_text(colour = ink2, size = 11.5, lineheight = 1.15),
        plot.caption     = element_text(colour = ink2, size = 9, hjust = 0, lineheight = 1.1),
        axis.text        = element_text(colour = ink2),
        axis.title       = element_text(colour = ink2, size = 11),
        legend.position  = "top", legend.justification = "left",
        plot.margin      = margin(24, 60, 18, 18),
        plot.title.position = "plot", plot.caption.position = "plot")

ggsave(file.path(out_dir, "t6_monte_carlo.png"), p, width = 6, height = 7.5, dpi = 180)
fwrite(mc, file.path(out_dir, "monte_carlo_coefficients.csv"))
