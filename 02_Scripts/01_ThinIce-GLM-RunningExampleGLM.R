#Create 30Mar2025 DCR####
#Using code from here: https://github.com/AquaticEcoDynamics/glm-aed/blob/main/glm-examples/example_lakes.Rmd####
#Trying to run GLM3.3.1: dowloaded here: https://github.com/AquaticEcoDynamics/releases/tree/main/GLM-AED
#This also seems to be helpful: https://github.com/robertladwig/GLM_workshop
#CCC suggested Docker/Rocker: https://journal.r-project.org/archive/2017/RJ-2017-065/index.html
  #No idea how to do that, yet!

#Necessary libraries
library(glmtools)
library(tidyverse)

#Move this to the Functions script when created####
#Function to run the GLM code####
run_sim <- function(lake, do_run, glm_exec){
  
  # Get original directory
  orig_dir <- getwd()
  
  # Will return to orignal directory after running the simulation
  on.exit(setwd(orig_dir))
  
  if (do_run){
    setwd(file.path(lake))
    
    # Remove output files before running the simulation to avoid errors
    # "lake.csv", "output.nc"
    output_files <- file.path("output", c("lake.csv", "output.nc"))
    unlink(output_files, recursive = TRUE, force = TRUE)
    
    # Run the simulation
    system2(glm_exec, wait = TRUE, stdout = "", stderr = "") # the added 
    # arguments are so the the output prints to console
  }
} #end of function

#If you want to run the simulations, set `do_run = TRUE`
do_run <- TRUE

#Run the simulation####
lake <- "FCR"

#Set output directories
lake_csv <- file.path(lake, "output/lake.csv") 
nc_file <- file.path(lake, "output/output.nc")

# Best practice to give the full path to the executable e.g. 
# "C:/Users/data/Git/ThinIce-GLM/04_glm_3.3.1a0/glm.exe"
glm_exec <- file.path(getwd(), "04_glm_3.3.1a0/glm.exe")
glm_exec

run_sim(lake, do_run, glm_exec)
# Currently errors because the aed2.nml file is not present in the FCR directory
# If you want to just run the physics then you can either remove or comment out
# using "!", in the "&wq_setup" in the FCR/glm3.nml file (L9-16)

# Load packages, set sim folder, load nml file ####
if (!require('pacman')) install.packages('pacman'); library('pacman')
pacman::p_load(tidyverse, lubridate, ncdf4, GLMr, glmtools)

nml_file<-paste0("FCR","/glm3.nml")
nml<-read_nml(nml_file)
print(nml)

#load GLM3r
if(!require('GLM3r')){remotes::install_github("FLARE-forecast/GLM3r")}
library(GLM3r) #load the library
#Check the version - this is 3.3.0a9 as of 30Mar2025
GLM3r::glm_version()

#I think this runs GLM through CCC's server - which is a previous version####
#This also doesn't work because we don't have the nml file correct, it has aed turned on####
GLM3r::run_glm("FCR",nml_file='glm3.nml',verbose=T)
run_sim(lake, do_run, glm_exec)

#Try to run sparkling example data through GLM3r
nml_file<-paste0("05_Sparkling/glm3.nml")
read_nml(nml_file)
#Ok - nml file reads ok####
#Run through CCC's server
GLM3r::run_glm("05_Sparkling",nml_file='glm3.nml',verbose=T)

# or with new function
run_sim(lake = "05_Sparkling", do_run = TRUE, glm_exec = glm_exec)

#This file is auto-created by GLM3r or by GLM itself
nc_file<-"05_Sparkling/output/output.nc"
#look at the temperature profile####
plot_temp(nc_file)
#get_var gets the variables####
sim_vars(nc_file)
#Plot a variable, e.g., height of ice
plot_var(nc_file, "vol_blue_ice")

#Next steps#####
#Clean this file up - libraries to the top, functions to 00_ThinIce-GLM-Functions.R file####
#Run using Mohonk met data and morphology####
#calibrate physics using real data####
#

