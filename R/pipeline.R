# Verbindt input, throughput en output

run_pipeline <- function(verslagperiode, db_pad = DB_PAD, output_dir = OUTPUT_DIR) {
  # INPUT
  message("[input] CBS-tabel ", TABEL_ID, " ophalen ...")
  maand <- haal_cpi_maandcijfers()

  # THROUGHPUT
  message("[throughput] verslagperiode: ", verslagperiode)
  resultaat <- bereken_kwartaalmutatie(maand, verslagperiode)  # faalt hier, voordat er iets is weggeschreven
  kwartaal  <- bereken_kwartaalmutaties(maand)

  # OUTPUT
  paden <- maak_grafieken(kwartaal, verslagperiode, output_dir)
  schrijf_sqlite(maand, kwartaal, verslagperiode, db_pad)
  message("[output] database: ", db_pad)
  message("[output] grafieken: ", paste(paden, collapse = ", "))

  invisible(resultaat)
}
