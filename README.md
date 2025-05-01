## Thin Ice GLM modeling

This githhub repository is the best place to find Thin Ice details about running GLM on our modeled lakes.
Those lakes include: <br>
Mohonk (contact: Dave Richardson) <br>
Green Lake 4 (Contact: Bella Oleksy) <br>
The Loch (Contact: Bella Oleksy) <br>
Bethel (Contact: Rebecca North) <br>
Marceline (Contact: Rebecca North) <br>
Shelburne (Contact: Mindy Morales-Williams) <br>
ELA239 (Contact: Scott Higgins) <br>

## Flow of modeling a lake with GLM

1. Create folder in base directory (e.g., "06_Mohonk")<br>
2. Copy over glm3.nml file/template<br>
3. Create 3 folders: <br>
  a. data: various data goes here including data prior to being ready for GLM, NLDAS meteorological data goes here<br>
  b. input: this is the data input to GLM including inflows, and met data <br>
  c. output: the model will generate output to be exported here<br>
4. Download NLDAS data: this comes from GES DISC NLDAS (see links below)<br>
  a. This happens in 02_Scripts/04_ThinIce-GLM-NLDS-download.R script, details there<br>
      This is going take awhile to get each year collated<br>
  b. Alternatively local met stations can be used if you have the following variables on hourly timescales; <br> 
      ShortWave	LongWave	AirTemp	RelHum	WindSpeed	Rain	Snow <br>
5. Update the nml file for your lake (morphometry, lat/long, data range, etc...) <br>
6. Run GLM for physics! <br> 
  a. Check outputs <br>
7. Calibrate and validate model <br>
  a. still working on this one <br>

## Tips for working with gitHub with big numbers of files
1. Use the terminal tab in the Console window - there you can access your system shell and enter git commands directly
  a. In the 02_Scripts/HelpWithGit.txt is a small compilation of some troubleshooting
  b. E.g., if you want to add a bunch of files to commit, it can be tedious to check 1000s of boxes in the Git tab in the Workspace Browser window<br>
      Instead, in the terminal tab, type 'git add -A' (without the quotes), and press enter
      All files will be added to the commit window. You can proceed by pressing Commit, entering a Commit message, committing, and pushing.<br>

 
## Fun links that might be informative or helpful:
Some papers for reading: 
GLM 3.0 paper: https://gmd.copernicus.org/articles/12/473/2019/<br>
Lake Sunapee application using GLM: https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2020WR027296 <br>

Project EDDIE module for modeling lakes with GLM. Great place to get a start: https://serc.carleton.edu/eddie/teaching_materials/modules/lake_modeling.html<br>

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
