# Architecture

The application has a deliberately small, portable boundary: normalized expression counts plus sample metadata enter through the CLI; tables and PNG figures leave through an explicit output directory.

`R/multi_correlation.R` owns validation, optional L2P symbol normalization, duplicate-gene handling, category selection, statistics, FDR correction, and visualization. `entrypoint.R` converts command-line arguments into that core interface. The OCI image only packages the same interface for OncoChat or HPC execution.

The template-hub v5 JSON is a reference for the original parameter intent only. It is not copied or modified by this repository. The standalone implementation corrects the template's duplicated/malformed reshape operation and makes its previously unreported p-values and multiple-testing correction durable outputs.
