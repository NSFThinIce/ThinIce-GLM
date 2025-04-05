#Created 05Apr2025 DCR####
#Initial Run of Mohonk on GLM

#install packages
if(!require('GLM3r')){remotes::install_github("FLARE-forecast/GLM3r")}
if(!require('glmtools')){install.packages(glmtools)}
if(!require('tidyverse')){install.packages()}

#Necessary libraries
library(glmtools)
library(tidyverse)
library(GLM3r) #load the library

#Run functions
source("02_Scripts/00_ThinIce-GLM-Functions.R")

#If you want to run the simulations, set `do_run = TRUE`
do_run <- TRUE

#Run Sparkling as an example####

# # Best practice to give the full path to the executable e.g. 
# # "C:/Users/data/Git/ThinIce-GLM/04_glm_3.3.1a0/glm.exe"
glm_exec <- file.path(getwd(), "04_glm_3.3.1a0/glm.exe")
glm_exec

#Try to run sparkling example data through GLM3r
nml_file<-paste0("05_Sparkling/glm3.nml")
read_nml(nml_file)

#Ok - nml file reads ok####

#RUN SIMULATION THROUGH GLM3r#####
#Check the version - this is 3.3.0a9 as of 30Mar2025
GLM3r::glm_version()
#Run through CCC's server
GLM3r::run_glm("05_Sparkling",nml_file='glm3.nml',verbose=T)

# or with new function
run_sim(lake = "06_Mohonk", do_run = TRUE, glm_exec = glm_exec)

#This file is auto-created by GLM3r or by GLM itself
nc_file<-"06_Mohonk/output/output.nc"
#look at the temperature profile####
plot_temp(nc_file)
#get_var gets the variables####
sim_vars(nc_file)
#Plot a variable, e.g., height of ice
plot_var(nc_file, "vol_white_ice")
#Extract a relevant variables values to store as a df####
get_var(file=nc_file,var_name="blue_ice_thickness")

