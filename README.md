PARAMETRA

Welcome to the PARAMETRA livestock disease transmission database. This database has been assembled by the BIOSECURE consortium to facilitate livestock disease transmission modelling. The PARAMETRA database is designed to be directly downloaded into programming environments such as R. In this ReadMe you will find an overview of the data currently available.
The PARAMETRA database currently contains parameter values for up to 20 different livestock diseases. PARAMETRA was populated using a semi-systematic literature review. For further information on methodology please consult the accompanying publication [doi: XXXX - add when we submit to Biorxiv].

DATABASE STRUCTURE

The PARAMETRA database is subdivided by disease and by parameter. Parameters included in the database are:

Transmission: Reproduction number; transmission parameter; probability of infection given direct/indirect contact; probability of reactivation of latent infection; other

Infectious/Latent/Incubation: Infectious period; latent Period; incubation period; shape; other

Pathogen survival: no numeric parameters, this section of the database contains a summary of relevant publications relating to pathogen survival on a variety of surfaces and disinfection procedures

Diagnostic Test: Specificity; sensitivity

Within Herd Prevalence: Within herd prevalence

Regional Prevalence: Herd prevalence; global prevalence

Control Plan: no numeric parameters, this section of the database contains a summary of relevant publications relating to the presence of voluntary or compulsory national and regional control plans for various diseases

Other Relevant Information: no numeric parameters, this section of the database contains a summary of publications which may be of interest of relevance for modelling but which do not fit directly into any of the numeric parameter categories included in the database

LOT: List of terms, this section contains a list of terms used in the database and their meanings

Endemic pathogens: contains a list of endemic pathogens and a summary of the availability of parameters per disease

Epidemic pathogens: contains a list of endemic pathogens and a summary of the availability of parameters per disease

AMR pathogens: antimicrobial resistance pathogens, contains a list of AMR pathogens and a summary of the availability of parameters per disease

FOLDERS AND FILES

data: this folder contains all parameter value data in separate .csv files and the full database as a single .xlsx file
	
 	parametra.xslx: the full PARAMETRA database
	
 	parametra_AMR_Pathogens.cv: summary of available data for AMR pathogens
	
	parametra_ChangesLog.csv: summary of changes made to the database
	
 	parametra_ControlPlan.csv: national and regional control plan data
	
 	parametra_DiagnosticTest.csv: diagnostic test sensitivity and specificity data
	
 	parametra_Endemic_Pathogens.csv: summary of available data for endemic pathogens
	
 	parametra_Epidemic_Pathogens.cv: summary of available data for epidemic pathogens
	
 	parametra_InfectiousLatentIncubation.csv: infectious latent incubation period data
	
 	parametra_LOT.csv: list of terms
	
 	parametra_OtherRelevantInformation.csv: other relevant publications
	
 	parametra_PathogenSurvival.csv: pathogen survival and disinfection on surfaces data
	
 	parametra_RegionalPrevalence.csv: regional prevalence data
	
 	
  	parametra_Transmission.csv: transmission parameter data
	
 	parametra_WithinHerdPrevalence.csv: within herd prevalence data

outputs: this folder contains the matrix summarising the database contents
	
 	param_matrix.csv: database summary matrix
	
 	param_matrix.xlsx: database summary matrix

renv: this folder contains R environment files
	
 	.gitignore:
	
 	activate.R:



	.Rprofile:

	.gitignore:

	README.md: read me file for the database

	data_analysis.qmd:
	
 	parametra.Rproj: R project file for the database

	renv.lock:

	set_up.R:

SET UP


1. open parametra.Rproj in RStudio (recommended)

2. Alternatively set your working directory to the project folder

3. Install required packages

	install.packages(c("mc2d", "ggplot2", "dplyr", "tidyr"))

USAGE

The database and individual sheets can be downloaded directly into R or other programming environments. The database is designed to be used in the development of transmission models for livestock diseases. 

DATABASE MODIFICATION

The database can only be modified by administrators (contact information below). If you wish to make a modification to the database, if you notice an error in the database, or you would like to include an additional disease or parameter to the database please contact the administrators to discuss this.

LICENSE


CONTACT

Natalia Ciria Artiga: Natalia.Ciria@uab.cat

Alistair Antonopoulos: Alistair@kreavet.com
