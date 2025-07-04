#' Control Plan Parameters Table
#'
#' A dataset containing information about disease control programs and plans
#' implemented in different countries for various animal pathogens.
#'
#' @format A data frame with 19 variables:
#' \describe{
#'   \item{country}{Country where the control plan is implemented}
#'   \item{pathogen}{Name of the infectious agent}
#'   \item{host}{Host species}
#'   \item{host_type}{Type of host}
#'   \item{host_breed}{Specific breed of host}
#'   \item{host_age}{Age or age group of hosts}
#'   \item{host_other}{Additional host characteristics}
#'   \item{plan_implemented}{Whether a control plan is implemented}
#'   \item{plan_voluntary_compulsary}{Voluntary or compulsary plan}
#'   \item{plan_coverage}{Geographical scope of the plan}
#'   \item{country_disease_status}{Disease status classification}
#'   \item{plan_type}{Type of control plan}
#'   \item{last_updated}{Date of last control plan update}
#'   \item{remarks}{Additional notes or comments}
#'   \item{ref_short}{Short reference: source author and year}
#'   \item{year}{Year of publication}
#'   \item{ref}{Reference: source doi or url}
#'   \item{filled_by}{Data entry person identifier}
#'   \item{parameter_type}{Category of parameter}
#' }
#'
#' @source Compiled from various official sources and publications (see "ref" column)
"ControlPlan"
