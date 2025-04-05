###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2017-01-20
### Modified for Thin Ice project
### Author: Dave Richardon richardsond@newpaltz.edu
### Date: 2025-04-05
######################################################z #####
rm(list=ls())

#Packages####
if(!require(RCurl)){install.packages("RCurl")}
if(!require(lubridate)){install.packages("lubridate")}
if(!require(raster)){install.packages("raster")}
if(!require(ncdf4)){install.packages("ncdf4")}
if(!require(rgdal)){install.packages("rgdal")}
if(!require(httr)){install.packages("httr")}

library(RCurl)
library(lubridate)
library(raster)
library(ncdf4)
library(rgdal)
library(httr)

###########################################################
### Enter password information
###########################################################
#https://urs.earthdata.nasa.gov/profile <-- GET A EARTHDATA LOGIN
username = "thiniceproject"
password = "Cyanotoxin1234!!"

###########################################################
### Use shapefile of lake to set bounding box
###########################################################
# read in lake file to get bounding box
# Mendota Example
#lakeShape = readOGR('forNLDAS.shp',layer='forNLDAS')
#extent = as.numeric(lakeShape@bbox)
extent = c(-74.05990,41.75868,-74.05723,41.76179)

###########################################################
### Set timeframe
###########################################################
out = seq.POSIXt(as.POSIXct('2017-01-01 00:00',tz = 'GMT'),as.POSIXct('2025-01-01 00:00',tz='GMT'),by = 'hour')
vars = c('PEVAPsfc_110_SFC_acc1h', 'DLWRFsfc_110_SFC', 'DSWRFsfc_110_SFC', 'CAPE180_0mb_110_SPDY',
         'CONVfracsfc_110_SFC_acc1h', 'APCPsfc_110_SFC_acc1h', 'SPFH2m_110_HTGL',
         'VGRD10m_110_HTGL', 'UGRD10m_110_HTGL', 'TMP2m_110_HTGL', 'PRESsfc_110_SFC')

# Create output list of tables
output = list()

###########################################################
### Need to know how many cells your lake falls within
### Can download one instance of data and see how many columns there are
###########################################################
cellNum = 4 #How many output cells will there be? Need to check this beforehand
for (l in 1:11){
  colClasses = c("POSIXct", rep("numeric",cellNum))
  col.names = c('dateTime',rep(vars[l],cellNum))
  output[[l]] = read.table(text = "",colClasses = colClasses,col.names = col.names)
  attributes(output[[l]]$dateTime)$tzone = 'GMT'
}


#Not working - check this:
#https://rdrr.io/github/lawinslow/nldasR/


###########################################################
### Run hourly loop
###########################################################
# Start the clock!
ptm <- proc.time()
#
for (i in 1:length(out)) {
  print(out[i])
  yearOut = year(out[i])
  monthOut = format(out[i], "%m")
  dayOut = format(out[i], "%d")
  hourOut = format(out[i], "%H%M")
  doyOut = format(out[i],'%j')
  
  filename = format(out[i], "%Y%m%d%H%M")
  
  URL3 = paste('https://',username,':',password,'@hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?',
               'FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.002%2F',yearOut,'%2F',doyOut,'%2FNLDAS_FORA0125_H.A',yearOut,monthOut,dayOut,'.',hourOut,'.002.grb&',
               'FORMAT=bmV0Q0RGLw&BBOX=',extent[2],'%2C',extent[1],'%2C',extent[4],'%2C',extent[3],'&',
               'LABEL=NLDAS_FORA0125_H.A',yearOut,monthOut,dayOut,'.',hourOut,'.002.2017013163409.pss.nc&',
               'SHORTNAME=NLDAS_FORA0125_H&SERVICE=SUBSET_GRIB&VERSION=1.02&DATASET_VERSION=002',sep='')
  
  
  # IMPORTANT MESSAGE Dec 05, 2016    The GES DISC will be migrating from http to https throughout December
  # As part of our ongoing migration to HTTPS, the GES DISC will begin redirecting all HTTP traffic to HTTPS.
  # We expect to have all GES DISC sites redirecting traffic by January 4th. For most access methods, the redirect will be transparent to the user.
  # However, users with locally developed scripts or utilities that do not support an HTTP code 301 redirect may find that the scripts will fail.
  # If you access our servers non-interactively (i.e. via a mechanism other than a modern web browser), you will want to modify your scripts to
  # point to the HTTPS addresses to avoid the enforced redirect.
  
  library(httr)
  x = download.file(URL3,destfile = paste(filename,'.nc',sep=''),mode = 'wb',quiet = T)
  
  for (v in 1:11) {
    br = brick(paste(filename,'.nc',sep=''),varname = vars[v])
    output[[v]][i,1] = out[i]
    output[[v]][i,-1] = getValues(br[[1]])
  }
  rm(br)
  #Sys.sleep(2)
}
# Stop the clock
proc.time() - ptm

###########################################################
### Save all 11 variables from the output list
###########################################################

###########################################################  



for (i in 1:length(out)) {
  print(out[i])
  filename = format(out[i], "%Y%m%d%H%M")
  for (v in 1:11) {
    br = brick(paste(filename,'.nc',sep=''),varname = vars[v])
    output[[v]][i,1] = out[i]
    output[[v]][i,-1] = getValues(br[[1]])
  }
  rm(br)
}

for (f in 1:11){
  write.csv(output[[f]],paste('LakeName_',vars[f],'.csv',sep=''),row.names=F)
}


rm(list=ls())
options(scipen=999)
#setwd("C:/Users/melofton/Documents/Sunapee/")
pressure<-read.csv("LakeName_PRESsfc_110_SFC.csv") #PRES = surface Pressure [Pa]
temperature<-read.csv("LakeName_TMP2m_110_HTGL.csv") #TMP = 2 m aboveground temperature [K]
precip<-read.csv("LakeName_APCPsfc_110_SFC_acc1h.csv") #APCP = precipitation hourly total [kg/m2]
#LakeName_CAPE180_0mb_110_SPDY #CAPE = 180-0 mb above ground Convective Available Potential Energy [J/kg]
#LakeName_CONVfracsfc_110_SFC_acc1h #CONVfrac = fraction of total precipitation that is convective [unitless]
humidity<-read.csv("LakeName_SPFH2m_110_HTGL.csv") #SPFH = 2 m aboveground Specific humidity [kg/kg]
windx<-read.csv("LakeName_UGRD10m_110_HTGL.csv") #UGRD = 10 m aboveground Zonal wind speed [m/s]
windy<-read.csv("LakeName_VGRD10m_110_HTGL.csv") #VGRD = 10 m aboveground Meridional wind speed [m/s]
longwave<-read.csv("LakeName_DLWRFsfc_110_SFC.csv") #DLWRF = longwave radiation flux downwards (surface) [W/m2]
shortwave<-read.csv("LakeName_DSWRFsfc_110_SFC.csv") #DSWRF = shortwave radiation flux downwards (surface) [W/m2]
LakeName_PEVAPsfc_110_SFC_acc1h #PEVAP = potential evaporation hourly total [kg/m2]

library(dplyr)
temperature<-temperature%>%mutate(temp.dC=TMP2m_110_HTGL-273.15)
precip<-precip%>%mutate(precip.m.day=APCPsfc_110_SFC_acc1h/1000*24)
pressure<-pressure%>%mutate(pressure.mb=PRESsfc_110_SFC/100)

##' Convert specific humidity to relative humidity
##'
##' converting specific humidity into relative humidity
##' NCEP surface flux data does not have RH
##' from Bolton 1980 The computation of Equivalent Potential Temperature 
##' \url{http://www.eol.ucar.edu/projects/ceop/dm/documents/refdata_report/eqns.html}
##' @title qair2rh
##' @param qair specific humidity, dimensionless (e.g. kg/kg) ratio of water mass / total air mass
##' @param temp degrees C
##' @param press pressure in mb
##' @return rh relative humidity, ratio of actual water mixing ratio to saturation mixing ratio
##' @export
##' @author David LeBauer
qair2rh <- function(qair, temp, press = 1013.25){
  es <-  6.112 * exp((17.67 * temp)/(temp + 243.5))
  e <- qair * press / (0.378 * qair + 0.622)
  rh <- e / es
  rh[rh > 1] <- 1
  rh[rh < 0] <- 0
  return(rh)
}

temp1<-subset(temperature,select=c("dateTime","temp.dC"))
shortwave1<-subset(shortwave,select=c("dateTime","DSWRFsfc_110_SFC"))
long1<-subset(longwave,select=c("dateTime","DLWRFsfc_110_SFC"))
prec1<-subset(precip,select=c("dateTime","precip.m.day"))
specif.hum<-subset(humidity,select=c("dateTime","SPFH2m_110_HTGL"))
wind<-subset(windx,select=c("dateTime","UGRD10m_110_HTGL"))
wind2<-subset(windy,select=c("dateTime","VGRD10m_110_HTGL"))
met<-shortwave1%>%left_join(long1)%>%left_join(temp1)%>%left_join(specif.hum)%>%left_join(prec1)%>%left_join(pressure)%>%
  left_join(wind)%>%left_join(wind2)
met<-met%>%mutate(es=6.112 * exp((17.67 * temp.dC)/(temp.dC + 243.5)))%>%
  mutate(e=SPFH2m_110_HTGL * pressure.mb / (0.378 * SPFH2m_110_HTGL + 0.622))%>%
  mutate(rh=e/es)

met$rh[met$rh > 1] <- 1
met$rh[met$rh < 0] <- 0

met<-met%>%mutate(rh=rh*100)

met<-met%>%mutate(wind.m_s=sqrt(UGRD10m_110_HTGL^2+VGRD10m_110_HTGL^2))

met<-subset(met,select=c("dateTime","DSWRFsfc_110_SFC","DLWRFsfc_110_SFC","temp.dC","rh","wind.m_s","precip.m.day"))
names(met)[names(met)==c("dateTime","DSWRFsfc_110_SFC","DLWRFsfc_110_SFC","temp.dC","rh","wind.m_s","precip.m.day")]<-c("time","ShortWave","LongWave","AirTemp","RelHum","WindSpeed","Rain")

#Add in snow as 0####
met<-met%>%mutate(Snow=0)

#Write out met data####
write.csv(met,"MohonkMet_2017_hourly.csv",row.names = FALSE,quote = FALSE)

