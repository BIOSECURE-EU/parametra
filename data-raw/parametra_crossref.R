library(rcrossref)
library(dplyr)

dois_works <- rcrossref::cr_works(dois = unique(parametra_long$doi))

parametra_crossref<-purrr::pluck(dois_works$data)

first_authors <- NA
et_al<-NA
for(i in 1:nrow(parametra_crossref)) {
  authors_df <- parametra_crossref$author[[i]]
  first_i <- which(authors_df$sequence == "first")[1]
  if("family"%in%names(authors_df)&&!is.na(authors_df$family[first_i])) {
    first_authors[i] <- authors_df$family[first_i]
    et_al[i]<-!is.null(authors_df)&&nrow(authors_df)>1
  } else if("name"%in%names(authors_df)&&!is.na(authors_df$name[first_i])) {
    first_authors[i] <- authors_df$name[first_i]
    et_al[i]<-FALSE
  }
}

parametra_crossref <- parametra_crossref %>%
  mutate(first_author = first_authors,
         year = substr(issued, 1, 4),
         ref_short = paste0(first_author, ifelse(et_al," et al.",""),", ",year))

save(parametra_crossref, file="data-raw/parametra_crossref")

usethis::use_data(parametra_crossref, overwrite = TRUE)

parametra_crossref_flat <- parametra_crossref_flat %>%
  mutate(across(where(is.list), ~as.character(.)))

write.csv(parametra_crossref_flat, file = "data-raw/parametra_crossref.csv", row.names = FALSE)
