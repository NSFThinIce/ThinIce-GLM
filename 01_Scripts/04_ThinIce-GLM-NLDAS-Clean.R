###########################################################
### WARNING: THIS SCRIPT CLEANS NC files from NLDAS downloads####
### Make sure you back up NC files before deleting####
### Current code editor: Dave Richardson: richardsond@newpaltz.edu
### Date: 21Apr2025
### Edited for the modeled lakes, NSF Thin Ice Project
###
### Steps of operation
### 1. Enter relevant data in "Step 1. LAKE DATA"
### 2. Make sure NC files are backed up on computer or external harddrive outside of git
### 2. Run code through to clean NC files off of GIT
###########################################################

##############Add in install.package statements here########### 
if(!require('tidyverse')){install.packages(tidyverse)}

#Load libraries#####
library(tidyverse)

#Run the functions code####
source("01_Scripts/00_ThinIce-GLM-Functions.R")

###########################################################
### Step 1. LAKE DATA ####
###########################################################
lakeNumber<-"08" #number of the folder####
lakeName<-"Bethel" #Lake name here####
years<-2019 #set the year range here, DCR recommends doing 1 year at a time because git can cause R studio to hang up
            #can also be consectutive 2017:2024 or non-consecutive c(2017,2020,2021) ####
##########################################################

###########################################################
### Loop through each year and delete each folder
###########################################################
for(year.index in 1:length(years)){
  ###########################################################
  ### Point to dump directory where data will be saved
  ### This is set automatically based on your lake data above
  ###########################################################
  dumpdir_nc = paste0(lakeNumber,"_",lakeName,"/input/NLDAS/",years[year.index],"/") #where to dump nc files
  
  #Get the list of files####
  nc_files<-list.files(dumpdir_nc)
  #Loop through each file in the year folder####
  for(nc.file.index in 1:length(nc_files)){
    #Get each file name####
    nc_file_name<-paste0(dumpdir_nc,nc_files[nc.file.index])
    #Check the files existence####
    if (file.exists(nc_file_name)) {
      #Delete file if it exists####
      file.remove(nc_file_name)
    }  
  } #End of loop through files####
  
} #end of loop through years####




