library(rcrossref)
dois<-unique(parametra_long$doi)
dois_works <- rcrossref::cr_works(dois=dois)
dois_works<-ref_dois

crossref_data<-purrr::pluck(dois_works$data)
save(crossref_data, file="crossref_data")
