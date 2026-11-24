# =============================================================================
# Bangladeshi T-shirts (HS 6109) in Brazil: four elasticities, one tariff wall
#   Data: Comex Stat (MDIC/SECEX), imports Jan-Oct 2023-2025, HS 6109 by
#   country and NCM. Model: nested CES (Armington), partial equilibrium.
#
# Author: Elish Sharmin  |  github.com/sharminelish
# =============================================================================

library(data.table)
library(ggplot2)
library(scales)
library(haven)

# ---- Folder and input files -------------------------------------------------
BASE <- "."   # run from the elasticities folder, e.g. setwd("E:/elasticities")
f_comex     <- file.path(BASE, "brazil_6109_import_shares.csv")  # Comex Stat export
f_protee    <- file.path(BASE, "final_tariff_HS4.dta")           # CEPII ProTEE, HS4
out_dir     <- file.path(BASE, "figures")
dir.create(out_dir, showWarnings = FALSE)

# ---- Parameters (replace sigma / eta / S_M0 when sources are confirmed) ------
# sigma from CEPII ProTEE (Fontagne, Guimbard & Orefice 2022): HS4 trade
# elasticity = tariff elasticity = -sigma. HS 6109: -7.28, significant, no flags.
protee <- read_dta(f_protee)
SIGMA  <- -protee$epsilon_HS4[protee$HS4 == "6109"]
ETA    <- SIGMA / 2 # domestic vs imported T-shirts (assumption: sigma / 2 rule)
S_M0  <- 0.186  # imports share of apparel consumption, 2025 (CNI CAC, CNAE 14 proxy)
CET   <- 0.35   # MERCOSUR CET on HS 6109
YEAR  <- 2025   # calibration year (Jan-Oct)

# Origins paying 0%: MERCOSUR members and Peru (ACE 58: all trade duty-free
# except 12 codes). Other origins are treated at the 35% CET.
zero_duty <- c("Peru", "Paraguai", "Argentina", "Uruguai")

en <- c("Peru" = "Peru", "China" = "China", "Bangladesh" = "Bangladesh",
        "Vietnã" = "Vietnam", "Paquistão" = "Pakistan", "Turquia" = "Türkiye",
        "Tailândia" = "Thailand", "Camboja" = "Cambodia", "Índia" = "India",
        "Indonésia" = "Indonesia", "Paraguai" = "Paraguay", "Portugal" = "Portugal",
        "Itália" = "Italy", "Sri Lanka" = "Sri Lanka", "Marrocos" = "Morocco")

# ---- Read Comex Stat export (fields contain stray carriage returns) ---------
raw <- readChar(f_comex, file.size(f_comex), useBytes = TRUE)
d   <- fread(text = gsub("\r", "", raw, useBytes = TRUE), sep = ";", encoding = "UTF-8")
setnames(d, c("year", "country", "ncm", "desc", "unit", "fob", "freight",
              "insurance", "cif", "kg", "units"))
d <- d[country != "Brasil"]                       # drop re-imports
d[, tariff := fifelse(country %in% zero_duty, 0, CET)]
d[, country_en := fifelse(country %in% names(en), en[country], country)]

# ---- Descriptives -----------------------------------------------------------
totals <- d[, .(fob_musd = sum(fob) / 1e6, units_m = sum(units) / 1e6), by = year]
shares <- d[, .(fob = sum(fob)), by = .(year, country_en, tariff)][
            , share := fob / sum(fob), by = year]
print(totals)
print(dcast(shares, country_en ~ year, value.var = "share")[order(-`2025`)][1:10])

# ---- Style (LinkedIn 1080 x 1350) -------------------------------------------
col_main <- "#2a78d6"; col_2 <- "#eb6834"; col_3 <- "#1baf7a"
ink <- "#0b0b0b"; ink2 <- "#52514e"; bg <- "#fcfcfb"
theme_li <- function() {
  theme_minimal(base_size = 13) +
    theme(plot.background  = element_rect(fill = bg, colour = NA),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = "#e6e5e1", linewidth = 0.3),
          plot.title       = element_text(face = "bold", size = 17, colour = ink),
          plot.subtitle    = element_text(colour = ink2, size = 11.5, lineheight = 1.15),
          plot.caption     = element_text(colour = ink2, size = 9, hjust = 0, lineheight = 1.1),
          axis.text        = element_text(colour = ink2),
          axis.title       = element_text(colour = ink2, size = 11),
          legend.text      = element_text(colour = ink, size = 10.5),
          plot.margin      = margin(24, 60, 18, 18),
          plot.title.position = "plot", plot.caption.position = "plot")
}
save_li <- function(p, file) ggsave(file.path(out_dir, file), p, width = 6, height = 7.5, dpi = 180)
src_cap <- "Source: Comex Stat (MDIC/SECEX), HS 6109, January–October. Code: github.com/sharminelish"
sim_cap <- paste0("Calibrated to Comex Stat shares (Jan–Oct ", YEAR, "). σ = ", sprintf("%.2f", SIGMA),
                  " for HS 6109 (CEPII ProTEE).\nImport share ", S_M0 * 100, "% (CNI, apparel 2025, constant prices); η = σ/2 (assumed). ",
                  "\nPartial equilibrium; exporter prices fixed. Code: github.com/sharminelish")

# =============================================================================
# Figure 1: who supplies Brazil's T-shirts, and at what duty
# =============================================================================
top <- shares[year == YEAR][order(-share)][1:8]
top[, regime := factor(fifelse(tariff == 0, "Duty-free (trade agreement)", "Pays the 35% CET"),
                       c("Duty-free (trade agreement)", "Pays the 35% CET"))]
top[, country_en := factor(country_en, rev(country_en))]
bd_growth <- d[country == "Bangladesh", sum(fob), by = year][, V1[year == YEAR] / V1[year == 2023] - 1]
tot_growth <- totals[, fob_musd[year == YEAR] / fob_musd[year == 2023] - 1]

p1 <- ggplot(top, aes(share, country_en, fill = regime)) +
  geom_col(width = 0.62) +
  geom_text(aes(label = percent(share, 0.1)), hjust = -0.15, size = 4.2, colour = ink) +
  scale_fill_manual(values = c(col_3, col_main), name = NULL) +
  scale_x_continuous(labels = percent, limits = c(0, 0.28), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(title = "Brazil's biggest T-shirt supplier\npays no import duty",
       subtitle = paste0("Share of Brazil's T-shirt imports (HS 6109), Jan–Oct ", YEAR, ".\n",
                         "Imports reached US$", round(totals[year == YEAR]$fob_musd), "m FOB (",
                         percent(tot_growth, 1, style_positive = "plus"), " vs 2023).\n",
                         "Bangladesh is #3 and growing fast (", percent(bd_growth, 1, style_positive = "plus"),
                         ") despite the 35% tariff."),
       x = "Share of import value (FOB)", y = NULL, caption = src_cap) +
  theme_li() + theme(legend.position = "top", legend.justification = "left",
                     panel.grid.major.y = element_blank(),
                     axis.text.y = element_text(colour = ink, size = 11.5))
save_li(p1, "t1_suppliers.png")

# =============================================================================
# Figure 2: landed price per cotton T-shirt (CIF + import duty)
# =============================================================================
pick <- c("Peru", "Bangladesh", "China", "India", "Pakistan")
uv <- d[ncm == 61091000 & year == YEAR & country_en %in% pick,
        .(cif_u = sum(cif) / sum(units), tariff = tariff[1]), by = country_en]
uv[, duty_u := cif_u * tariff][, landed := cif_u + duty_u]
uv[, country_en := factor(country_en, uv[order(landed)]$country_en)]
uvl <- melt(uv, id.vars = c("country_en", "landed"), measure.vars = c("cif_u", "duty_u"),
            variable.name = "part", value.name = "usd")
uvl[, part := factor(part, c("duty_u", "cif_u"), c("Import duty (35% of CIF)", "CIF price at the border"))]
print(uv)

p2 <- ggplot(uvl, aes(usd, country_en, fill = part)) +
  geom_col(width = 0.62, colour = bg, linewidth = 0.6) +
  geom_text(data = uv, aes(landed, country_en, label = dollar(landed, 0.01)),
            inherit.aes = FALSE, hjust = -0.15, size = 4.4, fontface = "bold", colour = ink) +
  scale_fill_manual(values = c(col_2, col_main), name = NULL,
                    breaks = c("CIF price at the border", "Import duty (35% of CIF)")) +
  scale_x_continuous(labels = dollar, limits = c(0, 6.6), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(title = "Even after 35% duty, a Bangladeshi\ncotton T-shirt lands cheaper than Peru's",
       subtitle = paste0("Average price per cotton T-shirt (NCM 6109.10.00), Jan–Oct ", YEAR, ",\n",
                         "CIF value plus import duty. Peru enters duty-free under ACE 58.\n",
                         "Excludes IPI, PIS/COFINS and ICMS; product quality differs by origin."),
       x = "US$ per T-shirt", y = NULL, caption = src_cap) +
  theme_li() + theme(legend.position = "top", legend.justification = "left",
                     panel.grid.major.y = element_blank(),
                     axis.text.y = element_text(colour = ink, size = 11.5))
save_li(p2, "t2_landed_price.png")

# =============================================================================
# Calibrated nested-CES market
# =============================================================================
groups <- c("Peru", "Paraguay", "China", "Bangladesh", "Vietnam", "Pakistan", "India")
cal <- d[year == YEAR, .(cif = sum(cif), tariff = tariff[1]), by = country_en]
cal[, grp := fifelse(country_en %in% groups, country_en, "Others")]
cal <- cal[, .(cif = sum(cif), tariff = tariff[1]), by = grp]   # all 'Others' pay 35%
cal[, spend := cif * (1 + tariff)]                                # buyer spending incl. duty
cal[, s0 := spend / sum(spend)]
s0 <- setNames(cal$s0, cal$grp); t0 <- setNames(cal$tariff, cal$grp)
print(cal)

market <- function(t1, sigma = SIGMA, eta = ETA) {
  phat  <- (1 + t1) / (1 + t0)
  den   <- sum(s0 * phat^(1 - sigma))
  s1    <- s0 * phat^(1 - sigma) / den
  PMhat <- den^(1 / (1 - sigma))
  SM1   <- S_M0 * PMhat^(1 - eta) / (S_M0 * PMhat^(1 - eta) + 1 - S_M0)
  rec0  <- S_M0 * s0 / (1 + t0); rec1 <- SM1 * s1 / (1 + t1)   # customs value (CIF)
  data.table(grp = names(s0), rec_hat = rec1 / rec0, total_hat = sum(rec1) / sum(rec0))
}
set_t <- function(...) { t <- t0; x <- c(...); t[names(x)] <- x; t }

# ---- Figure 3: elasticity ladder --------------------------------------------
bd_share <- s0[["Bangladesh"]]
bd_el  <- -log(market(set_t(Bangladesh = (1 + CET) * 1.01 - 1))[grp == "Bangladesh"]$rec_hat) / log(1.01)
imp_el <- -log(market((1 + t0) * 1.01 - 1)$total_hat[1]) / log(1.01)
el <- data.table(
  label = c("σ  Elasticity of substitution\n(a very small supplier)",
            "Tariff elasticity\n(gravity estimate on customs data = −σ)",
            "θ = σ − 1  Trade elasticity\n(buyer spending incl. duty)",
            sprintf("Bangladesh's own demand elasticity\n(%.0f%% of spending on imported T-shirts)", 100 * bd_share),
            "Import demand elasticity\n(all suppliers' prices rise)"),
  value = c(SIGMA, SIGMA, SIGMA - 1, bd_el, imp_el))
el[, label := factor(label, rev(label))]
print(el)

p3 <- ggplot(el, aes(value, label)) +
  geom_col(fill = col_main, width = 0.62) +
  geom_text(aes(label = sprintf("−%.1f%%", value)), hjust = -0.15, size = 4.4,
            colour = ink, fontface = "bold") +
  scale_x_continuous(limits = c(0, 8), breaks = 0:8, expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(title = "If a T-shirt gets 1% dearer,\nhow much does trade fall?",
       subtitle = paste0("Four related elasticities, Brazil's T-shirt market.\n",
                         "One supplier faces σ; Brazil's total T-shirt imports\n",
                         "respond far less, because buyers can only switch to domestic."),
       x = "% fall in trade for a 1% rise in price (1 + tariff)", y = NULL, caption = sim_cap) +
  theme_li() + theme(panel.grid.major.y = element_blank(),
                     axis.text.y = element_text(colour = ink, size = 10.5, hjust = 0))
save_li(p3, "t3_elasticity_ladder.png")

# ---- Figure 4: scenarios (Bangladesh's tariff -> 0 in all) ------------------
sc <- rbindlist(list(
  market(set_t(Bangladesh = 0))[, scen := "FTA: Bangladesh only"],
  market(set_t(Bangladesh = 0, Vietnam = 0))[, scen := "FTA: Bangladesh and Vietnam"],
  market(set_t(Bangladesh = 0, India = 0, Pakistan = 0))[, scen := "FTA: Bangladesh, India, Pakistan"],
  market(t0 * 0)[, scen := "MFN cut: zero for everyone"]))
sc_bd <- sc[grp == "Bangladesh"][, pct := 100 * (rec_hat - 1)]
sc_bd[, scen := factor(scen, rev(scen))]
print(sc_bd); print(sc[grp == "Peru", .(scen, peru_pct = 100 * (rec_hat - 1))])

p4 <- ggplot(sc_bd, aes(pct, scen)) +
  geom_col(fill = col_main, width = 0.55) +
  geom_text(aes(label = sprintf("+%.0f%%", pct)), hjust = -0.15, size = 5,
            colour = ink, fontface = "bold") +
  scale_x_continuous(limits = c(0, ceiling(max(sc_bd$pct) / 100) * 100),
                     breaks = seq(0, 600, 200), labels = label_percent(scale = 1), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(title = "Zero tariff for Bangladeshi T-shirts:\nthe gain depends on the competitors",
       subtitle = paste0("Simulated change in Bangladesh's T-shirt exports to Brazil\n",
                         "when its 35% tariff falls to zero in every scenario.\n",
                         "With a margin of preference, Bangladesh wins share from every\n",
                         "rival (σ). A cut for everyone only helps against duty-free Peru\n",
                         "and domestic producers, so the gain is far smaller."),
       x = "Change in Bangladesh's T-shirt exports (customs value)", y = NULL,
       caption = sim_cap) +
  theme_li() + theme(panel.grid.major.y = element_blank(),
                     axis.text.y = element_text(colour = ink, size = 11, hjust = 0))
save_li(p4, "t4_scenarios.png")

# ---- Figure 5: sensitivity to sigma ----------------------------------------
sens <- rbindlist(lapply(sort(c(seq(3, 10, 0.25), SIGMA)), function(s)
  market(set_t(Bangladesh = 0), sigma = s)[grp == "Bangladesh", .(sigma = s, mult = rec_hat)]))
p5 <- ggplot(sens, aes(sigma, mult)) +
  geom_line(colour = col_main, linewidth = 1) +
  geom_point(data = sens[sigma %in% c(4, SIGMA, 10)], colour = col_main, size = 3) +
  geom_text(data = sens[sigma %in% c(4, SIGMA, 10)], aes(label = sprintf("×%.1f", mult)),
            vjust = -1.1, size = 4.2, colour = ink, fontface = "bold") +
  scale_x_continuous(breaks = 3:10) +
  scale_y_continuous(limits = c(0, max(sens$mult) * 1.12), labels = function(x) paste0("×", x)) +
  coord_cartesian(clip = "off") +
  labs(title = "The answer is only as good as σ",
       subtitle = paste0("Multiplier on Bangladesh's T-shirt exports to Brazil from a\n",
                         "Bangladesh-only FTA (35% → 0), by assumed σ.\n",
                         "Marked: CEPII's estimate for T-shirts, σ = ", sprintf("%.2f", SIGMA), "."),
       x = "Elasticity of substitution, σ", y = "Exports after / before", caption = sim_cap) +
  theme_li()
save_li(p5, "t5_sensitivity_sigma.png")

fwrite(cal, file.path(out_dir, "calibration_shares.csv"))
