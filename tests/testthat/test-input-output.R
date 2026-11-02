test_that("maak_maandcijfers leest jaar, maand en status uit de CBS-periodecode", {
  ruw <- data.frame(
    product_code = "CPI072200",
    periode_code = c("2026MM08", "2026MM09"),
    cpi = c(122.27, 128.27)
  )
  uit <- maak_maandcijfers(ruw, PRODUCTEN, voorlopig_perioden = "2026MM09")
  expect_equal(uit$jaar, c(2026L, 2026L))
  expect_equal(uit$maand, c(8L, 9L))
  expect_equal(uit$voorlopig, c(FALSE, TRUE))
})

test_that("schrijf_sqlite is idempotent voor data en logt elke run", {
  maand <- maak_maand(c(100, 101, 102, 103, 104, 105))
  kwartaal <- bereken_kwartaalmutaties(maand)
  db <- tempfile(fileext = ".sqlite")

  schrijf_sqlite(maand, kwartaal, "2024Q2", db_pad = db)
  schrijf_sqlite(maand, kwartaal, "2024Q2", db_pad = db)

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  on.exit(DBI::dbDisconnect(con))
  expect_equal(DBI::dbGetQuery(con, "SELECT COUNT(*) n FROM cpi_maand")$n, 6)
  expect_equal(DBI::dbGetQuery(con, "SELECT COUNT(*) n FROM cpi_kwartaal")$n, 2)
  expect_equal(DBI::dbGetQuery(con, "SELECT COUNT(*) n FROM runs")$n, 2)
})
