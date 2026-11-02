# THROUGHPUT: van maandcijfers naar kwartaalmutatie.
# Pure functies (geen netwerk, geen bestanden), dus makkelijk te testen.
#
# Volgorde, per product:
#   1. maand -> kwartaal
#   2. kwartaalindex = gemiddelde van de drie maanden    bereken_kwartaalindex()
#   3. vorig kwartaal koppelen, mutatie in %             bereken_kwartaalmutaties()
#   4. één verslagperiode kiezen en controleren          bereken_kwartaalmutatie()
# De functies bouwen op elkaar voort; bereken_kwartaalmutatie() is het eindpunt.

# Stap 1-2: kwartaalindex = gemiddelde van de drie maandindexcijfers.
# Onvolledige kwartalen vallen af: een gemiddelde over twee maanden is een ander getal
bereken_kwartaalindex <- function(maand) {
  # 1. maand -> kwartaal
  maand$kwartaal <- (maand$maand - 1L) %/% 3L + 1L
  sleutel <- interaction(maand$product_code, maand$jaar, maand$kwartaal, drop = TRUE)

  # 2. gemiddelde per product en kwartaal
  kw <- do.call(rbind, lapply(split(maand, sleutel), function(g) {
    data.frame(
      product_code = g$product_code[1],
      product      = g$product[1],
      jaar         = g$jaar[1],
      kwartaal     = g$kwartaal[1],
      n_maanden    = length(unique(g$maand[!is.na(g$cpi)])),  # maand zonder waarde telt niet
      cpi          = mean(g$cpi),
      voorlopig    = any(g$voorlopig),
      stringsAsFactors = FALSE
    )
  }))

  # alleen volledige kwartalen
  kw <- kw[kw$n_maanden == 3L, , drop = FALSE]
  kw$periode     <- sprintf("%dQ%d", kw$jaar, kw$kwartaal)
  kw$kwartaal_nr <- kw$jaar * 4L + kw$kwartaal - 1L   # doorlopende teller
  kw <- kw[order(kw$product_code, kw$kwartaal_nr), ]
  rownames(kw) <- NULL
  kw
}

# Stap 3: mutatie (%) t.o.v. het voorgaande kwartaal, voor alle kwartalen
bereken_kwartaalmutaties <- function(maand) {
  kw <- bereken_kwartaalindex(maand)

  # Vorig kwartaal via kwartaal_nr + 1 koppelen, niet via 'de rij erboven':
  # een gat in de reeks geeft dan NA in plaats van een vergelijking over twee kwartalen
  vorig <- data.frame(
    product_code = kw$product_code,
    kwartaal_nr  = kw$kwartaal_nr + 1L,
    cpi_vorig    = kw$cpi,
    stringsAsFactors = FALSE
  )
  uit <- merge(kw, vorig, by = c("product_code", "kwartaal_nr"), all.x = TRUE)
  # mutatie = (index t / index t-1 - 1) * 100
  uit$mutatie_pct <- (uit$cpi / uit$cpi_vorig - 1) * 100
  uit <- uit[order(uit$product_code, uit$kwartaal_nr), ]
  rownames(uit) <- NULL
  uit
}

# Stap 4: kwartaalmutatie voor één verslagperiode.
#
# Stopt met een foutmelding (geen NA) als het kwartaal of het voorgaande
# kwartaal ontbreekt of onvolledig is.
#
# maand:          maandcijfers, zie haal_cpi_maandcijfers()
# verslagperiode: "JJJJQk", bijvoorbeeld "2026Q3"
# Geeft een data.frame met één rij per product
bereken_kwartaalmutatie <- function(maand, verslagperiode) {
  if (!is.character(verslagperiode) || length(verslagperiode) != 1L ||
      !grepl("^[0-9]{4}Q[1-4]$", verslagperiode)) {
    stop("verslagperiode moet het formaat 'JJJJQk' hebben, bijvoorbeeld '2026Q3'.")
  }

  res <- bereken_kwartaalmutaties(maand)
  res <- res[res$periode == verslagperiode, , drop = FALSE]

  # Per product controleren: anders valt een product zonder melding uit het resultaat
  ontbreekt <- setdiff(maand$product_code, res$product_code)
  if (length(ontbreekt) > 0L) {
    stop("Geen volledig kwartaal (3 maanden) beschikbaar voor ", verslagperiode,
         ": ", paste(ontbreekt, collapse = ", "), ".")
  }
  if (anyNA(res$mutatie_pct)) {
    stop("Het voorgaande kwartaal ontbreekt of is onvolledig voor ", verslagperiode, ".")
  }
  rownames(res) <- NULL
  res
}
