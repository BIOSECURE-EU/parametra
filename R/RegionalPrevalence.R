#' Regional Prevalence Parameters Table
#'
#' A dataset containing regional prevalence parameters for various pathogens
#' in animal populations at country or regional level.
#'
#' @format A data frame with 18 variables:
#' \describe{
#'   \item{Country}{Country or region where data was collected}
#'   \item{Parameter}{Parameter measured}
#'   \item{Sampling purpose}{Purpose of the sampling conducted}
#'   \item{Information level}{Geographical level of information detail}
#'   \item{Pathogen}{Name of the infectious agent}
#'   \item{Host}{Host species}
#'   \item{Host type}{Type of host}
#'   \item{Host breed}{Specific breed of host}
#'   \item{Host Age (group)}{Age or age group of hosts}
#'   \item{Host other characteristics}{Additional host characteristics}
#'   \item{Time period}{Time period of the study}
#'   \item{Study}{Study methodology used}
#'   \item{Remarks}{Additional notes or comments}
#'   \item{Reference}{Citation for the source study}
#'   \item{Year}{Year of publication}
#'   \item{doi}{Digital Object Identifier}
#'   \item{Filled in by:}{Data entry person identifier}
#'   \item{ParameterType}{Category of parameter}
#' }
#'
#' @source Compiled from various scientific publications (see "Reference" column)
"RegionalPrevalence"
