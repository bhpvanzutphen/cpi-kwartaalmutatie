# Eenmalig: installeert ontbrekende packages
pakketten <- c("cbsodataR", "DBI", "RSQLite", "ggplot2", "testthat")
ontbrekend <- setdiff(pakketten, rownames(installed.packages()))
if (length(ontbrekend) > 0) {
  install.packages(ontbrekend, repos = "https://cloud.r-project.org")
}
