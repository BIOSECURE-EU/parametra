install.packages("readxl")
library(readxl)

file<-"data/parametra.xlsx"
data<-read_xlsx(path = file)

sheet_names<-excel_sheets(path = file)


for(i in 1:length(sheet_names)){
  csv <- read_xlsx(path = file, sheet = sheet_names[i])
  write.csv(csv, file = paste0("data/parametra_",sheet_names[i],".csv"))
  assign(sheet_names[i],csv)
  
}

