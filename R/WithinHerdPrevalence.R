#' Within-Herd Prevalence Parameters Table
#'
#' A dataset containing within-herd prevalence parameters for various pathogens
#' in animal populations.
#'
#' @format A data frame with 18 variables:
#' \describe{
#'   \item{parameter}{Parameter measured}
#'   \item{pathogen}{Name of the infectious agent}
#'   \item{host}{Host species}
#'   \item{host_type}{Type of host}
#'   \item{host_breed}{Specific breed of host}
#'   \item{host_age}{Age or age group of hosts}
#'   \item{host_other}{Additional host characteristics}
#'   \item{study_type}{Study type}
#'   \item{time_period}{Time period of the study}
#'   \item{value}{Numeric value of the parameter}
#'   \item{lower_cl}{Lower bound of confidence/credible interval}
#'   \item{upper_cl}{Upper bound of confidence/credible interval}
#'   \item{remarks}{Additional notes or comments}
#'   \item{ref_short}{Short reference: source author and year}
#'   \item{year}{Year of publication}
#'   \item{ref}{Reference: source doi or url}
#'   \item{filled_by}{Data entry person identifier}
#'   \item{parameter_type}{Category of parameter}
#' }
#'
#' @source Compiled from various scientific publications (see "Reference" column)
"WithinHerdPrevalence"
