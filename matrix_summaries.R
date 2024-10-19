library(dplyr)
library(tidyr)

parametra_long<-read.csv("data/parametra_long.csv")

#### Parameter availability matrix ####
study_types<-parametra%>% 
  filter(!grepl(";", Pathogen))%>%  #Filter for only individual pathogens
  group_by(Pathogen, Study)%>%
  summarise(n = n())%>%
  arrange(desc(n))


matrix<-tidyr::pivot_wider(data=study_types[!is.na(study_types$n),],
                           id_cols=Pathogen,
                           names_from=Study,
                           values_from=n)


matrix_df<-as.data.frame(matrix)

write.csv(matrix_df, file = "outputs/study_types_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Pathogen
matrix$Pathogen<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0


heatmap(matrix, Colv = NA, Rowv = NA)


#### Study type matrix ####

study_types<-parametra%>% 
  filter(!grepl(";", Pathogen))%>%  #Filter for only individual pathogens
  group_by(Pathogen, Study)%>%
  summarise(n = n())%>%
  arrange(desc(n))


matrix<-tidyr::pivot_wider(data=study_types[!is.na(study_types$n),],
                           id_cols=Pathogen,
                           names_from=Study,
                           values_from=n)


matrix_df<-as.data.frame(matrix)

write.csv(matrix_df, file = "outputs/study_type_matrix.csv", row.names = FALSE)


#matrix row names
rnames<-matrix$Pathogen
matrix$Pathogen<-NULL
matrix<-as.matrix(matrix)
row.names(matrix)<-rnames

matrix[is.na(matrix)]<-0


heatmap(matrix, Colv = NA, Rowv = NA)



#### Year of publishing ####
study_year<-parametra%>%
  separate(Reference,c("First Author","Year"), sep=", ")%>%
  mutate(Year=as.numeric(Year))%>%
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
