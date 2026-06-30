# parametra 1.1.0

## Data

- Added the `cost_biosecurity` table, based on BioSecure T4.2 biosecurity cost data.
- Added a few Sheep and Goat pox virus parameters.

## Structure and documentation

- Renamed columns and table names to `snake_case` for consistency.
- Added standardised IDs for curated records.
- Added and reviewed column-name definitions and README documentation for the `cost_biosecurity` table.
- Automated R data documentation from the LOT and README sheets.
- Added a `year` column.
- Added a `filled_date` column to track data entry dates.
- Standardised model type values.
- Standardised references across PARAMETRA.

## Maintenance

- Implemented an R-based curation workflow, including maintainer documentation, 
  to read, validate, curate, and write the Excel database.

# parametra 1.0.0

* Initial PARAMETRA release, publication version: https://doi.org/10.1016/j.prevetmed.2025.106668.
