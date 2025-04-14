###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2019-09-30
### https://github.com/CareyLabVT/Sunapee-GLM/blob/master/NLDASData/getNLDAS_simple.R
### https://github.com/CareyLabVT/Sunapee-GLM/tree/master/NLDASData
###########################################################

# v 04Mar2021: BGS updated to remove hardcoding: only first 43 lines need to be edited

##############Add in install.package statements here########### 
if(!require('RCurl')){install.packages(RCurl)} #Accessing files through URLS
if(!require('lubridate')){install.packages(lubridate)}
if(!require('raster')){install.packages(raster)}
if(!require('ncdf4')){install.packages(ncdf4)} #help downloading the data
if(!require('sf')){install.packages(sf)}
if(!require('httr')){install.packages(httr)}
if(!require('curl')){install.packages(curl)}
if(!require('stringr')){install.packages(stringr)}
if(!require('tidyverse')){install.packages(tidyverse)}

#Load libraries#####
library(RCurl)
library(lubridate)
library(raster)
library(ncdf4)
library(sf)
library(httr)
library(curl)
library(stringr)
library(tidyverse)

#Run the functions code####
source("02_Scripts/00_ThinIce-GLM-Functions.R")

###########################################################
### Enter in some lake and year relevant information####
###########################################################
lakeNumber<-"06" #number of the folder####
lakeName<-"Mohonk" #Lake name here####
year<-2018 #set the year here####
#enter the timezone you would like to have the final data in. see OlsonNames() for options
local_tz_set = 'EST'


###########################################################
### Point to dump directory where data will be saved
###########################################################
dumpdir_nc = paste0(lakeNumber,"_",lakeName,"/input/NLDAS/",year,"/") #where to dump nc files
dumpdir_csv = paste0(lakeNumber,"_",lakeName,"/input/NLDAS_csv/",year,"/") #where to dump csv files
dumpdir_compiled = paste0(lakeNumber,"_",lakeName,"/input/NLDAS_compiled/",year,"/") #where to dump the compiled NLDAS data
dumpdir_input = paste0(lakeNumber,"_",lakeName,"/input/") #where to dump the GLM met data 

#Need to make sure that folders exist for that year####
#If they do not exist, then this will create the folder####
if(!file.exists(dumpdir_nc)){dir.create(file.path(dumpdir_nc))}
if(!file.exists(dumpdir_csv)){dir.create(file.path(dumpdir_csv))}
if(!file.exists(dumpdir_compiled)){dir.create(file.path(dumpdir_compiled))}


###########################################################
### Enter password information
###########################################################
#https://urs.earthdata.nasa.gov/profile <-- GET A EARTHDATA LOGIN
username = 'thiniceproject'
password = 'Cyanotoxin1234!!'

#in addition, make sure you have authorized your account access to the GEODISC archives:
# https://disc.gsfc.nasa.gov/earthdata-login

###########################################################
### Use shapefile of lake to set bounding box
###########################################################
# read in lake file (as a .shp file) to get bounding box
# lakeShape = st_read('shapefile.shp') 
extent = as.numeric(c(-74.06,41.75,-74.05,41.76)) 
#if the extent is loaded from the shapefile (above), make sure they are in decimal degrees, otherwise this code will not work

###########################################################
### Set timeframe
###########################################################
#Get the list of files####
nc_files<-list.files(dumpdir_nc)

#If the folder has character(0) then there is nothing in it (or the folder doesn't exist)
#start at January 1 of the year
if(length(nc_files)==0){
  startdatetime = paste0(year,'-01-01 00:00:00')
}else{
  year0<-substr(nc_files[length(nc_files)],1,4)
  month0<-substr(nc_files[length(nc_files)],5,6)
  day0<-substr(nc_files[length(nc_files)],7,8)
  hour0<-substr(nc_files[length(nc_files)],9,10)
  startdatetime<-paste0(year,'-',month0,'-',day0,' ',hour0,':00:00')
}

enddatetime = paste0(year,'-12-31 23:00:00') #set the end date at the end of the year
loc_tz = 'GMT' #only run in tz's without DST, otherwise you will be very sad when you go to collate and it's a mess. 


# sequence the datetime over your desired time period
out.ts = seq.POSIXt(as.POSIXct(startdatetime, tz = loc_tz),as.POSIXct(enddatetime,tz=loc_tz), by = 'hour')

  #In case any need rerunning, can create a specific list here. SOmetimes, it appears that the download doesn;t work. You can tell this if the nc file size is 2KB instead of 90KB 
  #out.ts<-c(as.POSIXct("2017-07-30 21:00:00", tz = loc_tz),as.POSIXct("2017-07-31 07:00:00", tz = loc_tz),as.POSIXct("2017-08-02 02:00:00", tz = loc_tz),as.POSIXct("2017-09-03 14:00:00", tz = loc_tz),as.POSIXct("2017-09-23 03:00:00", tz = loc_tz),as.POSIXct("2017-09-24 07:00:00", tz = loc_tz),as.POSIXct("2017-09-24 18:00:00", tz = loc_tz),as.POSIXct("2017-09-25 08:00:00", tz = loc_tz),as.POSIXct("2017-11-21 11:00:00", tz = loc_tz),as.POSIXct("2017-11-23 17:00:00", tz = loc_tz),as.POSIXct("2017-12-16 13:00:00", tz = loc_tz))

# Create output list of tables
output = list()

###########################################################
### Run hourly loop
###########################################################
# Start the clock!
ptm <- proc.time()

#Set teh timeout limit - might help if you are gettinng connection timed out after 10006 milliseconds error message
#getOption('timeout')
#options(timeout=20006)


#This takes about 2.7 seconds per download. This is 65 seconds per day, ~32 minutes per month, 6.6 hours per year
for (i in 1:length(out.ts)) {
  print(out.ts[i])
  yearOut = year(out.ts[i])
  monthOut = format(out.ts[i], "%m")
  dayOut = format(out.ts[i], "%d")
  hourOut = format(out.ts[i], "%H%M")
  doyOut = format(out.ts[i],'%j')
  
  filename = format(out.ts[i], "%Y%m%d%H%M")
  
  #Get URL for FORA which has 12 output variables including long wave radiation####
  #Trying to match up with the URL from FORA gotten from subsetting data here and downloading links list####
  #https://disc.gsfc.nasa.gov/datasets/NLDAS_FORA0125_H_2.0/summary?keywords=NLDAS
  #                  https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.2.0%2F
  #                  2017%2F
  #                  001
  #                  %2FNLDAS_FORA0125_H.A
  #                  20170101.
  #                  0000
  #                  .020.nc
  #                  &SERVICE=L34RS_LDAS
  #                  &VERSION=1.02
  #                  &SHORTNAME=NLDAS_FORA0125_H
  #                  &BBOX=25%2C-125%2C53%2C-67
  #                  &LABEL=NLDAS_FORA0125_H.A
  #                  20170101.0000.
  #                  020.nc.SUB.nc4
  #                  &FORMAT=bmM0Lw
  #                  &DATASET_VERSION=2.0
  
    URL_FORA <- paste('https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.2.0%2F',
                    yearOut, '%2F',
                    str_pad(as.numeric(yday(as.Date(paste0(yearOut,"-", monthOut,'-' ,dayOut)))), 3, pad = "0"), ## The URL changes for every chunk of 24 hours
                    '%2FNLDAS_FORA0125_H.A',
                    yearOut, monthOut, dayOut, '.',
                    hourOut,  
                    '.020.nc',
                    '&SERVICE=L34RS_LDAS',
                    '&VERSION=1.02',
                    '&SHORTNAME=NLDAS_FORA0125_H',
                    '&BBOX=',
                    round(extent[2], 2),'%2C', # In the new version of the URL, the coordinates are only up to 2 digits
                    round(extent[1], 2),'%2C',
                    round(extent[4], 2),'%2C',
                    round(extent[3], 2),
                    '&LABEL=NLDAS_FORA0125_H.A',
                    yearOut, monthOut, dayOut, '.',
                    hourOut,
                    '.020.nc.SUB.nc4',
                    '&FORMAT=bmM0Lw',
                    #'&VARIABLES=Tair', #Commenting this out gets all the variables
                    '&DATASET_VERSION=2.0',
                    sep='')  
  
  #Try updating to match this which comes from the hourly forcing subsetting from GES DISC
  #https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORB0125_H.2.0%2F2017%2F001%2FNLDAS_FORB0125_H.A20170101.0000.020.nc&LABEL=NLDAS_FORB0125_H.A20170101.0000.020.nc.SUB.nc4&VERSION=1.02&SERVICE=L34RS_LDAS&FORMAT=bmM0Lw&VARIABLES=Tair&SHORTNAME=NLDAS_FORB0125_H&BBOX=41.759%2C-74.06%2C41.762%2C-74.057&DATASET_VERSION=2.0
  #This will get FORB which doesn't have long wave radiation 
  URL_FORB <- paste('https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORB0125_H.2.0%2F',
               yearOut, '%2F',
               str_pad(as.numeric(yday(as.Date(paste0(yearOut,"-", monthOut,'-' ,dayOut)))), 3, pad = "0"), ## The URL changes for every chunk of 24 hours
               '%2FNLDAS_FORB0125_H.A',
               yearOut, monthOut, dayOut, '.',
               hourOut,  
               '.020.nc',
               '&LABEL=NLDAS_FORA0125_H.A',
               yearOut, monthOut, dayOut, '.',
               hourOut,
               '.020.nc.SUB.nc4&',
               'VERSION=1.02&SERVICE=L34RS_LDAS&FORMAT=bmM0Lw',
               #'&VARIABLES=Tair', #Commenting this out gets all the variables
               '&SHORTNAME=NLDAS_FORA0125_H',
               '&BBOX=', 
               round(extent[2], 2),'%2C', # In the new version of the URL, the coordinates are only up to 2 digits
               round(extent[1], 2),'%2C',
               round(extent[4], 2),'%2C',
               round(extent[3], 2),
               '&DATASET_VERSION=2.0',
               sep='')
  
  # URL <- paste('https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.002%2F',
  #              yearOut, '%2F',
  #              str_pad(as.numeric(yday(as.Date(paste0(yearOut,"-", monthOut,'-' ,dayOut)))), 3, pad = "0"), ## The URL changes for every chunk of 24 hours
  #              '%2FNLDAS_FORA0125_H.A',
  #              yearOut, monthOut, dayOut, '.',
  #              hourOut,  '.002.grb&FORMAT=bmM0Lw&BBOX=', 
  #              round(extent[2], 2),'%2C', # In the new version of the URL, the coordinates are only up to 2 digits
  #              round(extent[1], 2),'%2C',
  #              round(extent[4], 2),'%2C',
  #              round(extent[3], 2),
  #              '&LABEL=NLDAS_FORA0125_H.A',
  #              yearOut,monthOut,dayOut,'.',
  #              hourOut,
  #              '.002.grb.nc4&SHORTNAME=NLDAS_FORA0125_H&SERVICE=L34RS_LDAS&VERSION=1.02&DATASET_VERSION=002',
  #              sep='')
  
  # IMPORTANT MESSAGE Dec 05, 2016    The GES DISC will be migrating from http to https throughout December
  # As part of our ongoing migration to HTTPS, the GES DISC will begin redirecting all HTTP traffic to HTTPS.
  # We expect to have all GES DISC sites redirecting traffic by January 4th. For most access methods, the redirect will be transparent to the user.
  # However, users with locally developed scripts or utilities that do not support an HTTP code 301 redirect may find that the scripts will fail.
  # If you access our servers non-interactively (i.e. via a mechanism other than a modern web browser), you will want to modify your scripts to
  # point to the HTTPS addresses to avoid the enforced redirect.
  
  # x = download.file(URL3,destfile = paste(filename,'.nc',sep=''),mode = 'wb',quiet = T)
  # x = download.file(URL,destfile = paste(filename,'.nc',sep=''),mode = 'wb',quiet = T)
  
  
  lk <- URL_FORA #Can also use FORB if not needing long wave radiation
  
  #wget:
  #r <- GET(lk,
  #          authenticate("ptran5@wisc.edu", "Earthdata1"),
  #          path = "~/Documents/MendotaRawData/")
  
  # or this with curl
  h <- curl::new_handle()
  
  #A handle is used to configure a request with custom options, headers and payload. Once the handle has been set up, it can be passed to any of the download functions such as curl()####
  curl::handle_setopt(
    handle = h,
    httpauth = 1,
    userpwd = paste0(username, ':', password)
  )
  
  # resp <- curl::curl_fetch_memory(lk, handle = h)
  resp <- curl::curl_fetch_disk(url = lk, 
                                path = paste(dumpdir_nc, filename, '_', loc_tz, '.nc',sep=''), 
                                handle = h)
  
  Sys.sleep(2)
  
}

#If there are time out errors (it seems like it might be a campus issue with a firewall), here is a possible way to fix it:
#https://stackoverflow.com/questions/35282928/how-do-i-set-a-timeout-for-utilsdownload-file-in-r

# Stop the clock
proc.time() - ptm



#### step 2: save each variable as a new csv ####

#Location where nc files are stored: dumpdir_nc
#nc_files<-list.files(dumpdir_nc)

###########################################################
### Need to know how many cells your lake falls within
### Can download one instance of data from the earthdata site and see how many columns there are
### use 'nc_open(filename)' to see how many cells there are
###########################################################
br<-nc_open(paste0(dumpdir_nc,nc_files[1]))
br
nc_close(br)
#if there are only 2 variables, time and the variable, then there should be only 1 cell####
cellNum=1 #number of cells in your area of interest

###########################################################
### Set up the output data frame
###########################################################
#vars for FORA - FORB is slightly different####
vars_nc = c('Tair', #standard_name: Near surface air temperature #long_name: NARR hybrid level Temperature #units: K
            'Qair', #standard_name: Near surface specific humidity #long_name: NARR hybrid level Specific humidity #units: kg kg-1
            'PSurf', #standard_name: Near surface pressure #long_name: NARR hybrid level Surface pressure #units: Pa
            'Wind_E', #standard_name: Near surface eastward wind component #long_name: NARR hybrid level Zonal wind speed #units: m s-1
            'Wind_N', #standard_name: Near surface northward wind component #long_name: NARR hybrid level Meridional wind speed #units: m s-1
            'LWdown', #standard_name: Surface incident longwave radiation #long_name: Longwave radiation flux downwards (surface) #W m-2
            'CRainf_frac', #standard_name: Convective precipitation fraction #long_name: Fraction of total precipitation that is convective #units: fraction
            'CAPE', #standard_name: Convective Available Potential Energy #long_name: Convective Available Potential Energy #units: J kg-1
            'PotEvap', #standard_name: Potential evaporation #long_name: Potential evaporation #units: kg m-2
            'Rainf', #standard_name: Total precipitation #long_name: Total precipitation #units: kg m-2
            'SWdown' #standard_name: Surface incident shortwave radiation #long_name: Shortwave radiation flux downwards (surface) #units: W m-2
            )
           #vars for FORB####
           #'CRainf', #standard_name: Convective precipitation #long_name: Convective precipitation #units: kg m-2
           #'ACond', #standard_name: Aerodynamic conductance #long_name: Aerodynamic conductance #units: m s-1
           #'PhiS' #standard_name: Near surface geopotential height #long_name: NARR hybrid level Geopotential height #units: gpm



#set up output dataframe for the number of cells above and the number of columns of data
output <- NULL
for (l in 1:length(vars_nc)){
  colClasses = c("POSIXct", rep("numeric",cellNum))
  col.names = c('dateTime',rep(vars_nc[l],cellNum))
  output[[l]] = read.table(text = "",colClasses = colClasses,col.names = col.names)
  attributes(output[[l]]$dateTime)$tzone = 'GMT'
}

###########################################################
### Run file list loop
###########################################################

# Start the clock!
ptm <- proc.time()
#About 0.1 seconds per file, ~15 minutes for the year####

#Loop through each of the nc files####
#*This loop will crash if any of the nc files have not downloaded correctly####
#**In that case, find the files that have not downloaded correctly by going to the folder and seeing which are <90KB, then go up to setting up the out.ts with specific dates (~Line 82) and rerun the download loop for those files
for (i in 1:length(nc_files)) {
  #*Print out the nc file name####
  print(nc_files[i])
  #*Loop through the variables####
  for (v in 1:length(vars_nc)) {
    nldasvar <- vars_nc[v]
    br = nc_open(paste0(dumpdir_nc, nc_files[i]))
    output[[v]][i,1] =  as.POSIXct(paste0(substr(nc_files[i], 1, 4),'-', substr(nc_files[i], 5,6), '-', substr(nc_files[i], 7,8), ' ', substr(nc_files[i], 9,10), ':', substr(nc_files[i], 11,12)), tz=loc_tz)
    output[[v]][i,-1] = ncvar_get(br, nldasvar)
    nc_close(br)
  }
  rm(br)
}

# Stop the clock
proc.time() - ptm

###########################################################
### save each variable in a .csv
###########################################################
for (f in 1:length(vars_nc)){
  write_csv(output[[f]],paste0(dumpdir_csv, vars_nc[f],'.csv'))
}


#------------------------------------------------------------------#
#### step 3: merge NLDAS csv files together ####

box = 1 # Chosen cell of 'cellNum' from combineNLDAS.R, you'll have to look at these to figure out which one is best.

###########################################################
### run loop to collate all data
###########################################################

# # make a list of the files previously collated
files = list.files(dumpdir_csv, pattern = '.csv')
# 
# #Find the date from the first and last nc file####
# nc_file_startdatetime<-nc_files[1]
# 
# year_final<-substr(nc_files[length(nc_files)],1,4)
# month_final<-substr(nc_files[length(nc_files)],5,6)
# day_final<-substr(nc_files[length(nc_files)],7,8)
# hour_final<-substr(nc_files[length(nc_files)],9,10)
# nc_file_enddatetime<-paste0(year,'-',month0,'-',day0,' ',hour0,':00:00')
# 
# 
# #make a null dataframme with the sequence of datetimes from above
# final.box = data.frame(dateTime = seq.POSIXt(
#   as.POSIXct(output[[1]]$dateTime[1], tz= loc_tz),
#   as.POSIXct(output[[1]]$dateTime[length(output[[1]]$dateTime)],tz=loc_tz),by = 'hour'))

#index each box csv to break out each of the cells
for (i in 1:length(files)){
  #Find which variable matches with the abcs of the files in the folder with csvs
  #fileIndx = grep(vars_nc[i],files)
  
  #Get out the data and set the date time
  df = read_csv(paste0(dumpdir_csv,files[i]))%>% 
    dplyr::mutate(dateTime = as.POSIXct(dateTime, tz=loc_tz,
                                        "%Y-%m-%d %H:%M:%S")) |> 
    arrange(dateTime) # chronological order   
  
  #Check and see if there are more than 1 version of that variable, if so, bind them together
  # if(length(fileIndx) >1) {
  #   for (f in 2:length(fileIndx)){
  #     df2 = read.csv(paste0(dumpdir_csv, files[fileIndx[f]]))
  #     df = rbind(df,df2)
  #   }
  # }
  
  # Total time series from first dateTime to last####
  out = data.frame(dateTime = seq.POSIXt(
    as.POSIXct(df$dateTime[1], tz= loc_tz),
    as.POSIXct(df$dateTime[length(df$dateTime)],tz=loc_tz),by = 'hour')) 
  
  #Join together to check for any missing dates in time series####
  missingDates = out |> 
    anti_join(df)
  print(nrow(missingDates)) # Check for missing dates. 
  
  #Checking for replicate time stamps####
  out = out %>% 
    left_join(df)
  print(nrow(out))
  # out <- distinct(out) #check for duplicate time stamps
  
  #Export to the compiled file
  out %>% 
    mutate(dateTime = as.character(dateTime)) %>% 
    write_csv(.,paste0(dumpdir_compiled,
                       format(as.POSIXct(startdatetime), '%Y-%m-%d'),
                       '_', format(as.POSIXct(enddatetime), '%Y-%m-%d'),
                       '_', vars_nc[i],'.csv'))
  #If it is the first file, then use that as the output, if not, then merge with previous####
  if(i==1){final.box<-out}else{
    final.box <- final.box %>% 
      left_join(out)  
  }

}

####### Create a Single Dataframe and adjust time zone###########
head(final.box)
tail(final.box)
which(duplicated(final.box)) #check for duplicate time stamps - if this list is long, something is wrong!! There should be ZERO duplicated timestamps.
# final.box <- distinct(final.box)
which(is.na(final.box$Tair)) # check for NA values in specific columns

# adjust to local timezone #
final.box <- final.box %>% 
  mutate(local_dateTime = with_tz(dateTime, tzone = local_tz_set))
head(final.box)

#Ranme and calculate some import drivers for GLM-AED####
drivers <- final.box %>% 
  dplyr::rename(PotentialEvap = PotEvap, ##
                LongWave.W_m2=LWdown, 
                ShortWave.W_m2=SWdown,
                ConvectivePotentialEnergy = CAPE,
                Precipitation = Rainf,
                SpecHumidity.kg_kg=Qair,
                WindSpeed_Zonal = Wind_E, 
                WindSpeed_Meridional = Wind_N,
                AirTemp2m = Tair,
                SurfPressure.Pa = PSurf)%>%
  dplyr::mutate(RelHum = 100*SpecHumidity.kg_kg/qsat(AirTemp2m-273.15, SurfPressure.Pa*0.01), #calculate relative humidity
                WindSpeed.m_s=sqrt(WindSpeed_Zonal^2+WindSpeed_Meridional^2), #calculate wind speed from the two directions###
                AirTemp.C = AirTemp2m - 273.15,  #Convert air temperature to celcius from kelvin
                )%>%  
  dplyr::mutate(Snow.m_day=ifelse(AirTemp.C<0,Precipitation*24/1000,0),
                Rain.m_day=ifelse(AirTemp.C>=0,Precipitation*24/1000,0)
                )%>% #Split precip into snow (when air temp is <0) or rain (when air temp >0), see note below 
  dplyr::select(local_dateTime,AirTemp.C,ShortWave.W_m2,LongWave.W_m2,
                SpecHumidity.kg_kg,RelHum,WindSpeed.m_s,Rain.m_day,Snow.m_day,SurfPressure.Pa)

              #Ignoring convective precip: ConvectivePrecip = CONVfrac*Precipitation, convective precip is heavy localized rainfall like summer thunderstorms
#For Snow####
#From All models use a threshold air temperature of 0°C to partition the precipitation inputs, such that if the air temperature is above this value then the precipitation is considered to be rainfall, and is considered to be snowfall if the air temperature is below this value.
#Xia et al. 2012: https://agupubs.onlinelibrary.wiley.com/doi/10.1029/2011JD016048

#Confirm that there is not repeated time steps
drivers |> 
  group_by(local_dateTime) %>% 
  filter(n()>1) 

#Format specifically for met GLM data####
drivers <- drivers %>% 
  rename(time = local_dateTime,
         ShortWave = ShortWave.W_m2,
         LongWave = LongWave.W_m2,
         AirTemp = AirTemp.C,
         WindSpeed = WindSpeed.m_s,
         Rain = Rain.m_day,
         Snow = Snow.m_day ) %>% 
  select(-c(SurfPressure.Pa, SpecHumidity.kg_kg))

#Plot a few of the drivers####
plot(drivers$time,drivers$Rain,type = 'l')
plot(drivers$time,drivers$Snow,type = 'l')
plot(drivers$time,drivers$ShortWave,type = 'l')


#Find the initial and final day for the file name####
#This is now in local time zone so it might be a day earlier than January 1
year_start<-substr(drivers$time[1],1,4)
month_start<-substr(drivers$time[1],6,7)
day_start<-substr(drivers$time[1],9,10)

#This is now in local time zone so it might be a day earlier than January 1
year_final<-substr(drivers$time[length(drivers$time)],1,4)
month_final<-substr(drivers$time[length(drivers$time)],6,7)
day_final<-substr(drivers$time[length(drivers$time)],9,10)


drivers$time[1]
#save combined nldas file####
write_csv(drivers,paste0(dumpdir_input,lakeName, '_', 
                   paste(year_start,month_start,day_start,sep="_"),
                   '_to_', 
                   paste(year_final,month_final,day_final,sep="_"),
                   '_hourly.csv'))

