# Transmission Parameters Table

A dataset containing transmission parameters for various infectious
diseases in animal populations.

## Usage

``` r
Transmission
```

## Format

A data frame with 1072 rows and 28 variables:

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

## Source

Compiled from various scientific publications (see "ref" column)
