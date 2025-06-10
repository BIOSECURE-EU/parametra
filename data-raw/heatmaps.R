parametra_heatmap <- function(x, y, data=parametra_long, order_by=NULL, filename = NULL) {
  # Create data summary
  data<-data %>%
    dplyr::filter(!grepl(";", .data[[x]])) %>%  #Filter for only individual items
    dplyr::group_by(across(all_of(c(x, y)))) %>%
    dplyr::summarise(n = n())

  # Rows order
  if(is.null(order_by)){
    data<-dplyr::arrange(data, desc(n))
  }else{
    data<-dplyr::arrange(data, across(order_by), desc(n))
  }

  # Create pivot wider matrix
  matrix <- tidyr::pivot_wider(
    data = data[!is.na(data$n), ],
    id_cols  = all_of(x),
    names_from = all_of(y),
    values_from = n
  )

  # Convert to matrix format
  rnames <- matrix[[x]]
  matrix[[x]] <- NULL
  matrix <- as.matrix(matrix)
  row.names(matrix) <- rnames

  # Replace NA with 0
  matrix[is.na(matrix)] <- 0

  # Create heatmap
  heatmap(matrix, Colv = NA, Rowv = NA)

  # Save if filename provided
  if (!is.null(filename)) {
    matrix_df <- as.data.frame(matrix)
    write.csv(matrix_df, file = filename, row.names = FALSE)
  }

  return(matrix)
}


x<-"Pathogen"
y<-"Parameter"
parametra_heatmap(x=x, y=y, filename=paste0("data-raw/heatmaps/",x,"_",y,".csv"))

x<-"Pathogen"
y<-"Year"
parametra_heatmap(x=x, y=y, order_by=y, filename=paste0("data-raw/heatmaps/",x,"_",y,".csv"))

x<-"Pathogen"
y<-"Study"
parametra_heatmap(x=x, y=y, order_by=y, filename=paste0("data-raw/heatmaps/",x,"_",y,".csv"))

x<-"Parameter"
y<-"Study"
parametra_heatmap(x=x, y=y, order_by=y, filename=paste0("data-raw/heatmaps/",x,"_",y,".csv"))

x<-"Pathogen"
y<-"Model"
parametra_heatmap(x=x, y=y, order_by=y, filename=paste0("data-raw/heatmaps/",x,"_",y,".csv"))

x<-"Parameter"
y<-"Model"
parametra_heatmap(x=x, y=y, order_by=y, filename=paste0("data-raw/heatmaps/",x,"_",y,".csv"))
