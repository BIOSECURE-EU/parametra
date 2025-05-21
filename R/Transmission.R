#' Transmission Parameters Table
#'
#' A dataset containing transmission parameters for various infectious diseases
#' in animal populations.
#'
#' @format A data frame with 1072 rows and 28 variables:
#' \describe{
#'   \item{Parameter}{Parameter measured}
#'   \item{If other}{Additional parameter specifications}
#'   \item{Unit}{Units of measurement}
#'   \item{Type of infectious disease model}{Model classification (e.g., SI, SIR)}
#'   \item{Mixing}{Mixing pattern in the population}
#'   \item{Scale}{Scale of the study}
#'   \item{Study}{Study type}
#'   \item{Pathogen}{Name of the infectious agent}
#'   \item{Variant/Strain}{Specific variant or strain}
#'   \item{Host}{Host species}
#'   \item{Host type}{Type of host}
#'   \item{Host breed}{Specific breed of host}
#'   \item{Host Age (group)}{Age or age group of hosts}
#'   \item{Host other characteristics}{Additional host characteristics}
#'   \item{Seeder/Inoculated vaccinated}{Vaccination status of seeder/Inoculated animals}
#'   \item{Contact vaccinated}{Vaccination status of contact animals}
#'   \item{Vaccine}{Type of vaccine used if applicable}
#'   \item{Value}{Numeric value of the parameter}
#'   \item{Lower confidence/credible level}{Lower bound of confidence/credible interval}
#'   \item{Upper confidence/credible level}{Upper bound of confidence/credible interval}
#'   \item{Frequentist/Bayesian estimation}{Statistical approach used}
#'   \item{Estimation method}{Method used for estimation}
#'   \item{Remarks}{Additional notes or comments}
#'   \item{Reference}{Citation for the source study}
#'   \item{Year}{Year of publication}
#'   \item{doi}{Digital Object Identifier}
#'   \item{Filled in by}{Data entry person identifier}
#'   \item{ParameterType}{Category of parameter}
#' }
#'
#' @source Compiled from various scientific publications (see "Reference" column)
"Transmission"
