# Diagnostic Test Parameters Table

A dataset containing diagnostic test parameters for various pathogens in
animal populations.

## Usage

``` r
DiagnosticTest
```

## Format

A data frame with 19 variables:

- parameter:

  Parameter measured

- test_type:

  Type of diagnostic test used

- pathogen:

  Name of the infectious agent

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

- study_type:

  Study type

- sample_type:

  Type of biological sample used

- value:

  Numeric value of the parameter

- lower_cl:

  Lower bound of confidence/credible interval

- upper_cl:

  Upper bound of confidence/credible interval

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
