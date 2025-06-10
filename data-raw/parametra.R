library(readxl)
library(xlsx)
library(dplyr)
library(tidyr)

# Dictionary for standardizing terms
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
             `Pathogen survival/Disinfection`="Decay Rate \\(α\\)",
             `Pathogen survival/Disinfection`="Rate of decontamination \\(δ\\)",
             `Transmission on fomites`="Transmission on fomites in cold weather conditions",
             `Transmission on fomites`="Transmission in contaminated transport vehicle",
             `Shape`="Latent period shape",

             # Study types
             `Experimental Field` = "Experimental field",
             `Experimental Lab` = "Experimental lab",
             `Meta-analysis` = "Systematic review and meta-analysis",

             # Models - Simple Dynamics
             `SIR` = "SIR model",
             `SEIR` = "SEIR model",
             `SIR/SEIR` = "SIR\\/SEIR model",
             `SIR` = "1R-SIR",
             `SIR` = "2R-SIR",
             `SLIR` = "SLRI",
             `SLIR` = "SLI-SC",
             `SIS` = "SI\\/SIS",
             `SI` = "SI model",

             # Models - Complex Dynamics
             `SEIR` = "SEIR model",
             `SLICE` = "SLI\\/SLIE\\/SLICE",

             # Models - Statistical Methods
             `Time Series` = "Time series data and generation time",
             `Bayesian` = "Bayesian analysis",
             `Bayesian` = "Bayesian hierarchical model",
             `Stochastic` = "Stochastic herd level simulation",
             `Stochastic` = "Stochastic mathematical model",

             # Models - Growth and Transmission Patterns
             `Exponential Growth` = "Exponential growth rate",
             `Doubling Time` = "Doubling time",
             `Doubling Time` = "Epidemic doubling time",
             `Network Analysis` = "Transmission network analysis",
             `Nearest Neighbor` = "Nearest infectious neighbour",
             `Nearest Neighbor` = "Nearest infectious neighbour \\(Euclidean distance\\)",
             `Nearest Neighbor` = "Nearest infectious neighbour \\(road distance\\)",

             # Models - Advanced Models
             `Phylodynamic` = "Time-rooted phylodynamic evolutionary model",
             `Markov Chain` = "Continuous Markov Chain Model",
             `Multiscale` = "Multiscale model",
             `Seasonal Matrix` = "Seasonal matrix population model",

             # Models - Other
             `Final Size` = "Final size",
             `Descriptive` = "None \\(descriptive\\)",
             `Annual Rate` = "\\/year",

             #Double space
             ` `="  ")

clean_parametra<-function(file, new_words){
  # Read excel file
  sheet_names <- excel_sheets(path = file)
  parametra_long <- data.frame()

  for(i in 1:length(sheet_names)) {
    # Skip documentation sheets when processing
    if(sheet_names[i] %in% c("ChangesLog", "LOT", "Endemic_Pathogens", "Epidemic_Pathogens", "AMR_Pathogens", "Crosref")) {
      next
    }
    # Read excel sheet
    table <- read_xlsx(path = file, sheet = sheet_names[i])

    # Remove row names
    rownames(table)<-NULL

    # Check required columns
    required_cols <- c("pathogen", "parameter", "value", "ref")
    missing_cols <- required_cols[!required_cols %in% names(table)]

    # Replace terms using dictionary
    good_colnames <- names(table)

    # Print summary of replacements
    replacements_made <- sapply(new_words, function(x) {
      sum(grepl(x, table, fixed = TRUE))
    })

    for(j in 1:length(new_words)) {
      table <- type.convert(data.frame(lapply(table, function(x) {
        gsub(new_words[j], names(new_words)[j], x)
      })), as.is = TRUE)
      good_colnames <- unlist(lapply(good_colnames, function(x) {
        gsub(new_words[j], names(new_words)[j], x)
      }))
      names(table) <- good_colnames
    }

    if(sum(replacements_made) > 0) {
      message(sum(replacements_made>0)," terms standardized in sheet '", sheet_names[i], "':")
      for(k in 1:length(replacements_made)) {
        if(replacements_made[k] > 0) {
          message("  - Replaced '",new_words[k], "' with '", names(replacements_made)[k],
                  "' (in ", replacements_made[k], " columns)")
        }
      }
    }

    # Remove empty rows
    table <- table[rowSums(is.na(table)) != ncol(table), ]

    # Check for missing values in critical columns
    missing_values <- sapply(required_cols, function(col) sum(is.na(table[[col]])))
    if(any(missing_values > 0)) {
      warning(sprintf("Sheet '%s' has missing values: %s",
                      sheet_names[i],
                      paste(sprintf("%s: %d", names(missing_values), missing_values),
                            collapse = ", ")))
    }

    # Write individual sheet data
    write.csv(table,
              file = paste0("data-raw/tables/parametra_", sheet_names[i], ".csv"),
              row.names = FALSE)

    # Add sheet identifier and combine
    table$parameter_type <- sheet_names[i]
    table$id <- paste0(table$parameter_type,"_",1:nrow(table))

    parametra_long <- bind_rows(parametra_long, table)

    # Create individual dataset
    assign(sheet_names[i], table)
    do.call("use_data", list(as.name(sheet_names[i]), overwrite = TRUE))
  }

  # Remove all-empty rows
  parametra_long <- parametra_long[rowSums(is.na(parametra_long)) != ncol(parametra_long), ]
  # Remove rows with now pathogen
  parametra_long <- parametra_long[!is.na(parametra_long$pathogen), ]
  # Add "Other" when Parameter is not specified
  parametra_long$parameter[is.na(parametra_long$parameter)] <- "Other"

  # Save final dataset
  write.csv(parametra_long, file = "data-raw/parametra_long.csv", row.names = FALSE)
  usethis::use_data(parametra_long, overwrite = TRUE)
}

clean_parametra("data-raw/parametra.xlsx", new_words)
