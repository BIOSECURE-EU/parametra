#' Parameters Table (Long Format)
#'
#' A comprehensive dataset combining all parameter tables into a single long-format table.
#' Contains information about infectious diseases in animal populations, including:
#' transmission parameters, pathogen survival, diagnostic tests, prevalence data, and
#' control measures. The source table for each entry is identified in the "ParameterType"
#' column.
#'
#' @format A data frame with 41 variables:
#' \describe{
#'   \item{parameter}{Parameter measured}
#'   \item{if_other}{Additional parameter specifications}
#'   \item{unit}{Units of measurement}
#'   \item{model_type}{Model classification (e.g., SI, SIR)}
#'   \item{model_mixing}{Mixing pattern in the population}
#'   \item{model_scale}{Scale of the model}
#'   \item{study_type}{Study type}
#'   \item{pathogen}{Name of the infectious agent}
#'   \item{variant_strain}{Specific variant or strain}
#'   \item{host}{Host species}
#'   \item{host_type}{Type of host}
#'   \item{host_breed}{Specific breed of host}
#'   \item{host_age}{Age or age group of hosts}
#'   \item{host_other}{Additional host characteristics}
#'   \item{vaccine_seeder}{Vaccination status of seeder/inoculated animals}
#'   \item{vaccine_contact}{Vaccination status of contact animals}
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
#'   \item{inoculated_contact}{Inoculation or contact status}
#'   \item{material}{Type of material or medium where survival was measured}
#'   \item{test_type}{Type of diagnostic test used}
#'   \item{sample_type}{Type of biological sample used}
#'   \item{time_period}{Time period of the study}
#'   \item{country}{Country or region where data was collected}
#'   \item{sampling_purpose}{Purpose of the sampling conducted}
#'   \item{info_level}{Level of information detail}
#'   \item{plan_implemented}{Whether a control plan is implemented}
#'   \item{plan_voluntary_compulsary}{Voluntary or compulsary plan}
#'   \item{plan_coverage}{Geographical scope of the plan}
#'   \item{country_disease_status}{Disease status classification}
#'   \item{plan_type}{Type of control plan}
#'   \item{last_updated}{Date of last control plan update}
#' }
#'
#' @source Combination of all individual parameter tables, compiled from various scientific publications (see "Reference" column)
"parametra_long"
