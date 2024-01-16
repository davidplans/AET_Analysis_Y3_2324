# Load necessary libraries
library(tidyverse)

# Load the data
data <- read_csv("/Users/david/Downloads/test.csv")

# Data Cleaning
# Remove unnecessary columns, you might need to adjust these based on your dataset
data <- data %>%
  select(-c("UTC Timestamp", "Local Timestamp", "Experiment ID", 
            "Participant Device Type", "Participant Device", "Participant OS", "Participant Browser",
            "Participant Monitor Size", "Participant Viewport Size", "ReactionTime", "TaskName"))

# Convert relevant columns to appropriate types
data$ReactionTime <- as.numeric(data$ReactionTime)
data$Correct <- as.logical(data$Correct)
data$Incorrect <- as.logical(data$Incorrect)

# Basic Data Summary
summary_stats <- data %>%
  group_by(TaskName) %>%
  summarize(
    Mean_Reaction_Time = mean(ReactionTime, na.rm = TRUE),
    Correct_Responses = sum(Correct, na.rm = TRUE),
    Incorrect_Responses = sum(Incorrect, na.rm = TRUE)
  )

# Output summary statistics
print(summary_stats)

# Additional analyses can be added here based on your specific research questions.
# This could include more detailed statistical tests, regressions, or data visualizations.

# Example: Comparing Reaction Times across different Task Types
# (adjust the grouping variable to match your task categories)
reaction_time_comparison <- data %>%
  group_by(stimuli_type) %>%
  summarize(
    Mean_Reaction_Time = mean(Reaction_Time, na.rm = TRUE)
  )

# Plotting the reaction times
ggplot(reaction_time_comparison, aes(x = stimuli_type, y = Mean_Reaction_Time)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Mean Reaction Time by Stimuli Type", x = "Stimuli Type", y = "Mean Reaction Time (ms)")

# Save the plot
ggsave("reaction_time_comparison_plot.png")

# Note: Replace 'path_to_your_data_file.csv' with the actual path to your dataset.
