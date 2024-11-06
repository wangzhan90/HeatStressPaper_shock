# Heat Stress Paper: Code for Creating Shocks
By: Zhan Wang, Department of Agricultural Economics, Purdue University. 

Contact: zhanwang@purdue.edu
# Introduction
This repository stores the R code to create GCM-specific shocks for simulations for the working paper of agricultural impacts of human heat stress in the US. The archive of model, data and simulations can be downloaded from https://github.com/wangzhan90/HeatStressPaper_model.

# Description
## \cmf
This folder contains the basic command files for the “cmf_HeatStress_baseline” and “cmf_HeatStress_2050” scenarios, which are used in creating GCM-specific command files.
## \Data
This folder contains three datasets:
\labor_HeatStressUS: the folder contains grid cell level labor productivity loss due to heat stress from “Saeed, W., I. Haqiqi, Q. Kong, M. Huber, J. R. Buzan, S. Chonabayashi, K. Motohashi, and T. W. Hertel. "The poverty impacts of labor heat stress in West Africa under a warming climate." Earth's Future 10, no. 11 (2022). https://doi.org/10.1029/2022EF002777 ”.
The code for processing the grid level data is available from https://github.com/ihaqiqi/agLaborHeatUS. 
Wajiha 2022: this folder contains the GTAP region level labor productivity loss for non-US regions, which is also from Saeed et al. (2022).
userData.HAR: this file contains other shocks used in the alternative scenario “cmf_HeatStress_2050”. Data sources are described in the supplementary material “S5. Additional scenario: Heat stress and other drivers projected by 2050” of this paper.
## \Figure
This folder stores the figure of heat stress shocks at grid cell level.
## \in
This folder contains the mapping files between GTAP and SIMPLE-G regions (GSRegMapping.csv), GCM names for simulations and from the GTAP experiment files (GTAPEXPfile.csv), SIMPLE-G regions and corresponding grid cell indexes (SGUReg.csv). The source of GTAPEXPfile.csv is also provided in the aggregation file (SIMPLE_agg.txt) for additional information.
## \non-US out
This folder stores the temporary results of aggregated labor productivity loss for all non-US regions.
## \out
This folder will store shocks for simulations. Currently, it contains the shock files generated for the “cmf_HeatStress_baseline” scenario (also available in the model, data and simulations archive).
## \shp
The folder contains the shapefile of farming resource regions in the US. This shapefile is created by mapping county level shapefile to farming resource regions with the "county-to-ERS Resource Region aggregation in Excel" file from USDA-ERS (https://www.ers.usda.gov/data-products/arms-farm-financial-and-crop-production-practices/documentation.aspx, accessed on 2024/4/28).
## prepareNonUSHeatShock.R
The code for processing heat stress shocks for non-US regions
## prepareUSHeatShock.R
The code for processing heat stress shocks at the grid cell level in the US.

# How to use
## Step 1: Download the folder of data and codes
Please download and save the “createShock” folder.

## Step 2: Process shocks for non-US regions
Please run “prepareNonUSHeatShock.R”, which will aggregate the labor production loss projection due to heat stress from GTAP regions to SIMPLE-G regions.

## Step 3: Process shocks at grid cell level
Please run “prepareUSHeatShock.R”, which will read in grid level shocks in csv format and create the shock files to be used in simulation. It will also combine grid cell level shocks in the US with region level shocks from non-US regions (generated in step 2). 
