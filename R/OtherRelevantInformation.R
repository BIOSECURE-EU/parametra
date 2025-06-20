#' Other Relevant Information Parameters Table
#'
#' A dataset containing additional parameters and information related to various infectious diseases
#' in animal populations that don't fit into other specific categories.
#'
#' @format A data frame with 24 variables:
#' \describe{
#'   \item{parameter}{Parameter measured}
#'   \item{if_other}{Additional parameter specifications}
#'   \item{unit}{Units of measurement}
#'   \item{model_type}{Model classification}
#'   \item{study_type}{Study type}
#'   \item{pathogen}{Name of the infectious agent}
#'   \item{variant_strain}{Specific variant or strain}
#'   \item{host}{Host species}
#'   \item{host_type}{Type of host}
#'   \item{host_breed}{Specific breed of host}
#'   \item{host_age}{Age or age group of hosts}
#'   \item{host_other}{Additional host characteristics}
#'   \item{vaccine}{Type of vaccine used if applicable}
#'   \item{value}{Numeric value of the parameter}
#'   \item{lower_cl}{Lower bound of confidence/credible interval}
#'   \item{upper_cl}{Upper bound of confidence/credible interval}
#'   \item{estimation_type}{Statistical approach used (Frequentist/Bayesian)}
#'   \item{estimation_method}{Method used for estimation}
#'   \item{remarks}{Additional notes or comments}
#'   \item{ref_short}{Short reference: source author and year}
#'   \item{year}{Year of publication}
#'   \item{ref}{Reference: source doi or url}
#'   \item{filled_by}{Data entry person identifier}
#'   \item{parameter_type}{Category of parameter}
#' }
#'
#' @source Compiled from various scientific publications (see "ref" column)
"OtherRelevantInformation"
