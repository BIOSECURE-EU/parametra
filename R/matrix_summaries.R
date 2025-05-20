library(dplyr)
library(tidyr)

parametra_long<-read.csv("data/parametra_long.csv")

#### Parameter availability matrix ####
parameters<-parametra%>% 
  filter(!grepl(";", Pathogen))%>%  #Filter for only individual pathogens
  group_by(Pathogen, Parameter)%>%
  summarise(n = n())%>%
  arrange(desc(n))


matrix<-tidyr::pivot_wider(data=parameters[!is.na(parameters$n),],
                           id_cols=Pathogen,
                           names_from=Parameter,
                           values_from=n)


matrix_df<-as.data.frame(matrix)


write.csv(matrix_df, file = "outputs/parameters_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Pathogen
matrix$Pathogen<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0


heatmap(matrix, Colv = NA, Rowv = NA)

#### Parameters by study ####

parameter_study_type<-parametra%>% 
  filter(!grepl(";", Parameter))%>%  #Filter for only individual Parameters
  group_by(Parameter, Study)%>%
  summarise(n = n())%>%
  arrange(desc(n))


matrix<-tidyr::pivot_wider(data=parameter_study_type[!is.na(parameter_study_type$n),],
                           id_cols=Parameter,
                           names_from=Study,
                           values_from=n)


matrix_df<-as.data.frame(matrix)

write.csv(matrix_df, file = "outputs/parameter_study_type_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Parameter
matrix$Parameter<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0


heatmap(matrix, Colv = NA, Rowv = NA)



#### Study type matrix ####

pathogen_study_type<-parametra%>% 
  filter(!grepl(";", Pathogen))%>%  #Filter for only individual pathogens
  group_by(Pathogen, Study)%>%
  summarise(n = n())%>%
  arrange(desc(n))


matrix<-tidyr::pivot_wider(data=pathogen_study_type[!is.na(pathogen_study_type$n),],
                           id_cols=Pathogen,
                           names_from=Study,
                           values_from=n)


matrix_df<-as.data.frame(matrix)

write.csv(matrix_df, file = "outputs/pathogen_study_type_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Pathogen
matrix$Pathogen<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0


heatmap(matrix, Colv = NA, Rowv = NA)



#### Year of publishing ####
study_year<-parametra%>%
  mutate(Year = as.numeric(stringr::str_extract_all(Reference, "\\b\\d{4}\\b")))%>%
  filter(!grepl(";", Pathogen))%>%  #Filter for only individual pathogens
  group_by(Pathogen, Year)%>%
  summarise(n = n())%>%
  arrange(Year, desc(n))


matrix<-tidyr::pivot_wider(data=study_year[!is.na(study_year$n),],
                           id_cols=Pathogen,
                           names_from=Year,
                           values_from=n)


matrix_df<-as.data.frame(matrix)

write.csv(matrix_df, file = "outputs/study_year_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Pathogen
matrix$Pathogen<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0


heatmap(matrix, Colv = NA, Rowv = NA)

#### Model type ####
model_type<-parametra%>%
  mutate(Model=`Type of infectious disease model`)%>%
  filter(!grepl(";", Pathogen),  #Filter for only individual pathogens
         !is.na(Model))%>% 
  group_by(Pathogen, Model)%>%
  summarise(n = n())%>%
  arrange(desc(n))

# Map model names
model_mapping <- c(
  # Simple Dynamics
  "SIR model" = "SIR",
  "SIR" = "SIR",
  "SIR/SEIR model" = "SIR/SEIR",
  "1R-SIR" = "SIR",
  "2R-SIR" = "SIR",
  "SLIR" = "SLIR",
  "SLRI" = "SLIR",
  "SLI" = "SLIR",
  "SLI-SC" = "SLIR",
  "SIS" = "SIS",
  "SI/SIS" = "SIS",
  "SIRS" = "SIRS",
  "SI" = "SI",
  "SI model" = "SI",
  "Si" = "SI",
  
  # Complex Dynamics
  "SEIR model" = "SEIR",
  "SEIR" = "SEIR",
  "SOEI" = "SOEI",
  "SLI/SLIE/SLICE" = "SLICE",
  "SLICE" = "SLICE",
  "SUD" = "SUD",
  
  # Statistical Methods
  "GLM" = "GLM",
  "Time series data and generation time" = "Time Series",
  "Bayesian analysis" = "Bayesian",
  "Bayesian hierarchical model" = "Bayesian",
  "Stochastic herd level simulation" = "Stochastic",
  "Stochastic mathematical model" = "Stochastic",
  
  # Growth and Transmission Patterns
  "Exponential growth rate" = "Exponential Growth",
  "Doubling time" = "Doubling Time",
  "Epidemic doubling time" = "Doubling Time",
  "Transmission network analysis" = "Network Analysis",
  "Nearest infectious neighbour" = "Nearest Neighbor",
  "Nearest infectious neighbour (Euclidean distance)" = "Nearest Neighbor",
  "Nearest infectious neighbour (road distance)" = "Nearest Neighbor",
  
  # Advanced Models
  "Time-rooted phylodynamic evolutionary model" = "Phylodynamic",
  "Continuous Markov Chain Model" = "Markov Chain",
  "Multiscale model" = "Multiscale",
  "Seasonal matrix population model" = "Seasonal Matrix",
  
  # Other
  "Final size" = "Final Size",
  "FS" = "Final Size",
  "None (descriptive)" = "Descriptive",
  "/year" = "Annual Rate"
)

# Clean the data
model_type <- model_type %>%
  mutate(
    # Replace model names using the mapping
    Model = case_when(
      Model %in% names(model_mapping) ~ model_mapping[Model],
      TRUE ~ Model
    )
  ) %>%
  # Group by pathogen and new model name, sum the counts
  group_by(Pathogen, Model) %>%
  summarise(
    n = sum(n),
    .groups = 'drop'
  ) %>%
  # Sort by count in descending order
  arrange(desc(n))



matrix<-tidyr::pivot_wider(data=model_type[!is.na(model_type$n),],
                           id_cols=Pathogen,
                           names_from=Model,
                           values_from=n)


matrix_df<-as.data.frame(matrix)

write.csv(matrix_df, file = "outputs/model_type_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Pathogen
matrix$Pathogen<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0

heatmap(matrix, Colv = NA, Rowv = NA)


#### Parameters by reference ####

parameter_ref<-parametra%>% 
  filter(!grepl(";", Parameter))%>%  #Filter for only individual Parameters
  group_by(Parameter)%>%
  summarise(n_param=n(),
            n_ref = n_distinct(Reference))%>%
  arrange(desc(n_param))

write.csv(parameter_ref, file = "outputs/parameter_n_ref.csv", row.names = FALSE)


#### Pathogens by reference ####

pathogen_ref<-parametra%>% 
  filter(!grepl(";", Parameter))%>%  #Filter for only individual Parameters
  group_by(Pathogen)%>%
  summarise(n_param=n(),
            n_ref = n_distinct(Reference))%>%
  arrange(desc(n_param))

write.csv(pathogen_ref, file = "outputs/pathogen_n_ref.csv", row.names = FALSE)
