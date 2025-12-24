# CrossRef Metadata for Parametra References

A dataset containing metadata extracted from CrossRef using the
rcrossref package for scientific publications referenced in the
parametra_long dataset.

## Usage

``` r
parametra_crossref
```

## Format

A data frame with 38 variables:

- container.title:

  Title of the containing publication (e.g., journal name)

- created:

  Creation date of the CrossRef record

- deposited:

  Date the record was deposited in CrossRef

- published.print:

  Print publication date

- doi:

  Digital Object Identifier

- indexed:

  Date the record was indexed

- issn:

  International Standard Serial Number

- issue:

  Issue number of the publication

- issued:

  Date of issue

- member:

  CrossRef member ID

- page:

  Page numbers

- prefix:

  DOI prefix

- publisher:

  Name of the publisher

- score:

  Relevance score

- source:

  Source of the metadata

- reference.count:

  Number of references

- references.count:

  Count of references

- is.referenced.by.count:

  Number of times cited

- title:

  Title of the publication

- type:

  Type of publication

- url:

  URL of the publication

- volume:

  Volume number

- abstract:

  Publication abstract

- short.container.title:

  Abbreviated container title

- author:

  Author information

- link:

  Associated links

- reference:

  Reference information

- alternative.id:

  Alternative identifiers

- published.online:

  Online publication date

- language:

  Publication language

- funder:

  Funding information

- license:

  License information

- update.policy:

  Update policy details

- assertion:

  Publication assertions

- archive:

  Archive information

- subtitle:

  Publication subtitle

- update_to:

  Update information

- isbn:

  International Standard Book Number

## Source

Data retrieved from CrossRef API using rcrossref package and
parametra_long dois
