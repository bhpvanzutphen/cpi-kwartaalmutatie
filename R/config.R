# Configuratie: alles wat je zou willen aanpassen staat hier

# CBS: "Consumentenprijzen; CPI 2025=100" (vanaf december 2009).
# Let op: vanaf 2026 publiceert CBS met basisjaar 2025=100 en een nieuwe
# productindeling. De oude 2015=100-tabel (83131NED) stopt na 2025, dus niet mengen
TABEL_ID <- "86141NED"

# Gekozen producten (CBS-code = naam, label = waarde).
# Beide op niveau 'klassen' (COICOP 4 cijfers, aangevuld met nullen); zie README
PRODUCTEN <- c(
  CPI072200 = "Brandstoffen en smeermiddelen",
  CPI041100 = "Werkelijke huur hoofdverblijf"
)

# Indexkolom: 'CPI' (incl. belastingen). Alternatief "CPIAfgeleid_2", zie README
INDEX_KOLOM <- "CPI_1"

# Output, relatief aan de projectmap
DB_PAD      <- file.path("output", "cpi.sqlite")
OUTPUT_DIR  <- "output"
