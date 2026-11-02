for (bestand in c("config", "input", "throughput", "output")) {
  source(file.path("..", "..", "R", paste0(bestand, ".R")))
}

# Maandcijfers voor één product uit een vector indexcijfers, vanaf januari van start_jaar
maak_maand <- function(cpi, product_code = "A", start_jaar = 2024L, voorlopig = FALSE) {
  n <- length(cpi)
  idx <- seq_len(n) - 1L
  data.frame(
    product_code = product_code,
    product      = paste("Product", product_code),
    jaar         = start_jaar + idx %/% 12L,
    maand        = idx %% 12L + 1L,
    cpi          = cpi,
    voorlopig    = voorlopig,
    stringsAsFactors = FALSE
  )
}
