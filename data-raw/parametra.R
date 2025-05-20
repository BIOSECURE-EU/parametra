library(readxl)
library(xlsx)
library(dplyr)
library(tidyr)

file<-"data-raw/parametra.xlsx"

sheet_names<-excel_sheets(path = file)

new_words<-c(`African Swine Fever`="African Swine Fever Virus",
             `African Swine Fever`="ASF",
             `Bovine Viral Diarrhoea Virus`="Bovine viral diarrhoea virus",
             `Bovine Viral Diarrhoea Virus`="Bovine Viral Diarrhoea Virus - Persistent infection",
             `Bovine Viral Diarrhoea Virus`="Bovine Viral Diarrhoea Virus - Transient infection",
             `Bovine Viral Diarrhoea Virus`="BVD",
             `Paratuberculosis`="Paratuberculosis \\(MAP\\)",
             `Paratuberculosis`="PTB",
             `Paratuberculosis`="Paratuberulosis",
             `Paratuberculosis`="Paratuberculosis \\(MAP\\)",
             `Foot and Mouth Disease`="FMDv",
             `Infectious Bovine Rhinotracheitis`="Infectious bovine rhinotracheitis",
             `Infectious Bovine Rhinotracheitis`="IBR",
             `E. coli`="E. coli \\(ETEC\\/STEC\\)",
             `E. coli`="E coli",
             `E. coli`="E coli ",
             `E. coli`="E.coli ",
             `E. coli`="E.coli",
             `PRRS`="PRRSv",
             `Peste des Petits Ruminants`="PPRV",
             `Peste des Petits Ruminants`="PPR",
             `Coxiella burnetii`="Coxiella Burnetti \\(q\\-fever\\)",
             `Coxiella burnetii`="Coxiella burnetti",
             `Bovine Respiratory Syncytial Virus`="BRSV",
             `Bovine Respiratory Syncytial Virus`="RSV",
             `Bovine Respiratory Syncytial Virus`="Bovine respiratory syncytial virus",
             `Bovine Respiratory Syncytial Virus`="Bovine Respiratory Syncytial Virus; BCoV",
             `Salmonella`="Salmonella Dublin",
             `Salmonella`="Salmonella ",
             `Swine Influenza`="Swine Influenza virus",
             `Swine Influenza`="Swine Influenza Virus",
             `Swine Influenza`="Swine Influneza",
             `Swine Influenza`="Swine Influenza \\(H1N1pmd09\\)",
             `Contagious agalactia`="Contagious agalactia \\(mycoplasma\\)",
             `Bovine Tuberculosis`="Tuberculosis \\(mycobacterium\\)",
             `Bovine Tuberculosis`="Bovine tuberculosis",
             `Campylobacter`="Campylobacter jejuni",
             `Campylobacter`="Campylobacter coli",

             #Parameters
             `Basic reproduction number`="Basic Reproduction number",
             `Within herd prevalence`="Within herd prevalence of persistently infected animals",
             `Within herd prevalence`="Within-herd prevalence of viremic animals",
             `Herd prevalence`="Herd Prevalence",
             `Incubation period`="Incubation peiod",
             `Incubation period`="Incubation peiod",
             `Specificity`="Specificty",
             `Probability of transmission via indirect contact`="Probability of infection via indirect contact",
             `Probability of transmission via direct contact`="Probability of infection via direct contact",
             `Ppathogen survival/Ddisinfection`="Pathogen survival/Disinfection",
             `Pathogen survival/Ddisinfection`="Pathogen survival",
             `Pathogen survival/Disinfection`="Disinfection",
             `Disinfection`="Ddisinfection",
             `Pathogen`="Ppathogen",
             `Pathogen survival/Disinfection`="Decay Rate \\(α\\)",
             `Pathogen survival/Disinfection`="Rate of decontamination \\(δ\\)",
             `Transmission on fomites`="Transmission on fomites in cold weather conditions",
             `Transmission on fomites`="Transmission in contaminated transport vehicle",
             `Shape`="Latent period shape",

             # Study types
             `Experimental Field` = "Experimental field",
             `Experimental Lab` = "Experimental lab",
             `Meta-analysis` = "Systematic review and meta-analysis",
             `SIR` = "SIR model",
             `SEIR` = "SEIR model",
             #Double space
             ` `="  ")

parametra_long<-data.frame()
file.remove("data-raw/parametra_long_new.xlsx")


for(i in 1:length(sheet_names)){

  #Read excel
  table <- read_xlsx(path = file, sheet = sheet_names[i])
  good_colnames<-names(table)

  #Replace new_words
  for(j in 1:length(new_words)){
    table<-type.convert(data.frame(lapply(table, function(x) {gsub(new_words[j], names(new_words)[j], x)})), as.is=TRUE)
    good_colnames<-unlist(lapply(good_colnames, function(x) {gsub(new_words[j], names(new_words)[j], x)}))
    names(table)<-good_colnames
  }

  #Remove empty rows
  table[rowSums(is.na(table)) != ncol(table), ]

  #Write table
  write.csv(table, file = paste0("data-raw/tables/parametra_long_",sheet_names[i],".csv"), row.names=FALSE)

  #Write excel file
  write.xlsx(table,"data-raw/parametra_long_new.xlsx",
             sheetName=sheet_names[i],
             col.names = TRUE,
             row.names=FALSE,
             showNA=FALSE,
             append=TRUE)

  #Joint table
  table$ParameterType<-sheet_names[i]
  parametra_long<-bind_rows(parametra_long,table)

  #Named individual table
  assign(sheet_names[i],table)
  do.call("use_data", list(as.name(sheet_names[i]), overwrite = TRUE))
}

#Remove empty rows
parametra_long<-parametra_long[rowSums(is.na(parametra_long)) != ncol(parametra_long),]
parametra_long<-parametra_long[!is.na(parametra_long$Pathogen),]
parametra_long$Parameter[is.na(parametra_long$Parameter)]<-"Other"

#Save parametra_long long
write.csv(parametra_long, file = paste0("data-raw/parametra_long.csv"))
usethis::use_data(parametra_long, overwrite = TRUE)
