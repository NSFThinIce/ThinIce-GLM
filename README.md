## Thin Ice GLM modeling

This githhub repository is the best place to find Thin Ice details about running GLM on our modeled lakes.
Those lakes include: <br>
Mohonk (contact: Dave Richardson) <br>
Green Lake 4 (Contact: Bella Oleksy) <br>
The Loch (Contact: Bella Oleksy) <br>
Bethel (Contact: Rebecca North) <br>
Marceline (COntact: Rebecca North) <br>
Shelburne (Contact: Mindy Morales-Williams) <br>
ELA239 (Contact: Scott Higgins) <br>

## Flow of modeling a lake with GLM

1. Create folder in base directory (e.g., "06_Mohonk")<br>
2. Copy over glm3.nml file/template<br>
3. Create 3 folders: <br>
  a. data: various data goes here including data prior to being ready for GLM, NLDAS meteorological data goes here<br>
  b. input: this is the data input to GLM including inflows, and met data <br>
  c. output: the model will generate output to be exported here<br>
4. Download NLDAS data: this comes from  <br>
  a. This happens in 02_Scripts/04_ThinIce-GLM-NLDS-download.R script, details there<br>
  b. Alternatively local met stations can be used if you have the following variables on hourly timescales; <br> 
      ShortWave	LongWave	AirTemp	RelHum	WindSpeed	Rain	Snow <br>
5. Update the nml file for your lake (morphometry, lat/long, data range, etc...) <br>
6. Run GLM for physics! <br> 
  a. Check outputs <br>
7. Calibrate and validate model <br>
  a. still working on this one <br>
 
## Fun links that might be informative or helpful:
Best place to find the description of the GLM nml configuration file and everything that it does:
https://aquatic.science.uwa.edu.au/research/models/GLM/configuration.html
<br>

The code is being constructed with help from various people and repositories including here:
https://github.com/AquaticEcoDynamics/glm-aed/blob/main/glm-examples/example_lakes.Rmd
https://github.com/robertladwig/GLM_workshop
<br>

The most recent releases available are here: 
GLM3.3.1: https://github.com/AquaticEcoDynamics/releases/tree/main/GLM-AED<br>

An ensemble model from Tadhg Moore and Chris McBride in NZ:
https://limnotrack.github.io/AEME/articles/aeme-inputs.html<br>

North American Land Data Assimilation System (NLDAS) has hourly meteorological data here:
https://disc.gsfc.nasa.gov/datasets/NLDAS_FORA0125_H_2.0/summary?keywords=NLDAS<br>

## Contacts

Dave Richardson (richardsond@newpaltz.edu)