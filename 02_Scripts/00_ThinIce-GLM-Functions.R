#Created 03Apr2025 DCR####
#Has functions needed to calibrate, run, and analyze GLM####

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
} #end of run_sim function