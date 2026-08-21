# Data Audit

## Dataset Size

* Rows: 541,909
* Columns: 8

## Data Quality Issues

* 1,454 missing descriptions
* 135,080 missing customer IDs
* 5,268 duplicate rows
* Negative quantities
* Cancelled invoices beginning with C
* Zero-price transactions
* Internal stock-adjustment rows

## Decisions Still Needed

* Which duplicates should be removed?
* Should missing customer IDs be kept?
* How should cancellations be treated?
* Which zero-price rows are valid?

## Proposed Cleaning Rules


- removing the duplicates
- Missing Description: exclude 1,454 zero-value, customerless records from the sales dataset and preserve them separately as possible internal stock adjustments.
