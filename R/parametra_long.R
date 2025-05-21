#' Parameters Table (Long Format)
#'
#' A comprehensive dataset combining all parameter tables into a single long-format table.
#' Contains information about infectious diseases in animal populations, including:
#' transmission parameters, pathogen survival, diagnostic tests, prevalence data, and
#' control measures. The source table for each entry is identified in the "ParameterType"
#' column.
#'
#' @format A data frame with 44 variables:
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
#'   \item{Seeder/Inoculated vaccinated}{Vaccination status of seeder/inoculated animals}
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
#'   \item{Filled in by:}{Data entry person identifier}
#'   \item{ParameterType}{Category of parameter}
#'   \item{Inoculated/Contact}{Inoculation or contact status}
#'   \item{Material}{Type of material or medium where survival was measured}
#'   \item{Test Type}{Type of diagnostic test used}
#'   \item{Type of sample}{Type of biological sample used}
#'   \item{Type of study}{Study methodology used}
#'   \item{Time period}{Time period of the study}
#'   \item{Country}{Country or region where data was collected}
#'   \item{Sampling purpose}{Purpose of the sampling conducted}
#'   \item{Information level}{Level of information detail}
#'   \item{Control programme in place}{Whether a control program exists}
#'   \item{Type of programme}{Classification of the control program}
#'   \item{Coverage (regional/national)}{Geographical scope of the program}
#'   \item{Country status for the disease}{Disease status classification}
#'   \item{Control plan type}{Type of control measures implemented}
#'   \item{Last updated}{Date of last program update}
#'   \item{Link}{URL to program documentation}
#' }
#'
#' @source Combination of all individual parameter tables, compiled from various scientific publications (see "Reference" column)
"parametra_long"
