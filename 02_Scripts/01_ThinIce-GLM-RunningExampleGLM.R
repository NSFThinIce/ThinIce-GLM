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
  if(do_run){
    setwd(file.path(lake))
    system2(glm_exec)
  }
} #end of function

#If you want to run the simulations, set `do_run = TRUE`
do_run<-FALSE

#Run the simulation####
lake<-"FCR"

#Set output directories
lake_csv <- file.path(lake, "output/lake.csv") 
nc_file <- file.path(lake, "output/output.nc")

glm_exec<-file.path("04_glm_3.3.1a0")

run_sim(lake, do_run,glm_exec)

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

#Try to run sparkling example data through GLM3r
nml_file<-paste0("05_Sparkling/glm3.nml")
read_nml(nml_file)
#Ok - nml file reads ok####
#Run through CCC's server
GLM3r::run_glm("05_Sparkling",nml_file='glm3.nml',verbose=T)
#This file is auto-created by GLM3r or by GLM itself
nc_file<-"05_Sparkling/output/output.nc"
#look at the temperature profile####
plot_temp(nc_file,col_lim=c(0,30))
#get_var gets the variables####
sim_vars(nc_file)
#Plot a variable, e.g., volume of blue ice
plot_var(nc_file,"vol_blue_ice")

#From FCR-GLMv3.3
getwd() #check this 

system2("04_glm_3.3.1a0/glm.exe", stdout = TRUE, stderr = TRUE, env = "DYLD_LIBRARY_PATH=/04_glm_3.3.1a0/")
#system2(paste0(sim_folder, "/", "glm"), stdout = TRUE, stderr = TRUE, env = paste0("DYLD_LIBRARY_PATH=",sim_folder))
system2('05_Sparkling/glm.bat')

system('run_glm3.bat',ignore.stdout=TRUE)
