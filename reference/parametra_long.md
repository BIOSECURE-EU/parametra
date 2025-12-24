# Parameters Table (Long Format)

A comprehensive dataset combining all parameter tables into a single
long-format table. Contains information about infectious diseases in
animal populations, including: transmission parameters, pathogen
survival, diagnostic tests, prevalence data, and control measures. The
source table for each entry is identified in the "ParameterType" column.

## Usage

``` r
parametra_long
```

## Format

A data frame with 41 variables:

- parameter:

  Parameter measured

- if_other:

  Additional parameter specifications

- unit:

  Units of measurement

- model_type:

  Model classification (e.g., SI, SIR)

- model_mixing:

  Mixing pattern in the population

- model_scale:

  Scale of the model

- study_type:

  Study type

- pathogen:

  Name of the infectious agent

- variant_strain:

  Specific variant or strain

- host:

  Host species

- host_type:

  Type of host

- host_breed:

  Specific breed of host

- host_age:

  Age or age group of hosts

- host_other:

  Additional host characteristics

- vaccine_seeder:

  Vaccination status of seeder/inoculated animals

- vaccine_contact:

  Vaccination status of contact animals

- vaccine:

  Type of vaccine used if applicable

- value:

  Numeric value of the parameter

- lower_cl:

  Lower bound of confidence/credible interval

- upper_cl:

  Upper bound of confidence/credible interval

- estimation_type:

  Statistical approach used (Frequentist/Bayesian)

- estimation_method:

  Method used for estimation

- remarks:

  Additional notes or comments

- ref_short:

  Short reference: source author and year

- year:

  Year of publication

- ref:

  Reference: source doi or url

- filled_by:

  Data entry person identifier

- parameter_type:

  Category of parameter

- inoculated_contact:

  Inoculation or contact status

- material:

  Type of material or medium where survival was measured

- test_type:

  Type of diagnostic test used

- sample_type:

  Type of biological sample used

- time_period:

  Time period of the study

- country:

  Country or region where data was collected

- sampling_purpose:

  Purpose of the sampling conducted

- info_level:

  Level of information detail

- plan_implemented:

  Whether a control plan is implemented

- plan_voluntary_compulsary:

  Voluntary or compulsary plan

- plan_coverage:

  Geographical scope of the plan

- country_disease_status:

  Disease status classification

- plan_type:

  Type of control plan

- last_updated:

  Date of last control plan update

## Source

Combination of all individual parameter tables, compiled from various
scientific publications (see "ref" column)
