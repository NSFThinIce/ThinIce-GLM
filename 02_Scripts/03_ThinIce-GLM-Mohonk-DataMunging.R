#Create 05Apr2025 DCR####
#Munging any data to get ready for GLM model input, validation, or comparison####

#install packages
if(!require('tidyverse')){install.packages()}
#Necessary libraries
library(tidyverse)


#Get all the mesonet together####

#*directory for mesonet####
dirPath<-"06_Mohonk/data/mesonet_data/"

#*Identify all the individual .csv files####
files<-list.files(dirPath,pattern = "*.csv")

#*Create storage location ####
weather.list<-list()

#*run through all the files and import them####
for(file.i in 1:length(files)){
  #**Import each of the weather files in####
  weather.list[[file.i]]<-read_csv(paste0(dirPath,files[file.i]))
  #print(paste0(dirPath,files[file.i]))
  
} #*end of for loop####

#*row bind all the existing weather data together####
weather_df<-do.call(bind_rows,weather.list)%>%
            mutate(time=ymd_hms(time_end), #**make time_end from character into time variable####
                   
                   )   

#*Check the names of the weather data####
#names(weather_df)

#*Create an initial plot of a variable####
ggplot(data=weather_df,aes(x=time,y=`temp_2m_max [degC]`))+geom_point()
