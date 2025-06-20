# PARAMETRA <img src="man/figures/logo.png" align="right" height="139"/>

A curated database for animal disease modelling, that contains data on infectious periods, transmission rates, pathogen survival, diagnostic tests, prevalence, and control measures for multiple livestock diseases.

Originally developed by the [BIOSECURE](https://biosecure.eu/) consortium through a semi-systematic literature review. For more information on the methodology, see the accompanying publication:

> Antonopoulos, Alistair and Ciria Artiga, Natalia and Regan, Áine and Tubay, Jerrold and Ciaravino, Giovanna and Hayes, Brandon H. and Lambert, Sebastien and Vergne, Timothée and Velkers, Francisca and Biebaut, Evelien and Viltrop, Arvo and Dewulf, Jeroen and Charlier, Johannes and Fischer, Egil A.J. and Allepuz, Alberto, PARAMETRA: A Transmission Modelling Database for Livestock Diseases (January 31, 2024). Available at SSRN: <https://ssrn.com/abstract=5137563> or [http://dx.doi.org/10.2139/ssrn.5137563](https://dx.doi.org/10.2139/ssrn.5137563)

The database continues to grow thanks to user contributions via the [PARAMETRA submission form](https://ec.europa.eu/eusurvey/runner/parametra-submission).

You can visualize the number of parametra entries by pathogen, parameter, year and study type [here](https://biosecure-eu.github.io/parametra/articles/parametra.html).

## How to use it

### Download Excel file

Click [here](https://github.com/BIOSECURE-EU/parametra/raw/refs/heads/main/data-raw/parametra.xlsx) to download parametra as an Excel file. This file can also be found at `data-raw/parametra.xlsx`.

### Installation as an R package

``` r
# install.packages("devtools")
devtools::install_github("BIOSECURE-EU/parametra")
```

### URL Data Access

Access the database and individual sheets directly in R or other programming environments for livestock disease transmission modeling.

**Download CSV files in R**

1.  Navigate to the CSV file in `data-raw/tables`
2.  Click **raw** in the top right
3.  Copy the link (starting with [https://raw.githubusercontent.com/..](https://raw.githubusercontent.com/.))

Example: Download `parametra_long.csv` (containing all parameter tables) directly in R:

``` r
data<-read.csv("https://raw.githubusercontent.com/BIOSECURE-EU/parametra/refs/heads/main/data-raw/parametra_long.csv")
```

Or in Python:

``` python
import pandas as pd

data = pd.read_csv("https://raw.githubusercontent.com/BIOSECURE-EU/parametra/refs/heads/main/data-raw/parametra_long.csv")
```

## Database Structure

Each PARAMETRA entry contains a parameter, pathogen, and reference. Additional information varies by parameter type and may include host species, study type, value, and upper and lower confidence intervals. The database organizes these entries into the following parameter tables:

1.  [**Transmission**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_Transmission.csv): Reproduction number, transmission parameter, probability of infection given direct/indirect contact, probability of reactivation of latent infection, other
2.  [**Infectious/Latent/Incubation**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_InfectiousLatentIncubatperiod.csv): Infectious period, latent period, incubation period, shape, other
3.  [**Pathogen survival**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_PathogenSurvival.csv): Pathogen survival on various surfaces and disinfection procedures
4.  [**Diagnostic Test**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_DiagnosticTest.csv): Specificity, sensitivity
5.  [**Within Herd Prevalence**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_WithinHerdPrevalence.csv): Within herd prevalence
6.  [**Regional Prevalence**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_RegionalPrevalence.csv): Herd prevalence, global prevalence
7.  [**Control Plan**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_ControlPlan.csv): Voluntary or compulsory national and regional control plans
8.  [**Other Relevant Information**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/tables/parametra_OtherRelevantInformation.csv): Other relevant parameters for modelling

All this tables are aggregated in [**parametra_long**](https://github.com/BIOSECURE-EU/parametra/blob/main/data-raw/parametra_long.csv). You can fill their full documentation [here](https://biosecure-eu.github.io/parametra/reference/index.html).

## Crossref

The [**parametra_crossref**](https://raw.githubusercontent.com/BIOSECURE-EU/parametra/refs/heads/main/data-raw/parametra_crossref.csv) table contains bibliographic information found on [Crossref](https://www.crossref.org/) for all references ("ref") cited in the database.

## Complementary tables

Only available in the excel file:

1.  **LOT (List of Terms)**: List of terms used in the database and their meanings
2.  **Change log**: Tracks modifications, updates, and version history
3.  **Endemic pathogens**: List of endemic pathogens and parameter availability summary
4.  **Epidemic pathogens**: List of epidemic pathogens and parameter availability summary
5.  **AMR pathogens**: List of antimicrobial resistance pathogens and parameter availability summary

## How to Submit New Parameters

There are two ways to contribute new parameters to the PARAMETRA database:

### Option 1: Single Parameter Submission

1.  Visit the [PARAMETRA submission form](https://ec.europa.eu/eusurvey/runner/parametra-submission)
2.  Fill in the required fields for your single parameter entry
3.  Submit the form

### Option 2: Bulk Submission (Excel Template)

1.  Download the [Excel template](https://github.com/BIOSECURE-EU/parametra/raw/refs/heads/main/data-raw/parametra_submission_template.xlsx)
2.  Fill out the Excel template with your parameter entries, using PARAMETRA database as a reference for proper formatting.
3.  Upload the file through the [PARAMETRA submission form](https://ec.europa.eu/eusurvey/runner/parametra-submission)

> All submissions will be reviewed by PARAMETRA administrators before being added to the database to ensure data quality and consistency.

## Contact

-   Natalia Ciria Artiga: [Natalia.Ciria\@uab.cat](mailto:Natalia.Ciria@uab.cat)
-   Alistair Antonopoulos: [Alistair\@kreavet.com](mailto:Alistair@kreavet.com)

## License

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)

## Acknowledgments

PARAMETRA was developed as part of the [BIOSECURE](https://biosecure.eu/) Project, funded from the European Union’s HORIZON Europe FARM2FORK project.
