# Vanuit de projectmap:
#   Rscript main.R 2026Q3

for (bestand in c("config", "input", "throughput", "output", "pipeline")) {
  source(file.path("R", paste0(bestand, ".R")))
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Gebruik: Rscript main.R JJJJQk, bijvoorbeeld 2026Q3")
verslagperiode <- args[[1]]

resultaat <- run_pipeline(verslagperiode)

weergave <- data.frame(
  product     = resultaat$product,
  periode     = resultaat$periode,
  kwartaalindex = round(resultaat$cpi, 2),
  vorig_kwartaal = round(resultaat$cpi_vorig, 2),
  mutatie_pct = round(resultaat$mutatie_pct, 1),
  voorlopig   = resultaat$voorlopig
)
print(weergave, row.names = FALSE)
