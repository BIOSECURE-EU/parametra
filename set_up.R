library(readxl)
library(xlsx)
library(dplyr)
library(tidyr)

file<-"data/parametra.xlsx"

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

parametra<-data.frame()
file.remove("data/parametra_new.xlsx")

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
  
  #Remove empty rows
  csv[rowSums(is.na(csv)) != ncol(csv), ]
  
  #Write csv
  write.csv(csv, file = paste0("data/parametra_",sheet_names[i],".csv"), row.names=FALSE)

  #Write excel file
  write.xlsx(csv,"data/parametra_new.xlsx",
             sheetName=sheet_names[i],
             col.names = TRUE,
             row.names=FALSE,
             showNA=FALSE,
             append=TRUE) 
  
  #Joint table
  csv$ParameterType<-sheet_names[i]
  parametra<-bind_rows(parametra,csv)
  
  #Named individual table
  assign(sheet_names[i],csv)
  
}

#Remove empty rows
parametra<-parametra[rowSums(is.na(parametra)) != ncol(parametra),]
parametra<-parametra[!is.na(parametra$Pathogen),]
parametra$Parameter[is.na(parametra$Parameter)]<-"Other"

#Save parametra long
write.csv(parametra, file = paste0("data/parametra_long.csv"))