# OUTPUT: grafieken en SQLite

# Schrijft twee PNG's en geeft de paden terug
maak_grafieken <- function(kwartaal, verslagperiode, output_dir = OUTPUT_DIR) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  # Eerste dag van het kwartaal als x-as
  kwartaal$datum <- as.Date(sprintf("%d-%02d-01", kwartaal$jaar, (kwartaal$kwartaal - 1L) * 3L + 1L))
  kwartaal$gekozen <- kwartaal$periode == verslagperiode
  mutaties <- kwartaal[!is.na(kwartaal$mutatie_pct), , drop = FALSE]

  p_mutatie <- ggplot2::ggplot(mutaties, ggplot2::aes(datum, mutatie_pct, fill = gekozen)) +
    ggplot2::geom_col(width = 70) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::facet_wrap(~product, ncol = 1, scales = "free_y") +
    ggplot2::scale_fill_manual(values = c(`FALSE` = "grey65", `TRUE` = "#c0392b"), guide = "none") +
    ggplot2::labs(
      title = "Kwartaalmutatie consumentenprijsindex",
      subtitle = paste0("Procentuele verandering t.o.v. voorgaand kwartaal; verslagperiode ", verslagperiode, " in rood"),
      x = NULL, y = "%", caption = paste0("Bron: CBS, tabel ", TABEL_ID)
    ) +
    ggplot2::theme_minimal(base_size = 11)

  p_index <- ggplot2::ggplot(kwartaal, ggplot2::aes(datum, cpi, colour = product)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_colour_manual(values = c("#2c3e50", "#c0392b")) +
    ggplot2::labs(
      title = "Kwartaalindex consumentenprijzen",
      subtitle = "Gemiddelde van de drie maandindexcijfers (2025=100)",
      x = NULL, y = "Index (2025=100)", colour = NULL,
      caption = paste0("Bron: CBS, tabel ", TABEL_ID)
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")

  paden <- c(
    mutatie = file.path(output_dir, "kwartaalmutatie.png"),
    index   = file.path(output_dir, "kwartaalindex.png")
  )
  ggplot2::ggsave(paden[["mutatie"]], p_mutatie, width = 8, height = 6, dpi = 150)
  ggplot2::ggsave(paden[["index"]],   p_index,   width = 8, height = 4, dpi = 150)
  paden
}

# Schrijf maand- en kwartaalcijfers plus een run-log naar SQLite.
#
# cpi_maand en cpi_kwartaal worden elke run vervangen, dus twee keer draaien
# geeft dezelfde inhoud. 'runs' is een logboek met per run een rij (tijdstip,
# tabel, verslagperiode). Alles in één transactie: bij een fout blijft de
# database zoals hij was
schrijf_sqlite <- function(maand, kwartaal, verslagperiode, db_pad = DB_PAD,
                           tabel_id = TABEL_ID, opgehaald_op = Sys.time()) {
  dir.create(dirname(db_pad), showWarnings = FALSE, recursive = TRUE)

  con <- DBI::dbConnect(RSQLite::SQLite(), db_pad)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  kwartaal_uit <- kwartaal[, c("product_code", "product", "periode", "jaar", "kwartaal",
                               "cpi", "cpi_vorig", "mutatie_pct", "voorlopig")]
  run <- data.frame(
    opgehaald_op   = format(opgehaald_op, "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    tabel_id       = tabel_id,
    verslagperiode = verslagperiode,
    stringsAsFactors = FALSE
  )

  DBI::dbWithTransaction(con, {
    DBI::dbWriteTable(con, "cpi_maand",    maand,        overwrite = TRUE)
    DBI::dbWriteTable(con, "cpi_kwartaal", kwartaal_uit, overwrite = TRUE)
    DBI::dbWriteTable(con, "runs",         run,          append = TRUE)
  })
  invisible(db_pad)
}
