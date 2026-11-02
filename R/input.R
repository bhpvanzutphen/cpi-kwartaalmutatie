# INPUT: maandcijfers rechtstreeks uit de CBS-API, geen csv/excel

# Maandelijkse CPI-indexcijfers voor de gekozen producten.
# Geeft een data.frame: product_code, product, jaar, maand, cpi, voorlopig
haal_cpi_maandcijfers <- function(tabel_id = TABEL_ID, producten = PRODUCTEN) {
  ruw <- cbsodataR::cbs_get_data(
    tabel_id,
    Bestedingscategorieen = names(producten),
    select = c("Bestedingscategorieen", "Perioden", INDEX_KOLOM)
  )

  # Voorlopig/definitief staat niet in de data maar in de metadata van Perioden
  perioden <- cbsodataR::cbs_get_meta(tabel_id)$Perioden
  voorlopig_perioden <- trimws(perioden$Key[perioden$Status == "Voorlopig"])

  # as.*() om de label-attributen van cbsodataR kwijt te raken
  df <- data.frame(
    product_code = trimws(as.character(ruw$Bestedingscategorieen)),
    periode_code = trimws(as.character(ruw$Perioden)),
    cpi          = as.numeric(ruw[[INDEX_KOLOM]]),
    stringsAsFactors = FALSE
  )

  # Jaarcijfers (JJ00) zitten ook in de tabel; die moeten eruit, anders klopt het kwartaalgemiddelde niet
  df <- df[grepl("^[0-9]{4}MM[0-9]{2}$", df$periode_code), , drop = FALSE]

  ontbreekt <- setdiff(names(producten), df$product_code)
  if (length(ontbreekt) > 0L) {
    stop("Geen maandcijfers van CBS voor: ", paste(ontbreekt, collapse = ", "))
  }

  maak_maandcijfers(df, producten, voorlopig_perioden)
}

# Ruwe CBS-rijen -> intern maandformaat. Los van de API-call, zodat testbaar
maak_maandcijfers <- function(df, producten, voorlopig_perioden = character()) {
  data.frame(
    product_code = df$product_code,
    product      = unname(producten[df$product_code]),
    jaar         = as.integer(substr(df$periode_code, 1, 4)),
    maand        = as.integer(substr(df$periode_code, 7, 8)),
    cpi          = df$cpi,
    voorlopig    = df$periode_code %in% voorlopig_perioden,
    stringsAsFactors = FALSE
  )
}
