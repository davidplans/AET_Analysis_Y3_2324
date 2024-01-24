* Encoding: UTF-8.
** Wilcoxon Signed-Rank tests Experiment 1

DATASET ACTIVATE DataSet1.
NPAR TESTS
  /WILCOXON=biological_pain_mean non_biological_pain_mean WITH biological_non_pain_mean 
    non_biological_non_pain_mean (PAIRED)
  /STATISTICS QUARTILES
  /MISSING ANALYSIS.



NPAR TESTS
  /WILCOXON=biological_pain_mean biological_pain_mean non_biological_pain_mean WITH non_biological_pain_mean 
    non_biological_non_pain_mean biological_non_pain_mean (PAIRED)
  /STATISTICS QUARTILES
  /MISSING ANALYSIS.
