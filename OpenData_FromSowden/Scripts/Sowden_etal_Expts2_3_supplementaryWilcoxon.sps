* Encoding: UTF-8.
** non-parametric Wilcoxon tests on error data


DATASET ACTIVATE DataSet1.
NPAR TESTS
  /WILCOXON=biological_errors WITH nonbiological_errors (PAIRED)
  /STATISTICS QUARTILES
  /MISSING ANALYSIS.

NPAR TESTS
  /WILCOXON=biological_pain_errors nonbiological_pain_errors WITH biological_nopain_errors 
    nonbiological_nopain_errors (PAIRED)
  /STATISTICS QUARTILES
  /MISSING ANALYSIS.
