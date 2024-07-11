library(readxl)
library(dplyr)
library(tidyr)

file<-"data/parametra.xlsx"

sheet_names<-excel_sheets(path = file)


new_words<-c(`African Swine Fever`="African Swine Fever Virus",
             `African Swine Fever`="ASF",
             `Swine Influenza`="Swine Influenza Virus",
             `Swine Influenza`="Swine Influneza",
             `Swine Influenza`="Swine Influneza",
             `Swine Influenza`="Swine Influenza Virus (H1N1pmd09)",
             `Bovine Viral Diarrhoea Virus`="Bovine viral diarrhoea virus",
             `Bovine Viral Diarrhoea Virus`="Bovine Viral Diarrhoea Virus - Persistent infection",
             `Bovine Viral Diarrhoea Virus`="Bovine Viral diarrhoea virus - Transient infection",
             `Bovine Viral Diarrhoea Virus`="BVD",
             `Paratuberculosis`="Paratuberculosis (MAP)",
             `Paratuberculosis`="PTB",
             `Foot and Mouth Disease`="FMDv",
             `Infectious Bovine Rhinotracheitis`="Infectious bovine rhinotracheitis",
             `Infectious Bovine Rhinotracheitis`="IBR",
             `E. coli`="E coli",
             `E. coli`="E coli ",
             `E. coli`="E.coli ",
             `PRRS`="PRRSv",
             `Salmonella`="Salmonella ",
             `Swine Influenza Virus`="Swine Influenza Virus (H1N1pmd09)")

parametra<-data.frame()

for(i in 1:length(sheet_names)){
  
  #Read excel
  csv <- read_xlsx(path = file, sheet = sheet_names[i])
  
  good_colnames<-names(csv)
  
  #Replace new_words
  for(j in 1:length(new_words)){
    csv<-type.convert(data.frame(lapply(csv, function(x) {gsub(new_words[j], names(new_words)[j], x)})), as.is=TRUE)
    good_colnames<-unlist(lapply(good_colnames, function(x) {gsub(new_words[j], names(new_words)[j], x)}))
    names(csv)<-good_colnames
  }
  
  #Save csv in data directory
  write.csv(csv, file = paste0("data/parametra_",sheet_names[i],".csv"))
  
  #Joint table
  csv$ParameterType<-sheet_names[i]
  parametra<-bind_rows(parametra,csv)
  
  #Named individual table
  assign(sheet_names[i],csv)
  
}

parametra%>%
  group_by(Pathogen, Parameter)%>%
  summarise(n = n())

unique(parametra$Pathogen)
unique(parametra$Parameter)

matrix<-tidyr::pivot_wider(data=data[data[[by_y]]%in%list_top&!is.na(data[measure]),],
                           id_cols=all_of(by_y),names_from=all_of(by_x),values_from=all_of(measure))