#' Pathogen Survival Parameters Table
#'
#' A dataset containing survival parameters for various pathogens
#' in different materials and environmental conditions.
#'
#' @format A data frame with 12 variables:
#' \describe{
#'   \item{parameter}{Parameter measured}
#'   \item{if_other}{Additional parameter specifications}
#'   \item{study_type}{Study type}
#'   \item{pathogen}{Name of the infectious agent}
#'   \item{variant_strain}{Specific variant or strain}
#'   \item{material}{Type of material or medium where survival was measured}
#'   \item{remarks}{Additional notes or comments}
#'   \item{ref_short}{Short reference: source author and year}
#'   \item{year}{Year of publication}
#'   \item{ref}{Reference: source doi or url}
#'   \item{filled_by}{Data entry person identifier}
#'   \item{parameter_type}{Category of parameter}
#' }
#'
#' @source Compiled from various scientific publications (see "Reference" column)
"PathogenSurvival"
