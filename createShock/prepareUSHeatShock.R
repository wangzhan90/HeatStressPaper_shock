# create labor productivity shocks from 14 GCM and 4 climate scenarios
# Zhan Wang (zhanwang@purdue.edu)

rm(list = ls())
library(raster)
library(ggplot2)
library(rgdal)
library(ggpubr)
library(plyr)
library(HARr)

# Functions ----
genFileName = function(temp, gcm){
  fileName = paste0("Labor_",temp, "C_", gcm, "_CMIP6")
  return(fileName)
}

# Add elements to list
addElement = function(list, variable, name, longname)
{
  attr(variable, 'description') = longname
  list = c(list, variable = list(variable))
  names(list)[length(list)] = name
  return(list)
}

# Main script ----
temp.list = c(3)
gcm.list = c("ACCESS_CM2","BCC-CSM2-MR","CMCC-CM2-SR5","EC-Earth3_r1i1p1f1",
             "EC-Earth3_r3i1p1f1","EC-Earth3_r4i1p1f1","HadGEM3-GC31-LL",
             "HadGEM3-GC31-MM","MIROC6","MPI-ESM1-2-HR_r1i1p1f1",
             "MPI-ESM1-2-HR_r2i1p1f1","MPI-ESM1-2-LR","MRI-ESM2-0")

# Get the list of grid
userData = read_har('Data/userData.har')
ALAB = as.data.frame(userData$alab)
ALAB$GID = toupper(rownames(ALAB))

set.gid = ALAB$GID
set.ltyp = c("Irrigated","Rainfed")

# Loop 1: Process Har file and prepare the range for visualization
minShockList = c()
maxShockList = c()
dofile.list = c()


# Also get non-US region shocks
nonUS = read.csv("non-US out/nonUSShock_all.csv", header = T, check.names=FALSE)
nonUS$x = 0
nonUS$y = 0
nonUS = subset(nonUS, is.na(GRID) == F)
colnames(nonUS)[3] = "GID"


for (temp in temp.list){
  for (gcm in gcm.list){
    inputFile = paste0(genFileName(temp, gcm),".csv")
    print(inputFile)
    
    df.heatShock = read.csv(paste0("Data/labor_HeatStressUS/v_2022_02_28/",inputFile), header = T)
    colnames(df.heatShock)[4] = "shock"
    
    minShockList = c(minShockList, min(df.heatShock$shock))
    maxShockList = c(maxShockList, max(df.heatShock$shock))
    
    # Add non-US regions
    nonUS.sub = nonUS
    nonUS.sub$shock = nonUS.sub[[gcm]]
    nonUS.sub = subset(nonUS.sub, select = c(x, y, GID, shock))
    
    df.heatShock.allreg = rbind(df.heatShock, nonUS.sub)
    
    shock.sub =  df.heatShock.allreg$shock
    shock.sub = round(shock.sub, 6)
    # Prepare shock har file
    if(F)
    {
      list.ALAB = list()
      header.ALAB = array(c(shock.sub, shock.sub),
                          dim = c(length(set.gid), 2),
                          dimnames = list(GID = set.gid, LTYPE = set.ltyp))
      
      list.ALAB = addElement(list.ALAB, header.ALAB , "ALAB", 
                             paste0("labor productivity loss by ",temp,"C warming, ", gcm))
      write_har(list.ALAB, paste0("out/",genFileName(temp, gcm),".har"), maxSize = 1e6)
      
    }
    
    # Prepare data as shk file
    shk = c(paste0(length(set.gid), " ", length(set.ltyp), 
                   ' Real SpreadSheet Header "ALAB" LongName "',paste0("labor productivity loss by ",temp,"C warming, ", gcm),'";'))
    
    df.shk = data.frame(Irrigated = shock.sub, Rainfed = shock.sub)
    df.shk$shock = paste0(df.shk$Irrigated,",",df.shk$Rainfed)
    
    shk = c(shk, df.shk$shock)
    writeLines(shk, con=paste0("out/",genFileName(temp, gcm),".shk"))
    
    # Prepare cmf file 
    # Use this cmf file for "cmf_HeatStress_baseline" shock (heat stress only)
    cmf = readLines("cmf/SIMPLEG_IGS_subtotal_Heat.cmf")
    # Use this cmf file for "cmf_HeatStress_2050" shocks (heat stress and other shocks projected to 2050)
    #cmf = readLines("cmf/SIMPLEG_IGS_subtotal_HeatAll.cmf")
    lineNum = grep(pattern = "Shock p_AFLABORgl = ", cmf)
    newLine = gsub(pattern = "userData", replace = paste0(genFileName(temp, gcm)), x = cmf[lineNum])
    cmf[lineNum] = newLine
    writeLines(cmf, con=paste0("out/SIMPLEG_IGS_",genFileName(temp, gcm),".cmf"))
    
    # Prepare do file
    dofile.list = c(dofile.list,paste0("call SIMPLEG_IGS.exe -cmf ","SIMPLEG_IGS_",genFileName(temp, gcm),".cmf")) 
  }
}

minShock = min(minShockList)
maxShock = max(maxShockList) 

dofile.list = c(dofile.list, "pause")
writeLines(dofile.list, con=paste0("out/run.bat"))

# Loop 2: visualize
myPalette <- colorRampPalette(c("red", "orange","yellow", "green", "blue"))
FRR.polygon = readOGR(dsn="shp/FarmResourceRegions_continental_refine.shp")

axis.0 = ggplot() + 
  geom_text(aes(x=0, y=0, label = " "), size = 6, hjust = 0) +
  theme_void()


xindex = 1
yindex = 1

for (gcm in gcm.list){
  for (temp in temp.list){
    inputFile = paste0(genFileName(temp, gcm),".csv")
    print(inputFile)
    print(yindex)
    print(xindex)
    df.heatShock = read.csv(paste0("Data/labor_HeatStressUS/v_2022_02_28/",inputFile), header = T)
    colnames(df.heatShock)[4] = "shock"
    df.heatShock$x = round(df.heatShock$x,digits = 4)
    df.heatShock$y = round(df.heatShock$y,digits = 4)
    
    assign(paste0("f",yindex,".",xindex), ggplot() + 
      geom_tile(data=df.heatShock, aes(x=x, y=y, fill=shock)) + 
      geom_polygon(data=FRR.polygon, aes(x=long, y=lat, group=group), 
                     fill=NA, color="black", linewidth=0.2) +
      scale_fill_gradientn(colours = myPalette(100),
                           limits=c(minShock,maxShock))+
      ggtitle(gcm)+
      theme(axis.line=element_blank(),
            axis.text.x=element_blank(),
            axis.text.y=element_blank(),
            axis.ticks=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank(),
            panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(),
            panel.background = element_blank(),
            axis.title = element_text(size = 25),
            plot.title = element_text(size = 15))
    )
    xindex = xindex + 1
  }
  xindex = 1
  yindex = yindex + 1
}


fig.list = list(f1.1, f2.1, f3.1, f4.1, f5.1,
                f6.1, f7.1, f8.1, f9.1, f10.1,
                axis.0, f11.1, f12.1, f13.1,axis.0)


ggarrange(plotlist = fig.list, ncol=5, nrow=3, common.legend = T, legend="right",
          widths = c(rep(2.5,5)), 
          heights = c(rep(1.5,3)))

ggsave(paste0("Figure/","HeatStressShock_3C",".png"),
       width=sum(c(rep(2.5,5))), height=sum(c(rep(1.5,3))))

