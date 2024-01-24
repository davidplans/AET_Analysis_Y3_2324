* Encoding: UTF-8.

DATASET ACTIVATE DataSet1.

FREQUENCIES VARIABLES=Gender
  /ORDER=ANALYSIS.

DESCRIPTIVES VARIABLES=Age
  /STATISTICS=MEAN STDDEV.

GLM biological_pain_mean biological_non_pain_mean non_biological_pain_mean non_biological_non_pain_mean
  /WSFACTOR=animacy 2 Polynomial painfulness 2 Polynomial 
  /METHOD=SSTYPE(3)
  /EMMEANS=TABLES(animacy) COMPARE ADJ(LSD)
  /EMMEANS=TABLES(painfulness) COMPARE ADJ(LSD)
  /EMMEANS=TABLES(animacy*painfulness) compare(painfulness)
  /PRINT=DESCRIPTIVE ETASQ OPOWER 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=animacy painfulness animacy*painfulness.

T-TEST PAIRS=biological_pain_mean biological_pain_mean biological_pain_mean biological_non_pain_mean WITH biological_non_pain_mean 
    non_biological_pain_mean non_biological_non_pain_mean non_biological_pain_mean (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.