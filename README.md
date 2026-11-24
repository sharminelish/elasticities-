# Four elasticities, one tariff wall: Bangladeshi T-shirts in Brazil (HS 6109)

How much would Bangladesh's T-shirt exports to Brazil respond if MERCOSUR's 35% tariff were removed? The answer depends on which elasticity you use. This folder:

1. describes Brazil's T-shirt imports (HS 6109) with official Comex Stat data;
2. calibrates a simple Armington (nested CES) model to that market, using a product-level elasticity of substitution from CEPII;
3. shows how four commonly confused elasticities relate to each other: σ, θ, the tariff elasticity and the import demand elasticity;
4. runs a Monte Carlo experiment showing that a gravity regression on customs data recovers −σ, while one on buyer spending recovers −θ = −(σ − 1).

The figures are sized for LinkedIn (1080 × 1350 px).

---

## Key results (January–October 2025)

| | Value |
|---|---|
| Brazil's T-shirt imports (HS 6109), FOB | US$182m (+58% vs Jan–Oct 2023) |
| Largest supplier | Peru, 23.8%: **duty-free** under ACE 58 |
| Bangladesh | #3, 16.2% share, **+80%** since 2023, pays the **35%** CET |
| Cotton T-shirt (6109.10.00), Bangladesh | US$3.32 CIF → **US$4.48** with duty |
| Cotton T-shirt (6109.10.00), Peru | **US$5.00** CIF, no duty |
| σ, elasticity of substitution (HS 6109, CEPII) | **7.28** |
| θ = σ − 1, trade elasticity | 6.28 |
| Bangladesh's own demand elasticity in Brazil | 6.6 |
| Brazil's import demand elasticity for T-shirts | 3.2 |

**Simulated change in Bangladesh's T-shirt exports to Brazil when its tariff falls from 35% to 0:**

| Scenario | Change |
|---|---|
| Bangladesh only | +464% |
| Bangladesh and Vietnam | +393% |
| Bangladesh, India and Pakistan | +399% |
| Zero tariff for every supplier (MFN cut) | +178% |

These are **partial-equilibrium upper bounds**, not forecasts (see *Limitations*).

---

## Files

| File | What it does |
|---|---|
| `run_all.R` | Installs missing packages and runs both scripts below |
| `tshirt_6109_analysis.R` | Reads the data, computes descriptives, calibrates the model, writes figures t1–t5 |
| `monte_carlo_6109.R` | Simulates 200 gravity panels and estimates PPML on two valuations, writes figure t6 |
| `brazil_6109_import_shares.csv` | Comex Stat export: Brazil's imports of HS 6109 by country and NCM, Jan–Oct 2023–2025 |
| `final_tariff_HS4.dta` | CEPII ProTEE trade elasticities at HS4 level |
| `figures/` | Output charts and `calibration_shares.csv` |

### Figures

| File | Content | Type |
|---|---|---|
| `t1_suppliers.png` | Import shares by country, duty-free vs 35% CET | Data |
| `t2_landed_price.png` | Price per cotton T-shirt: CIF + import duty | Data |
| `t3_elasticity_ladder.png` | The four elasticities side by side | Model |
| `t4_scenarios.png` | Bangladesh's export gain under four tariff scenarios | Model |
| `t5_sensitivity_sigma.png` | Bangladesh-only FTA result for σ from 3 to 10 | Model |
| `t6_monte_carlo.png` | Gravity estimates on customs value vs buyer spending | Simulation |

---

## Data sources

| Input | Source | How to obtain |
|---|---|---|
| Import values, freight, insurance, units by country and NCM | **Comex Stat**, MDIC/SECEX | comexstat.mdic.gov.br → Importação → 2023–2025, Jan–Oct → filter SH4 = 6109 → detail Year, Country, NCM → values US$ FOB, freight, insurance, CIF, net kg, statistical quantity → export CSV |
| Elasticity of substitution σ | **CEPII ProTEE**, HS4 file. Fontagné, L., Guimbard, H. and Orefice, G. (2022), "Product-Level Trade Elasticities", *Journal of International Economics*, 137 | cepii.fr → Databases → Product Level Trade Elasticities. Licence: Etalab 2.0 |
| Import share of apparel consumption (18.6%, 2025, constant prices) | **CNI**, *Coeficientes de Abertura Comercial*, nº 1/2026 | portaldaindustria.com.br → Estatísticas → Coeficientes de Abertura Comercial |
| 35% tariff on 6109.10.00 and 6109.90.00, no exceptions | **TEC** and Annexes I–X, updated to Gecex Resolution nº 969/2026 | MDIC/CAMEX, Tarifa Externa Comum |
| Peru duty-free | **ACE 58** (MERCOSUR–Peru): all bilateral trade with Brazil duty-free except 12 tariff codes | Siscomex, Acordos comerciais |

---

## Method

### 1. The four elasticities

| Symbol | Name | Measures | Relation |
|---|---|---|---|
| σ | Elasticity of substitution | How easily buyers switch between supplier countries | Parameter |
| — | Tariff elasticity | Coefficient on ln(1 + t) in a gravity regression | = −σ on customs data (excl. duty) |
| θ | Trade elasticity | Response of buyer spending (incl. duty) to trade costs | θ = σ − 1 |
| — | Import demand elasticity | Response of total imports when all suppliers' prices rise | Much smaller than σ |

Why θ = σ − 1: when the tariff falls by 1%, the quantity bought rises by σ%. The customs value (quantity × exporter price) therefore rises by σ%. Buyer spending (quantity × duty-inclusive price) rises by only σ − 1, because each unit is also 1% cheaper.

CEPII defines its trade elasticity as the tariff elasticity, which is minus the elasticity of substitution across origins. So σ = −(ProTEE value) = 7.28 for HS 6109.

### 2. Nested CES market (partial equilibrium)

Brazilian buyers choose between domestic and imported T-shirts (elasticity η), and among import origins k (elasticity σ). Exporter prices and total spending are held fixed. A tariff change moves the buyer price of origin k by

$$\hat p_k = \frac{1 + t_k^{1}}{1 + t_k^{0}}$$

New shares within imports and the change in the import price index:

$$s_k^{1} = \frac{s_k^{0}\,\hat p_k^{\,1-\sigma}}{\sum_m s_m^{0}\,\hat p_m^{\,1-\sigma}}, \qquad \hat P_M = \Big(\sum_m s_m^{0}\,\hat p_m^{\,1-\sigma}\Big)^{\frac{1}{1-\sigma}}$$

New import share of total spending:

$$S_M^{1} = \frac{S_M^{0}\,\hat P_M^{\,1-\eta}}{S_M^{0}\,\hat P_M^{\,1-\eta} + 1 - S_M^{0}}$$

Customs value of origin k is proportional to $S_M\,s_k / (1 + t_k)$.

**Calibration.** The within-import shares $s_k^0$ are buyer spending shares, CIF × (1 + t), for Jan–Oct 2025. The origins are Peru, Paraguay (0%), China, Bangladesh, Vietnam, Pakistan, India and Others (35%). $S_M^0$ = 18.6% (CNI). σ = 7.28 (CEPII). η = σ/2 (**assumption**).

### 3. Monte Carlo

Each of 200 simulated panels has 40 countries × 8 years, with random tariffs (about half of pairs liberalise at a random year) and multiplicative gamma noise. Buyer spending is generated as $X^{incl} = e^{FE}(1+t)^{1-\sigma}\varepsilon$, and the customs value as $X^{rec} = X^{incl}/(1+t)$. Both are estimated by PPML (`fixest::fepois`) with exporter-year, importer-year and pair fixed effects.

Result with σ = 7.28: the mean coefficient is −7.29 on customs values and −6.28 on buyer spending.

---

## How to run

Requires R (4.x). From R or RStudio:

```r
setwd("E:/elasticities")   # or wherever you downloaded this folder
source("run_all.R")
```

`run_all.R` installs any missing packages (`data.table`, `ggplot2`, `scales`, `haven`, `fixest`), checks that the two input files are present, and writes figures t1–t6 to `figures/`. The T-shirt analysis takes a few seconds; the Monte Carlo takes about 30 seconds to 3 minutes.

To change a parameter, edit the top of `tshirt_6109_analysis.R`: `S_M0` (import share), `ETA` (η), `CET` (tariff) or `YEAR`. σ is read from the CEPII file.

Note: the Comex Stat CSV export contains stray carriage returns inside quoted fields. The script removes them before parsing.

---

## Limitations

- **Partial equilibrium.** Exporter prices, Brazil's total T-shirt spending and Bangladesh's production capacity are fixed. There are no general-equilibrium, exchange-rate or supply-side effects.
- **Full pass-through.** The model assumes the whole tariff cut reaches the buyer. If exporters raise prices, the response is smaller.
- **Rules of origin and preference use** are ignored. A real FTA would need Bangladeshi T-shirts to qualify as originating.
- **η is assumed** (σ/2). It mainly affects the import demand elasticity and the MFN scenario.
- **Import share is a proxy.** The CNI figure covers all apparel (CNAE 14), at constant prices, not T-shirts alone. At 15% instead of 18.6%, the Bangladesh-only result changes from +464% to +470%.
- **Coverage.** Comex Stat may not capture all small-parcel e-commerce imports.
- **Unit prices** compare averages; product quality and mix differ by origin (e.g. Peruvian premium cotton).
- **Only the import duty** is counted. IPI, PIS/COFINS and ICMS are excluded.
- **HS revision.** CEPII elasticities are estimated on HS 2007; HS 6109 is unchanged in scope.

---

## Author

Elish Sharmin, working on trade between Bangladesh and Latin America.
GitHub: [sharminelish](https://github.com/sharminelish)

Views and calculations are the author's own. Please cite the data sources above when reusing the figures.
