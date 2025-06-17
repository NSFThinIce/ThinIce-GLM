### Steps of operation
### 1. Enter relevant data in "Step 1. LAKE DATA"
### 2. Run code through "END Step 2. DOWNLOAD NC DATA"
###    2a. If you stop downloading partway through, just pick up back here the next time you start up. 
### 3. Check the folder with nc files (ThinIce-GLM\LAKE\input\NLDAS\YEAR) on your computer. Sort the nc files by size and see if there are any small files with incomplete downloads
###    3a. Go back to 'Step 3. RERUN MISSING NC FILES' and enter those specific Date/Times into the commented out data frame
###    3b. Rerun the Step 2 loop
###    3c. Recheck the nc file folder to make sure all the files are the same size (~90 KB on a Windows OS)
### 4. Run 'Step 4. EXTRACT DATA FROM NC' to get all the variables out of the NC files and put them together
### 5. Run code in 'Step 5. QA/QC CHECKS'
###    5a. This code checks to make sure there aren't any missing or repeated rows
###    5b. Rerun some specific date/times using step 3 if so
### 6. Run 'Step 6. PREPARE FOR GLM FORMAT AND EXPORT' to get the date/time local and the variables are formatted correctly
###    6a. Make sure the file exported correctly
###########################################################

##############Add in install.package statements here########### 
if(!require('RCurl')){install.packages('RCurl')} #Accessing files through URLS
if(!require('lubridate')){install.packages('lubridate')}
if(!require('raster')){install.packages('raster')}
if(!require('ncdf4')){install.packages('ncdf4')} #help downloading the data
if(!require('sf')){install.packages('sf')}
if(!require('httr')){install.packages('httr')}
if(!require('curl')){install.packages('curl')}
if(!require('stringr')){install.packages('stringr')}
if(!require('tidyverse')){install.packages('tidyverse')}
if(!require('rvest')){install.packages('rvest')} # For parsing HTML during authentication

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
library(rvest)

#Run the functions code####
source("01_Scripts/00_ThinIce-GLM-Functions.R")

###########################################################
### Step 1. LAKE DATA ####
###########################################################
lakeNumber<-"11" #number of the folder####
lakeName<-"Shelburne" #Lake name here####
year<-2022 #set the year here####
local_tz_set = "US/Eastern" #enter the timezone you would like to have the final data in. see OlsonNames() for options####
loc_tz = 'GMT' #only run in tz's without DST, otherwise you will be very sad when you go to collate and it's a mess.####
extent = as.numeric(c(-73.16,44.37,-73.15,44.40)) #Enter in the decimal degree bounding box of your lake rounded to two decimals####
#if the extent is loaded from the shapefile (above), make sure they are in decimal degrees, otherwise this code will not work
##########################################################

###########################################################
### Point to dump directory where data will be saved
### This is set automatically based on your lake data above
###########################################################
dumpdir_nc = paste0(lakeNumber,"_",lakeName,"/input/NLDAS/",year,"/") #where to dump nc files
dumpdir_csv = paste0(lakeNumber,"_",lakeName,"/input/NLDAS_csv/",year,"/") #where to dump csv files
dumpdir_compiled = paste0(lakeNumber,"_",lakeName,"/input/NLDAS_compiled/",year,"/") #where to dump the compiled NLDAS data
dumpdir_input = paste0(lakeNumber,"_",lakeName,"/input/") #where to dump the GLM met data 

#Need to make sure that folders exist for the NLDAS outputs####
#If they do not exist, then this will create the folder####
if(!file.exists(paste0(lakeNumber,"_",lakeName,"/input/NLDAS/"))){dir.create(file.path(paste0(lakeNumber,"_",lakeName,"/input/NLDAS/")))}
if(!file.exists(paste0(lakeNumber,"_",lakeName,"/input/NLDAS_csv/"))){dir.create(file.path(paste0(lakeNumber,"_",lakeName,"/input/NLDAS_csv/")))}
if(!file.exists(paste0(lakeNumber,"_",lakeName,"/input/NLDAS_compiled/"))){dir.create(file.path(paste0(lakeNumber,"_",lakeName,"/input/NLDAS_compiled/")))}

#Need to make sure that folders exist for that year####
#If they do not exist, then this will create the folder####
if(!file.exists(dumpdir_nc)){dir.create(file.path(dumpdir_nc))}
if(!file.exists(dumpdir_csv)){dir.create(file.path(dumpdir_csv))}
if(!file.exists(dumpdir_compiled)){dir.create(file.path(dumpdir_compiled))}

###########################################################
### Enter password information
###########################################################
username <- "thiniceproject"
password <- "Cyanotoxin1234!!"  

###########################################################
### NASA Earthdata Authentication Function
### This function facilitates login to NASA's Earthdata system
### and retrieves cookies for use in authenticated requests.
###########################################################
authenticate_earthdata <- function(username, password) {
  
  # Print a status message to indicate the authentication process has started
  print("Authenticating with NASA Earthdata...")
  
  # Create a session to maintain cookies
  # `session()` initializes a new web session using the provided URL.
  # This session will handle all subsequent interactions.
  session <- session("https://urs.earthdata.nasa.gov/oauth/authorize?response_type=code&client_id=_JLuwMHxb2xX6NwYTb4dRA")
  
  #  Navigate to the Earthdata login homepage within the session
  # `session_jump_to()` makes a request to the specified URL and updates the session.
  login_page <- session_jump_to(session, "https://urs.earthdata.nasa.gov/home")
  
  # Extract the login form from the Earthdata login page
  # `html_form()` parses the HTML content of the page and extracts form elements.
  #  first form on the page is the login form.
  login_form <- html_form(login_page)[[1]]
  
  # Populate the login form with the user's credentials
  # `html_form_set()` fills in the username and password fields.
  # The `username` and `password` arguments are passed to this function.
  filled_form <- html_form_set(login_form, 
                               username = username,
                               password = password)
  
  # Submit the filled-in login form to the server
  # `session_submit()` sends the form to the server and updates the session with the response.
  session <- session_submit(session, filled_form)
  
  # Extract cookies from the response for use with `httr`
  # The cookies are needed to authenticate subsequent requests.
  # `session$response$cookies` contains a list of cookies from the server.
  cookies <- session$response$cookies
  
  # Convert the cookies into a single string format
  # This string is a concatenation of `name=value` pairs, separated by semicolons.
  cookie_string <- paste(paste(cookies$name, cookies$value, sep="="), collapse="; ")
  
  # Return the session and cookie string as a list
  # The session allows continued interaction with the authenticated server.
  # The cookie string can be used for making requests with other libraries, like `httr`.
  return(list(session = session, cookies = cookie_string))
}

###########################################################
### Alternative Download Function Using System Calls
### This function leverages `wget` via a system call to 
### download a file with authentication using credentials.
###########################################################

download_with_wget <- function(url, output_file, username, password) {
  
  # Create a .netrc file for wget authentication
  # The .netrc file stores credentials for automated access.
  # The `paste0()` function concatenates strings to create the file's content.
  netrc_content <- paste0("machine urs.earthdata.nasa.gov\n",
                          "login ", username, "\n",
                          "password ", password, "\n")
  
  # Generate a temporary file to store the .netrc content
  # `tempfile()` creates a unique temporary file path.
  netrc_file <- tempfile()
  
  # Write the .netrc content to the temporary file
  # `writeLines()` writes the authentication credentials into the file.
  writeLines(netrc_content, netrc_file)
  
  # Construct the `wget` command
  # `wget` is a system utility for downloading files from the web.
  # Here, it is configured with options for authentication and saving the file.
  wget_cmd <- paste0("wget ", 
                     "--load-cookies /dev/null ",            # Avoid using existing cookies
                     "--save-cookies /dev/null ",            # Avoid saving cookies
                     "--auth-no-challenge=on ",              # Enable pre-emptive authentication
                     "--user=", username, " ",               # Add the username for Basic Authentication
                     "--password=", password, " ",           # Add the password for Basic Authentication
                     "--content-disposition ",               # Use the server's suggested filename if available
                     "-O '", output_file, "' ",              # Specify the output file location
                     "'", url, "'")                          # Specify the download URL
  
  
  # Execute the `wget` command
  # `system()` runs the command in the system shell.
  # `intern = TRUE` captures the command output for debugging or logging.
  # `ignore.stderr = FALSE` ensures error messages are not suppressed.
  result <- system(wget_cmd, intern = TRUE, ignore.stderr = FALSE)
  
  # Clean up by removing the temporary .netrc file
  # `file.remove()` deletes the temporary file to ensure credentials are not left behind.
  file.remove(netrc_file)
  
  # Verify if the file was successfully downloaded
  # `file.exists()` checks if the file exists.
  # `file.info()` retrieves file metadata; `$size` checks if the file's size exceeds 1000 bytes/1kb.
  return(file.exists(output_file) && file.info(output_file)$size > 1000)
}

###########################################################
### Enhanced Download Function with Multiple Methods
### This function tries several approaches to download a file 
### while handling authentication and network issues.
###########################################################

download_nldas_file <- function(url, output_file, username, password, auth_session = NULL) {
  
  # Method 1: Use authenticated session if available
  if (!is.null(auth_session)) { # Check if a valid session is passed
    tryCatch({
      # Use the session to jump to the desired URL
      response <- session_jump_to(auth_session$session, url)
      
      # Check if the request was successful (HTTP status 200)
      if (response$response$status_code == 200) {
        # Save the content to the specified output file
        content <- response$response$content
        writeBin(content, output_file) # Write binary data to file
        
        # Validate file existence and size
        if (file.exists(output_file) && file.info(output_file)$size > 1000) {
          return(list(success = TRUE, method = "session", size = file.info(output_file)$size))
        }
      }
    }, error = function(e) { # Handle errors
      print(paste("Session method failed:", e$message))
    })
  }
  
  # Method 2: Try httr with different authentication approaches
  tryCatch({
    response <- httr::GET(
      url,
      httr::authenticate(username, password, type = "digest"), # Try with digest authentication
      httr::write_disk(output_file, overwrite = TRUE), 
      httr::timeout(300),
      httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"),
      httr::add_headers(
        "Accept" = "application/octet-stream, */*",
        "Accept-Language" = "en-US,en;q=0.9"
      )
    )
    # Check response status and file size
    if (httr::status_code(response) == 200 && file.exists(output_file) && file.info(output_file)$size > 1000) {
      return(list(success = TRUE, method = "httr_digest", size = file.info(output_file)$size))
    }
  }, error = function(e) {
    print(paste("httr digest failed:", e$message))
  })
  
  # Method 3: Try httr with basic authentication
  tryCatch({
    response <- httr::GET(
      url,
      httr::authenticate(username, password, type = "basic"),
      httr::write_disk(output_file, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    )
    # Check response status and file size
    if (httr::status_code(response) == 200 && file.exists(output_file) && file.info(output_file)$size > 1000) {
      return(list(success = TRUE, method = "httr_basic", size = file.info(output_file)$size))
    }
  }, error = function(e) {
    print(paste("httr basic failed:", e$message))
  })
  
  # Method 4: Try curl with enhanced options
  tryCatch({
    h <- curl::new_handle() # Create a new curl handle
    curl::handle_setopt(
      handle = h,
      httpauth = 1,          # Enable HTTP authentication
      userpwd = paste0(username, ':', password),   # Set username and password
      followlocation = TRUE,
      maxredirs = 10,
      ssl_verifypeer = TRUE,
      ssl_verifyhost = 2,
      useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      timeout = 300,
      connecttimeout = 60,
      cookiefile = "",  # Enable cookie engine
      cookiejar = "",   # Save cookies
      verbose = FALSE
    )
    # Fetch the file and save it
    resp <- curl::curl_fetch_disk(url = url, path = output_file, handle = h)
    
    # Validate file existence and size
    if (file.exists(output_file) && file.info(output_file)$size > 1000) {
      return(list(success = TRUE, method = "curl_enhanced", size = file.info(output_file)$size))
    }
  }, error = function(e) {
    print(paste("Enhanced curl failed:", e$message))
  })
  
  # Method 5: Use wget via system call
  if (Sys.which("wget") != "") {
    if (download_with_wget(url, output_file, username, password)) {
      return(list(success = TRUE, method = "wget", size = file.info(output_file)$size))
    }
  }
  
  # Method 6: Use curl via system call
  if (Sys.which("curl") != "") {
    tryCatch({
      curl_cmd <- paste0("curl -L -u ", username, ":", password, 
                         " -o '", output_file, "' '", url, "'")
      system(curl_cmd)
      
      if (file.exists(output_file) && file.info(output_file)$size > 1000) {
        return(list(success = TRUE, method = "system_curl", size = file.info(output_file)$size))
      }
    }, error = function(e) {
      print(paste("System curl failed:", e$message))
    })
  }
  
  # If all methods fail, return failure
  return(list(success = FALSE, method = "none", size = 0))
}

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

# sequence the datetime over your desired time period
# this creates a sequence of datetimes from the first day of the year (or the first time period) to the end of the year
out.ts = seq.POSIXt(as.POSIXct(startdatetime, tz = loc_tz),as.POSIXct(enddatetime,tz=loc_tz), by = 'hour')

##############################
### Step 3. RERUN MISSING NC FILES####
##############################
#In case any need rerunning, can create a specific list here. SOmetimes, it appears that the download doesn;t work. You can tell this if the nc file size is 2KB instead of 90KB 
#Do not uncomment these - but just run the code after the #
#out.ts<-c(as.POSIXct("2019-01-11 07:00:00", tz = loc_tz),as.POSIXct("2019-01-12 01:00:00", tz = loc_tz),as.POSIXct("2019-06-24 03:00:00", tz = loc_tz),as.POSIXct("2019-11-19 21:00:00", tz = loc_tz))
#out.ts<-c(as.POSIXct("2024-10-20 07:00:00", tz = loc_tz),as.POSIXct("2024-11-15 23:00:00", tz = loc_tz))
#out.ts <- c(as.POSIXct("2024-01-01 01:00:00", tz = loc_tz))
# Create output list of tables
output = list()

###########################################################
### Step 2. DOWNLOAD NC DATA#### 
### Run hourly loop
###########################################################

# Test credentials first
print("Testing NASA Earthdata credentials...")
auth_session <- NULL
tryCatch({
  auth_session <- authenticate_earthdata(username, password)
  print("✓ Authentication session created successfully")
}, error = function(e) {
  print(paste("⚠ Authentication session failed:", e$message))
  print("Will try alternative methods...")
})

# Start the clock!
ptm <- proc.time()

# Set timeout options
options(timeout = 300)

# Initialize counters
successful_downloads <- 0
failed_downloads <- 0

print(paste("Starting download of", length(out.ts), "files..."))

for (i in 1:length(out.ts)) {
  if (i %% 100 == 0) {  # Progress update every 100 files
    print(paste("Progress:", i, "of", length(out.ts), "files processed"))
    print(paste("Success rate:", round(successful_downloads/(successful_downloads + failed_downloads)*100, 1), "%"))
  }
  
  yearOut = year(out.ts[i])
  monthOut = format(out.ts[i], "%m")
  dayOut = format(out.ts[i], "%d")
  hourOut = format(out.ts[i], "%H%M")
  doyOut = format(out.ts[i],'%j')
  
  filename = format(out.ts[i], "%Y%m%d%H%M")
  output_file = paste(dumpdir_nc, filename, '_', loc_tz, '.nc', sep='')
  
  # Skip if file already exists and is larger than 1KB
  if(file.exists(output_file) && file.info(output_file)$size > 1000) {
    successful_downloads <- successful_downloads + 1
    next
  }
  
  #Get URL for FORA
  URL_FORA <- paste('https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.2.0%2F',
                    yearOut, '%2F',
                    str_pad(as.numeric(yday(as.Date(paste0(yearOut,"-", monthOut,'-' ,dayOut)))), 3, pad = "0"),
                    '%2FNLDAS_FORA0125_H.A',
                    yearOut, monthOut, dayOut, '.',
                    hourOut,  
                    '.020.nc',
                    '&SERVICE=L34RS_LDAS',
                    '&VERSION=1.02',
                    '&SHORTNAME=NLDAS_FORA0125_H',
                    '&BBOX=',
                    round(extent[2], 2),'%2C',
                    round(extent[1], 2),'%2C',
                    round(extent[4], 2),'%2C',
                    round(extent[3], 2),
                    '&LABEL=NLDAS_FORA0125_H.A',
                    yearOut, monthOut, dayOut, '.',
                    hourOut,
                    '.020.nc.SUB.nc4',
                    '&FORMAT=bmM0Lw',
                    '&DATASET_VERSION=2.0',
                    sep='')  
  
  # Attempt download with multiple methods
  result <- download_nldas_file(URL_FORA, output_file, username, password, auth_session)
  
  if (result$success) {
    successful_downloads <- successful_downloads + 1
    if (i <= 50 || i %% 100 == 0) {  # Show details for first 50 and every 100th
      print(paste("✓", basename(output_file), "-", result$method, "-", round(result$size/1024, 1), "KB"))
    }
  } else {
    failed_downloads <- failed_downloads + 1
    print(paste("✗ Failed:", basename(output_file)))
    
    # Clean up failed file
    if (file.exists(output_file)) {
      file.remove(output_file)
    }
  }
}

# Stop the clock
total_time <- proc.time() - ptm
print(paste("Total processing time:", round(total_time[3]/60, 1), "minutes"))

# Final summary
print("=== FINAL DOWNLOAD SUMMARY ===")
downloaded_files <- list.files(dumpdir_nc, pattern = "\\.nc$", full.names = TRUE)
if(length(downloaded_files) > 0) {
  file_sizes <- sapply(downloaded_files, function(x) file.info(x)$size)
  large_files <- sum(file_sizes > 1000)
  small_files <- sum(file_sizes <= 1000)
  
  print(paste("Total files attempted:", length(out.ts)))
  print(paste("Successful downloads (>1KB):", large_files))
  print(paste("Failed downloads (≤1KB):", small_files))
  print(paste("Success rate:", round(large_files/length(out.ts)*100, 1), "%"))
  
  if(small_files > 0) {
    small_file_list <- downloaded_files[file_sizes <= 1000]
    print("Files that need to be re-downloaded:")
    print(basename(small_file_list))
  }
  
  if(large_files > 0) {
    avg_size <- mean(file_sizes[file_sizes > 1000])
    print(paste("Average successful file size:", round(avg_size/1024, 1), "KB"))
  }
} else {
  print("No files were downloaded successfully")
}

###########################################################
### End Step. 2 DOWNLOAD NC DATA####
###########################################################

#If at this point, the year download didn't finish, then check the download folder. Delete any files that downloaded incompletely (they should be <90kb)####
#When you rerun this code from the beginning, it will start back up where you left off####


###########################################################
### Step 4. EXTRACT DATA FROM NC ####
###########################################################
#Requery the nc_files as it might have updated
#Get the list of files####
nc_files_updated<-list.files(dumpdir_nc)

#Reget the start and end time####
year_start_updated<-substr(nc_files_updated[1],1,4)
month_start_updated<-substr(nc_files_updated[1],5,6)
day_start_updated<-substr(nc_files_updated[1],7,8)
hour_start_updated<-substr(nc_files_updated[1],9,10)
startdatetime_updated<-paste0(year_start_updated,'-',month_start_updated,'-',day_start_updated,' ',hour_start_updated,':00:00')

year_end_updated<-substr(nc_files_updated[length(nc_files_updated)],1,4)
month_end_updated<-substr(nc_files_updated[length(nc_files_updated)],5,6)
day_end_updated<-substr(nc_files_updated[length(nc_files_updated)],7,8)
hour_end_updated<-substr(nc_files_updated[length(nc_files_updated)],9,10)
enddatetime_updated<-paste0(year_end_updated,'-',month_end_updated,'-',day_end_updated,' ',hour_end_updated,':00:00')

###########################################################
### Need to know how many cells your lake falls within
### Can download one instance of data from the earthdata site and see how many columns there are
### use 'nc_open(filename)' to see how many cells there are
###########################################################
br<-nc_open(paste0(dumpdir_nc,nc_files_updated[1]))
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
for (i in 1:length(nc_files_updated)) {
  #*Print out the nc file name####
  print(nc_files_updated[i])
  #*Loop through the variables####
  for (v in 1:length(vars_nc)) {
    nldasvar <- vars_nc[v]
    br = nc_open(paste0(dumpdir_nc, nc_files_updated[i]))
    output[[v]][i,1] =  as.POSIXct(paste0(substr(nc_files_updated[i], 1, 4),'-', substr(nc_files_updated[i], 5,6), '-', substr(nc_files_updated[i], 7,8), ' ', substr(nc_files_updated[i], 9,10), ':', substr(nc_files_updated[i], 11,12)), tz=loc_tz)
    output[[v]][i,-1] = ncvar_get(br, nldasvar)[cellNum]
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
                       format(as.POSIXct(startdatetime_updated), '%Y-%m-%d'),
                       '_', format(as.POSIXct(enddatetime_updated), '%Y-%m-%d'),
                       '_', vars_nc[i],'.csv'))
  #If it is the first file, then use that as the output, if not, then merge with previous####
  if(i==1){final.box<-out}else{
    final.box <- final.box %>% 
      left_join(out)  
  }

}

###########################################################
### Step 5. QA/QC CHECKS ####
###########################################################
####### Create a Single Dataframe and adjust time zone###########
head(final.box)
tail(final.box)
nrow(final.box) #should be 24*365=8760 (or 24*366=8784 in a leap year)
which(duplicated(final.box)) #check for duplicate time stamps - if this list is long, something is wrong!! There should be ZERO duplicated timestamps.
# final.box <- distinct(final.box)
sum(is.na(final.box$Tair)) #checks for NA values in the boxes
which(is.na(final.box$Tair)) # check for NA values in specific columns
final.box[which(is.na(final.box$Tair)),] #If there are any, then check here. Rerun this download above


# adjust to local timezone #
final.box <- final.box %>% 
  mutate(local_dateTime = with_tz(dateTime, tzone = local_tz_set))
head(final.box)

###########################################################
### Step 6. PREPARE FOR GLM FORMAT AND EXPORT ####
###########################################################

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
plot(drivers$time,drivers$WindSpeed,type = 'l')


#Find the initial and final day for the file name####
#This is now in local time zone so it might be a day earlier than January 1
year_start<-substr(drivers$time[1],1,4)
month_start<-substr(drivers$time[1],6,7)
day_start<-substr(drivers$time[1],9,10)

#This is now in local time zone so it might be a day earlier than January 1
year_final<-substr(drivers$time[length(drivers$time)],1,4)
month_final<-substr(drivers$time[length(drivers$time)],6,7)
day_final<-substr(drivers$time[length(drivers$time)],9,10)

#save combined nldas file####
#make sure the time is exported as a character to maintain time zone####
#The file name will include the first day to the last####
write_csv(drivers%>%mutate(time=as.character(time)),
                   paste0(dumpdir_input,lakeName, '_', 
                   paste(year_start,month_start,day_start,sep="_"),
                   '_to_', 
                   paste(year_final,month_final,day_final,sep="_"),
                   '_hourly.csv'))

