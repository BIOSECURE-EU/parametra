library(rcrossref)
library(dplyr)

dois_works <- rcrossref::cr_works(dois = unique(parametra_long$doi))

parametra_crossref<-purrr::pluck(dois_works$data)

save(parametra_crossref, file="data-raw/parametra_crossref")

usethis::use_data(parametra_crossref, overwrite = TRUE)

parametra_crossref <- parametra_crossref %>%
  mutate(across(where(is.list), ~as.character(.)))

write.csv(parametra_crossref, file = "data-raw/parametra_crossref.csv", row.names = FALSE)

names(parametra_crossref)
