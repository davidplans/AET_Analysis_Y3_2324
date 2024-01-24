* Encoding: UTF-8.

DESCRIPTIVES VARIABLES=Age 
  /STATISTICS=MEAN STDDEV.

FREQUENCIES VARIABLES=gender handedness
    /ORDER=ANALYSIS.

GLM biological_pain biological_nopain nonbiological_pain nonbiological_nopain
  /WSFACTOR=animacy 2 Polynomial pain 2 Polynomial 
  /METHOD=SSTYPE(3)
  /EMMEANS=TABLES(animacy*pain) Compare(pain) adj(lsd) 
  /PRINT=DESCRIPTIVE ETASQ OPOWER 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=animacy pain animacy*pain.

GLM biological_pain_errors biological_nopain_errors nonbiological_pain_errors nonbiological_nopain_errors
  /WSFACTOR=animacy 2 Polynomial pain 2 Polynomial 
  /METHOD=SSTYPE(3)
  /PRINT=DESCRIPTIVE ETASQ OPOWER 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=animacy pain animacy*pain.

REGRESSION
  /DESCRIPTIVES MEAN STDDEV CORR SIG N
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA CHANGE
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT biological_empathicIE
  /METHOD=ENTER nonbiological_empathicIE
  /METHOD=ENTER CogEmp_PerspectiveTaking CogEmp_OnlineSimulation AffEmp_EmotionContagion 
  AffEmp_ProximalResponsivity AffEmp_PeripheralResponsivity.

REGRESSION
  /DESCRIPTIVES MEAN STDDEV CORR SIG N
  /MISSING LISTWISE
  /STATISTICS COEFF OUTS R ANOVA CHANGE
  /CRITERIA=PIN(.05) POUT(.10)
  /NOORIGIN 
  /DEPENDENT nonbiological_empathicIE
  /METHOD=ENTER biological_empathicIE
  /METHOD=ENTER CogEmp_PerspectiveTaking CogEmp_OnlineSimulation AffEmp_EmotionContagion 
  AffEmp_ProximalResponsivity AffEmp_PeripheralResponsivity.