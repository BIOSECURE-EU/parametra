#' Diagnostic Test Parameters Table
#'
#' A dataset containing diagnostic test parameters for various pathogens
#' in animal populations.
#'
#' @format A data frame with 19 variables:
#' \describe{
#'   \item{Parameter}{Parameter measured}
#'   \item{Test Type}{Type of diagnostic test used}
#'   \item{Pathogen}{Name of the infectious agent}
#'   \item{Host}{Host species}
#'   \item{Host type}{Type of host}
#'   \item{Host breed}{Specific breed of host}
#'   \item{Host Age (group)}{Age or age group of hosts}
#'   \item{Host other characteristics}{Additional host characteristics}
#'   \item{Study}{Study type}
#'   \item{Type of sample}{Type of biological sample used}
#'   \item{Value}{Numeric value of the parameter}
#'   \item{Lower confidence/credible level}{Lower bound of confidence/credible interval}
#'   \item{Upper confidence/credible level}{Upper bound of confidence/credible interval}
#'   \item{Remarks}{Additional notes or comments}
#'   \item{Reference}{Citation for the source study}
#'   \item{Year}{Year of publication}
#'   \item{doi}{Digital Object Identifier}
#'   \item{Filled in by:}{Data entry person identifier}
#'   \item{ParameterType}{Category of parameter}
#' }
#'
#' @source Compiled from various scientific publications (see "Reference" column)
"DiagnosticTest"
