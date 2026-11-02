test_that("kwartaalindex is het maandgemiddelde, mutatie de verandering t.o.v. vorig kwartaal", {
  a <- maak_maand(c(100, 101, 102, 103, 104, 105), "A")
  b <- maak_maand(c(200, 200, 200, 190, 190, 190), "B")
  maand <- rbind(a, b)

  kw <- bereken_kwartaalindex(maand)
  expect_equal(kw$cpi, c(101, 104, 200, 190))

  res <- bereken_kwartaalmutatie(maand, "2024Q2")
  expect_equal(res$mutatie_pct[res$product_code == "A"], (104 / 101 - 1) * 100)
  expect_equal(res$mutatie_pct[res$product_code == "B"], -5)
})

test_that("onvolledige kwartalen worden niet gebruikt", {
  # Q1 compleet, Q2 slechts twee maanden
  maand <- maak_maand(c(100, 101, 102, 103, 104))
  expect_equal(bereken_kwartaalindex(maand)$periode, "2024Q1")
  expect_error(bereken_kwartaalmutatie(maand, "2024Q2"), "Geen volledig kwartaal")
})

test_that("een maand zonder waarde maakt het kwartaal onvolledig", {
  maand <- maak_maand(c(100, 101, 102, 103, NA, 105))
  expect_error(bereken_kwartaalmutatie(maand, "2024Q2"), "Geen volledig kwartaal")
})

test_that("een product zonder de verslagperiode valt niet stilzwijgend weg", {
  maand <- rbind(maak_maand(101:109, "A"), maak_maand(201:206, "B"))
  expect_error(bereken_kwartaalmutatie(maand, "2024Q3"), "Geen volledig kwartaal.*: B")
})

test_that("een kwartaal is voorlopig zodra één maand dat is", {
  maand <- maak_maand(c(100, 101, 102, 103, 104, 105))
  maand$voorlopig[6] <- TRUE
  expect_equal(bereken_kwartaalindex(maand)$voorlopig, c(FALSE, TRUE))
})

test_that("een gat in de reeks wordt niet overbrugd", {
  # Q1 en Q3 aanwezig, Q2 ontbreekt: Q3 mag niet met Q1 vergeleken worden
  q1 <- maak_maand(c(100, 101, 102))
  q3 <- maak_maand(c(110, 111, 112))
  q3$maand <- q3$maand + 6L
  expect_error(bereken_kwartaalmutatie(rbind(q1, q3), "2024Q3"), "voorgaande kwartaal")
})

test_that("de jaarwisseling (Q4 -> Q1) werkt", {
  # Q4 2024 = 109, 110, 111 -> 110; Q1 2025 = 112, 113, 114 -> 113
  res <- bereken_kwartaalmutatie(maak_maand(100:114), "2025Q1")
  expect_equal(res$cpi_vorig, 110)
  expect_equal(res$mutatie_pct, (113 / 110 - 1) * 100)
})

test_that("ongeldige verslagperiode geeft een fout", {
  maand <- maak_maand(c(100, 101, 102, 103, 104, 105))
  expect_error(bereken_kwartaalmutatie(maand, "2024-Q2"), "formaat")
  expect_error(bereken_kwartaalmutatie(maand, "2024Q5"), "formaat")
  expect_error(bereken_kwartaalmutatie(maand, NA_character_), "formaat")
})
