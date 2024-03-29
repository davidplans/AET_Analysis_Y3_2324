library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)

# Read the JSON file
json_data <- fromJSON("/Users/david/MainDrive/RHUL/Y3Projects/2023/AET_Analysis_Y3_2324/AET_Analysis_Y3_2324/patdeployments-default-rtdb-murphyphdstudent1-exportJan24.json", flatten = TRUE)

# Check the structure of the JSON data
str(json_data)

# Set the study filter variable
study_filter <- "\\bDPY323.*" # Adjust this regex to match the keys you're interested in

# Check if there are any keys that match the regular expression
matching_keys <- grep(study_filter, unlist(lapply(json_data, names)), value = TRUE)
print(matching_keys)

# Filter the data based on the study filter key
data <- map(json_data, ~ keep(.x, .p = str_detect(names(.x), regex(study_filter)))) %>%
  compact()

# If you need to save the filtered data back to a JSON file
output_path <- "/Users/david/MainDrive/RHUL/Y3Projects/2023/AET_Analysis_Y3_2324/AET_Analysis_Y3_2324/filtered_json_fileJAN24.json"
write(toJSON(data, pretty = TRUE), output_path)

calc_similarity <- function(delays, periods) {
  angles = delays / periods * 2 * pi
  
  
  delays_complex <- complex(modulus=periods/(2*pi), argument=angles)
  
  
  delays_complex_hat <- sapply(delays_complex, 
                               function(a) complex(modulus = 1.0, argument = Arg(a)*Mod(a)*2*pi))
  Similarity <- 1/length(delays_complex_hat)*Mod(sum(delays_complex_hat))
  Similarity
}

calc_similarity_angles <- function(angles) {
  delays_complex_hat <- complex(modulus = 1.0, argument = angles)
  plot(delays_complex_hat)
  Similarity <- 1/length(delays_complex_hat)*Mod(sum(delays_complex_hat))
  Similarity
}

calc_similarity_complex <- function(delays, periods) {
  
  angles = delays / periods * 2 * pi
  
  
  delays_complex <- complex(modulus=periods/(2*pi), argument=angles)
  
  
  delays_complex_hat <- sapply(delays_complex, 
                               function(a) complex(modulus = 1.0, argument = Arg(a)*Mod(a)*2*pi))
  mod <- 1/length(delays_complex_hat)*Mod(sum(delays_complex_hat))
  arg <- Arg(sum(delays_complex_hat))
  complex(argument = arg, modulus = mod)
}



becca_argomenti <- function(delays, periods) {
  angles = delays / periods * 2 * pi
  delays_complex <- complex(modulus=periods/(2*pi), argument=angles)
  delays_complex_hat <- sapply(delays_complex, 
                               function(a) complex(modulus = 1.0, argument = Arg(a)*Mod(a)*2*pi))
  Arg(delays_complex_hat)
}


```

```{r}
#| include: false
# Define Number of Trials Needed

st_trials_needed <- 17

```

```{r}
#| include: false
# Unnesting the Data

data_clean <- list_flatten(data) %>%
  enframe() %>%
  select(!name) %>%
  unnest_wider(value) %>%
  rename(bl = baselines,
         st = syncroTraining) %>%
  unnest_longer(bl) %>%
  unnest_wider(bl, names_sep = "_") %>%
  unnest_longer(st) %>%
  unnest_wider(st, names_sep = "_") %>%
  drop_na(st_averagePeriods, st_currentDelays) %>%
  group_by(participantID) %>%
  mutate(st_trial = row_number()) %>%
  filter(st_trial > 2) %>%
  group_by(participantID) %>%
  mutate(st_trial = row_number())
  

```

```{r}
#| include: false
## Define Quality Filters


data_clean <- data_clean %>% filter(lengths(st_averagePeriods) > 0 &
                                lengths(st_currentDelays) > 0 &
                                lengths(st_instantPeriods) > 4 &
                                lengths(st_recordedHR) > 0 &
                                st_confidence != -1 &
                                lengths(st_currentDelays) == lengths(st_averagePeriods))

```

```{r}
#| include: false
# Tidying up the Dataframe


data_clean <- data_clean %>% 
  group_by(participantID) %>%
  mutate(st_trial = row_number(),
         st_trial_comp = max(st_trial),
         st_bodyPos = na_if(st_bodyPos, -1)) %>%
  filter(st_trial_comp >= st_trials_needed) %>%
  group_by(participantID) %>%
  slice(1:st_trials_needed) %>%
  rowwise() %>%
  mutate(st_last_delay = st_currentDelays[length(st_currentDelays)],
         st_last_period = st_averagePeriods[length(st_averagePeriods)],
         st_mean_recorded_HR = mean(st_recordedHR),
         st_time_trials = sum(st_instantPeriods),
         st_periods_mean = mean(st_averagePeriods),
         st_engagement_trial = length(unique(st_currentDelays)),
         bl_ibi = list(60 / bl_instantBpms)) %>%
  group_by(participantID) %>%
  do( data.frame(.,sim_exc_trial = sapply(.$st_trial, function(i) calc_similarity(.$st_last_delay[!.$st_trial %in% i], .$st_last_period[!.$st_trial %in% i])))) %>%
  mutate(sim_overall = calc_similarity(st_last_delay, st_last_period),
         sim_difference = sim_exc_trial - sim_overall,
         sim_diff_conf_corr = cor(st_confidence, sim_difference, method = "pearson"),
         angles = becca_argomenti(st_last_delay, st_last_period)) %>%
  mutate_if(is.numeric, ~round(., 3))


```

```{r}
#| include: false
# Adding HR data

hr <- data_clean %>%
  group_by(participantID) %>%
  select(participantID, bl_ibi) %>%
  filter(row_number() == 1) %>%
  as_tibble()


hrv <- list()
for (i in 1:length(hr$bl_ibi)) {
  hrv[[i]] <- CreateHRVData(Verbose = FALSE) %>%
    LoadBeatVector(cumsum(hr$bl_ibi[[i]]), scale = 1) %>%
    BuildNIHR() %>%
    FilterNIHR() %>%
    CreateTimeAnalysis()
}


sdnn <- purrr::map(hrv, ~ pluck(.x, 3, 1, "SDNN")) %>%
  unlist()

rmssd <- purrr::map(hrv, ~ pluck(.x, 3, 1, "rMSSD")) %>%
  unlist()

pnn50 <- purrr::map(hrv, ~ pluck(.x, 3, 1, "pNN50")) %>%
  unlist()


```

Davide, the following code produces a summary object with a range of statistics. We are slightly unsure of `delays_ms`, `mean_angle`, `min_angle`, `max_angel` or how to convert angles back into delays for each participant. Any help would be greatly welcomed here.

```{r}
#| include: false
# Creating a summary object

summary <- data_clean %>%
  group_by(participantID) %>%
  summarise(similarity = calc_similarity(st_last_delay, st_last_period),
            confidence_mean = mean(st_confidence),
            confidence_sd = sd(st_confidence),
            confidence_median = median(st_confidence),
            count_bodyPos = length(unique(st_bodyPos)),
            delays_sec = mean(Arg(calc_similarity_complex(st_last_delay, st_last_period))/(2*pi)),
            mean_angle = Arg(calc_similarity_complex(st_last_delay, st_last_period)),
            min_angle = min(angles),
            max_angle = max(angles),
            sum_time_trials = sum(st_time_trials),
            mean_time_trials = mean(st_time_trials),
            sd_time_trials = sd(st_time_trials),
            mean_engagement_trials = mean(st_engagement_trial),
            sd_engagement_trials = sd(st_engagement_trial),
            valid_trials = st_trial_comp[st_trials_needed],
            used_trials = st_trials_needed,
            task_date = st_date[st_trials_needed],
            mean_HR = mean(st_mean_recorded_HR),
            sim_diff_conf_corr = sim_diff_conf_corr[st_trials_needed]) %>%
  mutate_if(is.numeric, ~round(., 3)) %>%
  mutate(hrv_sdnn = sdnn,
         hrv_rmssd = rmssd,
         hrv_pnn50 = pnn50)

N <- nrow(summary)

write_csv(summary, "/Users/david/MainDrive/RHUL/Y3Projects/2023/Analysis/similarity_scores.csv")

```

# Summary Statistics

`r N` individuals successfully provided data through the app and prolific system. Similarity scores were calculated using the first `r st_trials_needed` trials for each individual. Summary statistics for similarity scores and other metrics are presented below.

```{r}
#| echo: false
#| output: asis

t1 <- tableby(
  ~ similarity +
    confidence_mean +
    mean_HR +
    hrv_sdnn +
    hrv_rmssd +
    hrv_pnn50 +
    mean_time_trials +
    mean_engagement_trials +
    sim_diff_conf_corr,
  data = summary)

summary(t1,
  labelTranslations = list(
    similarity = "Similarity",
    confidence_mean = "Mean confidence score",
    mean_HR = "Mean heart rate (bpm)",
    hrv_sdnn = "SDNN",
    hrv_rmssd = "RMSSD",
    hrv_pnn50 = "PNN50",
    mean_time_trials = "Time spent on each trial (sec)",
    mean_engagement_trials = "Mean engagement trials (sec)",
    sim_diff_conf_corr = "Similarity Difference - Confidence Correlation"),
  digits = 2)


```

# Were participant responses non-random?

```{r}
#| include: false
# To compare participants responses to a randomly generated distribution, create random distribution 
#PLV

max_iter <- 5000

similarities_random20 <- purrr::map_dbl(1:max_iter, function(i) {
  n <- 17
  periods <- runif(n, 0.5, 1.5)
  delays <- purrr::map_dbl(periods, function(p) runif(1, 0, p))
  calc_similarity(delays, periods)
})

```

```{r}
#| include: false

Dp <- ggplot() +
  geom_density(aes(similarities_random20, color="Simulated responses")) +
  geom_density(aes(summary$similarity, color="Real responses")) +
  scale_color_manual( values=c("black","red")) +
  labs(color="Distribution") +
  theme_pubr(legend = c(0.85,0.85)) +
  xlab("Similarity Score") +
  ylab("Density")

```

```{r}
#| echo: false
#| fig-cap:
#| - "Probability density function of data from simulated participants responding at random (red line) and real participants’ data (black line)."
# run wilcox test to compare distributions 

wilcox_model <- wilcox.test(summary$similarity, similarities_random20)

# calculate r (effect size for wilcox test)
N <- nrow(summary) + length(similarities_random20)
z <- qnorm(wilcox_model$p.value/2)
r <- z/sqrt(N)

## Format p value for reporting in text
Wp <- ifelse(wilcox_model$p.value < .001, "<.001", paste0("=", round(wilcox_model$p.value, digits = 3), sep = ""))

Dp

```

```{r}
#| echo: false

knitr::kable(tidy(wilcox_model))

```

By comparing the responses from the participants to a randomly generated distribution (**`r toString(max_iter)`** iterations) we can see if the participants were answering randomly. A wilcox test indicates that the distribution of participants responses is different to the randomly generated distribution **(Z= `r toString(round(z, digits=3))`, *p*`r toString(Wp)`, *r* = `r toString(round(r, digits=3))`)**. This suggests participants were not responding randomly.

```{r}
#| include: false
# Define gaussian mixture models in order to define bayes factor labels

#gaussian mixture models

similarities_plv <- summary$similarity

model <- EMGauss(similarities_plv, K = 2)

non_interoceptive_mean = model$Means[1]
non_interoceptive_sd = model$SDs[1]
interoceptive_mean = model$Means[2]
interoceptive_sd = model$SDs[2]

z_score_non_intero = sapply(similarities_plv, function(x) (x - non_interoceptive_mean)/non_interoceptive_sd)
z_score_intero = sapply(similarities_plv, function(x) (x - interoceptive_mean)/interoceptive_sd)

is_subject_interoceptive = abs(z_score_intero) < abs(z_score_non_intero)
table(is_subject_interoceptive)

is_subject_intero = abs(z_score_intero)/abs(z_score_non_intero) > 3.0
is_subject_non_intero = abs(z_score_non_intero)/abs(z_score_intero) > 3.0

table(is_subject_intero)
table(is_subject_non_intero)

#probability of having a value at least this far from the mean
prob_non_intero <- 1 - (pnorm(abs(z_score_non_intero)) - pnorm(-abs(z_score_non_intero)))

prob_intero <- 1 - (pnorm(abs(z_score_intero)) - pnorm(-abs(z_score_intero)))

bf_intero <-  prob_intero/prob_non_intero
bf_non_intero <-  prob_non_intero/prob_intero

plot(log(bf_intero))
abline(h=3)

plot(log(bf_non_intero))
abline(h=3)

#plots of probabilities
plot(density(prob_non_intero), 
     main = "Probabilities of being non-interoceptive",
     xlab = "",
     col = "red")
plot(density(prob_intero),
     main = "Probabilities of being interoceptive",
     xlab = "",
     col = "blue")

```

# Classifying participants as interoceptive or non-interoceptive

In order to classify participants as either interoceptive or non-interoceptive, a gaussian mixture model with 2 mixtures was applied to the similarity values following the assumption that the population is made of two subpopulations; interoceptive and non-interoceptive participants. Briefly, a Z-score for each participant was calculated for the interoceptive and non-interoceptive distributions separately, and these Z-scores were used to calculate the probability of an individual being interoceptive or non-interoceptive. The estimated probability distributions, along with the distribution of real responses can be seen below.

```{r}
#| echo: false
#| fig-cap:
#| - "Probability density function of real participants’ data (black line), estimated distribution of non-interoceptive participants (red line) and interoceptive participants (blue line)."

#plot of real answers and distributions

x <- seq(0, 1, length = 100)
NonI <- dnorm(x, non_interoceptive_mean, non_interoceptive_sd)

Intero <- dnorm(x, interoceptive_mean, interoceptive_sd)

PDFplot <- ggplot() +
  geom_density(aes(x = summary$similarity,
                   color="Real Answers")) +
  geom_line(aes(x = x, y=NonI, color="Non-Interoceptive"), linetype="dashed") +
  geom_line(aes(x = x, y=Intero, color="Interoceptive"), linetype="dashed") +
  scale_color_manual( values=c("blue","red","black")) +
  labs(color="Distribution") + theme_pubr(legend = c(0.9,0.85)) +xlab("Similarity Score") +ylab("Density")

PDFplot

```

```{r}
#| echo: false

knitr::kable(tidy(wilcox_model))

```

Comparing the probabilities of a participant being Interoceptive or Non-Interoceptive allows a Bayes Factor (BF) to be calculated as the ratio of an individual belonging to one of the two distributions, over the probability of belonging to the other distribution. This allows each participant to be classified as being Interoceptive, Non-Interoceptive, or Unknown (Unclassifed). This classification was carried out using three BF thresholds, \>3, \>10 and \>30.

```{r}
#| include: false

## Generating the dataframes with BF 3, 10 and 30 (T1)
## add bayes factors for interoceptive or non interoceptive to dataframe

summary$bf_intero <- bf_intero
summary$bf_non_intero <- bf_non_intero

## BF3
## Assign Labels based on a bayes factor threshold >3

# Assign "Interoceptive participants" to individuals with bf_intero > 3. Assign
# "Unknown" to participants with bf_intero <=3

summary$intero_bf_label_3 <- ifelse(summary$bf_intero > 3,
                                    "Interoceptive participants",
                                    "Unknown")

# Assign "Non Interoceptive participants" to individuals with bf_non_intero > 3. Assign
# "Unknown" to participants with bf_non_intero <=3

summary$intero_non_bf_label_3 <- ifelse(summary$bf_non_intero > 3,
                                        "Non interoceptive participants",
                                        "Unknown")

## Assign Final Label for interceptive or non interceptive by checking values in intero_bf_label_3
## and intero_non_bf_label_3

summary$intero_bayes_3 <-  ifelse(summary$intero_bf_label_3 == "Interoceptive participants",
                                  "Interoceptive participants",
                                  "Non interoceptive participants")
  

### Assign Final Unknown label to individuals where there is not sufficient evidence
## to indicate if interceptive or non-interoceptive
summary$intero_bayes_3 <-  ifelse(summary$intero_bf_label_3 == "Unknown" & 
                                  summary$intero_non_bf_label_3 == "Unknown",
                                  "Unknown",
                                  summary$intero_bayes_3)


## remove individuals with Unknown final label (uncomment to remove)
# summary_bayes <- summary %>% filter(intero_bayes_3 != "Unknown")

## if not removing unknowns use this line

summary_bayes <- summary


#BF 10
## Assign Labels based on a bayes factor threshold >10

# Assign "Interoceptive participants" to individuals with bf_intero > 10. Assign
# "Unknown" to participants with bf_intero <=10
summary$intero_bf_label_10 <-  ifelse(summary$bf_intero > 10, "Interoceptive participants", "Unknown")


# Assign "Non Interoceptive participants" to individuals with bf_non_intero > 10. Assign
# "Unknown" to participants with bf_non_intero <=10
summary$intero_non_bf_label_10 <- ifelse(summary$bf_non_intero > 10,
                                         "Non interoceptive participants",
                                         "Unknown")


## Assign Final Label for interceptive or non interceptive by checking values in intero_bf_label_10
## and intero_non_bf_label_10
summary$intero_bayes_10 <-  ifelse(summary$intero_bf_label_10 == "Interoceptive participants",
                                   "Interoceptive participants",
                                   "Non interoceptive participants")
  

### Assign Final Unknown label to individuals where there is not sufficient evidence
## to indicate if interceptive or non-interoceptive
summary$intero_bayes_10 <-  ifelse(summary$intero_bf_label_10 == "Unknown" &
                                   summary$intero_non_bf_label_10 == "Unknown",
                                   "Unknown",
                                   summary$intero_bayes_10)

## remove individuals with Unknown final label (unvomment to remove)
# summary_bayes_10 <- summary %>% filter(intero_bayes_10 != "Unknown")

## if not removing unknowns use this line
summary_bayes_10 <- summary


#BF 30
## Assign Labels based on a bayes factor threshold >30

# Assign "Interoceptive participants" to individuals with bf_intero > 30. Assign
# "Unknown" to participants with bf_intero <=30
summary$intero_bf_label_30 <-  ifelse(summary$bf_intero > 30, "Interoceptive participants", "Unknown")


# Assign "Non Interoceptive participants" to individuals with bf_non_intero > 30. Assign
# "Unknown" to participants with bf_non_intero <=30
summary$intero_non_bf_label_30 <-  ifelse(summary$bf_non_intero > 30,
                                          "Non interoceptive participants",
                                          "Unknown")


## Assign Final Label for interceptive or non interceptive by checking values in intero_bf_label_30
## and intero_non_bf_label_30
summary$intero_bayes_30 <-  ifelse(summary$intero_bf_label_30 == "Interoceptive participants",
                                   "Interoceptive participants",
                                   "Non interoceptive participants")


### Assign Final Unknown label to individuals where there is not sufficient evidence
## to indicate if interceptive or non-interoceptive
summary$intero_bayes_30 <-  ifelse(summary$intero_bf_label_30 == "Unknown" &
                                   summary$intero_non_bf_label_30 == "Unknown",
                                   "Unknown",
                                   summary$intero_bayes_30)

## remove individuals with Unknown final label (unvomment to remove)
# summary_bayes_30 <- summary %>% filter(intero_bayes_30 != "Unknown")

## if not removing unknowns use this line

summary_bayes_30 <- summary

# numbers in each interoceptive category at BF3
table(summary_bayes$intero_bayes_3)

# numbers in each interoceptive category at BF10
table(summary_bayes_10$intero_bayes_10)

# numbers in each interoceptive category at BF30
table(summary_bayes_30$intero_bayes_30)

write_csv(summary_bayes_30, "summary_bfs.csv")

```

```{r}
#| echo: false
#| output: asis

## create table of classifications at each BF threshold
T2 <- tableby(~intero_bayes_3 +
                intero_bayes_10 +
                intero_bayes_30,
              data = summary_bayes_30)

summary(T2, labelTranslations = list(
  intero_bayes_3 = "BF > 3",
  intero_bayes_10 = "BF > 10",
  intero_bayes_30 = "BF > 30"))

## Create tableby summary and convert to dataframe to access values for text

T2s <- summary(T2, labelTranslations= list(
  intero_bayes_3 = "BF > 3",
  intero_bayes_10 = "BF > 10",
  intero_bayes_30 = "BF > 30"),
  text=NULL)


T2df <- as.data.frame(T2s)

```

At a BF threshold of \>3 **`r toString(T2df[2,2])`** participants were classified as interoceptive. Previous studies using multi-delay heartbeat detection tasks estimate that approximately 1/3 of healthy participants are interoceptive.

# Correlation between similarity scores and heart rate variability

```{r}
#| include: false

### Correlation between Similarity scores and heart rate variability

sim_HRV <- summary_bayes_30 %>% dplyr::select(similarity, mean_HR, hrv_sdnn, hrv_rmssd, hrv_pnn50)

MVNres<-MVN::mvn(sim_HRV)

NormRes <- ifelse(grepl("NO", MVNres$MVN), "non-normal", "normal")

sim_HRV_corS <- cor_test(sim_HRV, vars = similarity, vars2=c("mean_HR","hrv_sdnn","hrv_rmssd","hrv_pnn50"), method = "spearman")

sim_HRV_corP <- cor_test(sim_HRV, vars = similarity, vars2=c("mean_HR","hrv_sdnn","hrv_rmssd","hrv_pnn50"), method = "pearson")

sim_HRV_cor <- bind_rows(sim_HRV_corP, sim_HRV_corS)

sim_HRV_cor<- sim_HRV_cor %>%
  dplyr::select(-c(statistic, conf.low,conf.high)) %>% 
  arrange(desc(var2))

names(sim_HRV_cor) <- c("Var. 1", "Var. 2", "r", "p-value", "Type")

sim_HRV_cor$`Var. 1` <- rep(c("similarity"))

sim_HRV_cor$`Var. 2` <- c("Mean Heart Rate", "Mean Heart Rate",
                              "SDNN", "SDNN",
                              "RMSSD", "RMSSD",
                              "PNN50", "PNN50")

### Correlation in interoceptive participants
int_HRV <- summary_bayes_30 %>%
  filter(intero_bayes_3 =="Interoceptive participants") %>%
  dplyr::select(similarity, mean_HR, hrv_sdnn, hrv_rmssd, hrv_pnn50)

int_HRV_corS<-cor_test(int_HRV, vars = similarity, vars2=c("mean_HR","hrv_sdnn","hrv_rmssd","hrv_pnn50"), method = "spearman")

int_HRV_corP<-cor_test(int_HRV, vars = similarity, vars2=c("mean_HR","hrv_sdnn","hrv_rmssd","hrv_pnn50"), method = "pearson")

int_HRV_cor<-bind_rows(int_HRV_corP, int_HRV_corS)

int_HRV_cor<- int_HRV_cor %>% dplyr::select(-c(statistic, conf.low,conf.high)) %>% arrange(desc(var2))
names(int_HRV_cor)<-c("Var. 1", "Var. 2", "r", "p-value", "Type")

int_HRV_cor$`Var. 1`<-rep(c("similarity"))

int_HRV_cor$`Var. 2`<-c("Mean Heart Rate", "Mean Heart Rate",
                        "SDNN", "SDNN",
                        "RMSSD", "RMSSD",
                        "PNN50", "PNN50")


### Correlation in Non-interoceptive participants
non_HRV <- summary_bayes_30 %>% filter(intero_bayes_3 =="Non interoceptive participants") %>%
  dplyr::select(similarity, mean_HR, hrv_sdnn, hrv_rmssd, hrv_pnn50)

non_HRV_corS <- cor_test(non_HRV, vars = similarity, vars2=c("mean_HR","hrv_sdnn","hrv_rmssd","hrv_pnn50"), method = "spearman")

non_HRV_corP<-cor_test(non_HRV, vars = similarity, vars2=c("mean_HR","hrv_sdnn","hrv_rmssd","hrv_pnn50"), method = "pearson")

non_HRV_cor<-bind_rows(non_HRV_corP, non_HRV_corS)

non_HRV_cor<- non_HRV_cor %>% dplyr::select(-c(statistic, conf.low,conf.high)) %>% arrange(desc(var2))
names(non_HRV_cor)<-c("Var. 1", "Var. 2", "r", "p-value", "Type")

non_HRV_cor$`Var. 1`<-rep(c("similarity"))

non_HRV_cor$`Var. 2`<-c("Mean Heart Rate", "Mean Heart Rate",
                        "SDNN", "SDNN",
                        "RMSSD", "RMSSD",
                        "PNN50", "PNN50")

```

Similarity scores were not correlated with heart rate metrics:

## All participants

```{r}
#| echo: false

knitr::kable(sim_HRV_cor, digits = c(2, 3))

```

## Interoceptive Participants (BF\>3)

```{r}
#| echo: false

knitr::kable(int_HRV_cor, digits = c(2, 3))

```

## Non-Interoceptive Participants (BF\>3)

```{r}
#| echo: false

knitr::kable(non_HRV_cor, digits = c(2, 3))

```

# Correlation between Similarity scores and engagement metrics

```{r}
#| include: false

sim_engage <- summary_bayes_30 %>% dplyr::select(similarity, mean_time_trials, mean_engagement_trials )

MVNres <- MVN::mvn(sim_engage)

NormRes <- ifelse(grepl("NO", MVNres$MVN), "non-normal", "normal")

sim_engage_corS <-cor_test(sim_engage, vars = similarity, vars2=c("mean_time_trials", "mean_engagement_trials"), method = "spearman")

sim_engage_corP <-cor_test(sim_engage, vars = similarity, vars2=c("mean_time_trials", "mean_engagement_trials"), method = "pearson")

sim_engage_cor <-bind_rows(sim_engage_corP, sim_engage_corS)

sim_engage_cor <- sim_engage_cor %>% dplyr::select(-c(statistic, conf.low, conf.high)) %>% arrange(desc(var2))
names(sim_engage_cor) <-c ("Var. 1", "Var. 2", "r", "p-value", "Type")

sim_engage_cor$`Var. 1` <- rep(c("Similarity"))

sim_engage_cor$`Var. 2` <- c("Mean time taken on trials", "Mean time taken on trials",
                           "Mean engagement trials", "Mean engagement trials")

## Correlation in interoceptive participants
int_engage <- summary_bayes_30 %>% filter(intero_bayes_3 =="Interoceptive participants") %>%
  dplyr::select(similarity, "mean_time_trials", "mean_engagement_trials")

int_engage_corS <-cor_test(int_engage, vars = similarity, vars2=c("mean_time_trials", "mean_engagement_trials"), method = "spearman")

int_engage_corP <-cor_test(int_engage, vars = similarity, vars2=c("mean_time_trials", "mean_engagement_trials"), method = "pearson")

int_engage_cor <- bind_rows(int_engage_corP, int_engage_corS)

int_engage_cor <- int_engage_cor %>% dplyr::select(-c(statistic, conf.low,conf.high)) %>% arrange(desc(var2))
names(int_engage_cor) <- c("Var. 1", "Var. 2", "r", "p-value", "Type")

int_engage_cor$`Var. 1`<-rep(c("Similarity"))

int_engage_cor$`Var. 2`<-c("Mean time taken on trials", "Mean time taken on trials",
                           "Mean engagement trials", "Mean engagement trials")


### Correlation in Non-interoceptive participants
non_engage <- summary_bayes_30 %>% filter(intero_bayes_3 =="Non interoceptive participants") %>%
  dplyr::select(similarity,"mean_time_trials", "mean_engagement_trials")

non_engage_corS<-cor_test(non_engage, vars = similarity, vars2=c("mean_time_trials", "mean_engagement_trials"), method = "spearman")

non_engage_corP<-cor_test(non_engage, vars = similarity, vars2=c("mean_time_trials", "mean_engagement_trials"), method = "pearson")

non_engage_cor<-bind_rows(non_engage_corP, non_engage_corS)

non_engage_cor<- non_engage_cor %>% dplyr::select(-c(statistic, conf.low,conf.high)) %>% arrange(desc(var2))
names(non_engage_cor)<-c("Var. 1", "Var. 2", "r", "p-value", "Type")

non_engage_cor$`Var. 1`<-rep(c("Similarity"))

non_engage_cor$`Var. 2`<-c("Mean time taken on trials", "Mean time taken on trials",
                           "Mean engagement trials", "Mean engagement trials")

```

Likewise, there was no evidence of correlation between similarity scores and engagement metrics.

## All participants

```{r}
#| echo: false

knitr::kable(sim_engage_cor, digits = c(2,3))

```

## Interoceptive Participants (BF\>3)

```{r}
#| echo: false

knitr::kable(int_engage_cor, digits = c(2,3))

```

## Non-Interoceptive Participants (BF\>3)

```{r}
#| echo: false

knitr::kable(non_engage_cor, digits = c(2,3))

```

# Differences in HRV / engagement / confidence between interoceptive / non-interoceptive participants (BF\>3)

```{r}
#| include: false

T3 <- tableby(intero_bayes_3~
               similarity +
               confidence_mean +
               mean_HR +
               hrv_sdnn +
               hrv_rmssd +
               hrv_pnn50 +
               mean_time_trials +
               mean_engagement_trials, data = summary_bayes)

```

```{r}
#| echo: false
#| results: asis

summary(
  T3,
  labelTranslations = list(
    intero_bayes_3 = "Classification",
    similarity = "Similarity",
    confidence_mean = "Mean confidence score",
    mean_HR = "Mean heart rate",
    hrv_sdnn = "SDNN",
    hrv_rmssd = "RMSSD",
    hrv_pnn50 = "PNN50",
    mean_time_trials = "Time spent on each trial",
    mean_engagement_trials = "Mean engagement trials"),
  digits = 2)


T3df <- as.data.frame(summary(
  T3,
  labelTranslations = list(
    intero_bayes_3="Classification",
    similarity = "Similarity",
    confidence_mean = "Mean confidence score",
    mean_HR = "Mean heart rate",
    hrv_sdnn = "SDNN",
    hrv_rmssd = "RMSSD",
    hrv_pnn50 = "PNN50",
    mean_time_trials = "Time spent on each trial",
    mean_engagement_trials = "Mean engagement trials"),
  text=TRUE))


```

```{r}
#| echo: false
#| fig-cap:
#| - "Difference in mean heart rate between participants classified as interoceptive, non-interoceptive or unknown."

my_comparisons = list(
  c("Interoceptive participants","Non interoceptive participants"),
  c("Non interoceptive participants", "Unknown"),
  c("Interoceptive participants", "Unknown"))

Mean_HR_P <- ggerrorplot(summary_bayes_30,
              "intero_bayes_3",
              "mean_HR",
              color = "intero_bayes_3",
              desc_stat = "mean_ci") + stat_compare_means(
                comparisons = my_comparisons,
                label.y = c(89, 86, 91),
                label = "p.format",
                method = "t.test"
              )

ggpar(
  Mean_HR_P,
  legend = "none",
  xlab = "Classification",
  ylab = "Mean Heart Rate (95% CI)",
  font.xtickslab = 11,
  caption = "p-values from t-test"
) +
  scale_x_discrete(
    labels = c(
      "Interoceptive \n participants",
      "Non-Interoceptive \n participants",
      "Unknown \n participants"))

```

