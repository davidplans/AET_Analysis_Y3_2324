rm(list = ls(all.names = TRUE)) # clear all objects includes hidden object
dev.off(dev.list()["RStudioGD"])

# load libraries
library(tibble)
library(Select)
library(broom)
library(lme4)
library(readr)
library(dplyr)
library(lmerTest)
library(ggplot2)
library(zip)
library(afex)
library(MuMIn)
library(tidyverse)
library(brms)
library(HDInterval)
library(rstan)
library(devtools)
library(faintr)
library(RColorBrewer)
library(ggmcmc)
library(ggthemes)
library(ggridges)
library(viridis)
library(tidyr)

setwd("C:/Users/Setup/Google Drive/QJEP/OpenData/Data")

##load data files
data_painob_exp2 <- read.csv("experiment2_biological_nonbiological.csv")
data_painob_exp3 <- read.csv("experiment3_biological_nonbiological.csv")

##  now plot experiment 2 data

ggplot(data_painob_exp2, aes(x=fct_inorder(condition), y=effect, group=subject)) +
  geom_point(aes(colour=condition), size=4.5, position=position_dodge(width=0.1)) +
  geom_line(size=1, alpha=0.5, position=position_dodge(width=0.1)) +
  xlab('Condition') +
  ylab('Empathic interference effect') +
  scale_colour_manual(values=c("#009E73", "#D55E00"), guide=FALSE) + 
  theme(axis.text.x = element_text(size=25),
        axis.text.y = element_text(size=25),
        axis.title.x = element_text(size=25),
        axis.title.y = element_text(size=25)) +
  ylim(-200, 200)


##  now plot experiment 3 data

ggplot(data_painob_exp3, aes(fct_inorder(condition), y=effect, group=subject)) +
  geom_point(aes(colour=condition), size=4.5, position=position_dodge(width=0.1)) +
  geom_line(size=1, alpha=0.5, position=position_dodge(width=0.1)) +
  xlab('Condition') +
  ylab('Empathic interference effect') +
  scale_colour_manual(values=c("#009E73", "#D55E00"), guide=FALSE) + 
  theme(axis.text.x = element_text(size=25),
        axis.text.y = element_text(size=25),
        axis.title.x = element_text(size=25),
        axis.title.y = element_text(size=25)) +
  ylim(-200, 200)