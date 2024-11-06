# Prepare shocks for non-US regions
# Zhan Wang (zhanwang@purdue.edu)

rm(list = ls())
library(HARr)
library(plyr)
library(data.table)

getGTAPShock = function(filename)
{
  EXP.input = read.table(paste0("Data/Wajiha 2022/", filename ,".EXP"),header=TRUE, sep="|", row.names=NULL)
  colnames(EXP.input)[1] = "content"
  
  EXP.shock = EXP.input[EXP.input$content %like% "Shock afeall", ]
  EXP.shock = EXP.shock[EXP.shock %like% "blue, Agriculture" ]
  
  EXP.shock.split = strsplit(EXP.shock,"=")
  
  # Only extract the first element in the nested list
  EXP.shock.reg = unlist(lapply(EXP.shock.split, `[[`, 1))
  EXP.shock.value = unlist(lapply(EXP.shock.split, `[[`, 2))
  
  EXP.shock.reg = gsub("Shock afeall( blue, Agriculture,","",EXP.shock.reg, fixed = TRUE)
  EXP.shock.reg = gsub(")","",EXP.shock.reg, fixed = TRUE)
  EXP.shock.reg = gsub(" ","",EXP.shock.reg)
  
  EXP.shock.value = gsub("uniform","",EXP.shock.value)
  EXP.shock.value = gsub(";","",EXP.shock.value)
  EXP.shock.value = gsub(" ","",EXP.shock.value)
  EXP.shock.value = as.numeric(EXP.shock.value)
  out.df = data.frame(GTAP = EXP.shock.reg, shock = EXP.shock.value)
  return(out.df)
}

# Main script

EXP.file = read.csv("in/GTAPEXPfile.csv", header = T)
SGU.reg = read.csv("in/SGUReg.csv", header = T)

# Prepare mapping (only need to do it once)
if(T)
{
  GTAPSETS = read_har("Data/Wajiha 2022/sets.HAR")
  GTAPDATA = read_har("Data/Wajiha 2022/basedata.HAR")
  
  df.GS = data.frame(GTAP = GTAPSETS$h1)
  GS.map = read.csv("in/GSRegMapping.csv", header = T)
  # Change CHN to "CHN_MNG"
  GS.map[GS.map$SIMPLE == "CHN",]$SIMPLE = "CHN_MNG" 
  # Change Mongolia (mng) to "CHN_MNG"
  GS.map[GS.map$GTAP == "mng",]$SIMPLE = "CHN_MNG" 
  
  df.GS = join(df.GS, GS.map)
  
  # Assign mnm = SSA
  df.GS[df.GS$GTAP == "mnm",]$SIMPLE = "SSA" 

  # Prepare weight
  # Use EVFA	Endowments - Firms' Purchases at Agents' Prices
  # endowment: ag_othlowsk
  # sector: pdr, wht, gro, v_f, osd, c_b, pfb, ocr
  EVFA = GTAPDATA$evfa["ag_othlowsk",,]
  EVFA = as.data.frame(t(EVFA))
  EVFA = subset(EVFA, select = c(pdr,wht,gro,v_f,osd,c_b,pfb,ocr))
  EVFA$AgLabor = rowSums(EVFA[,])
  EVFA$GTAP = row.names(EVFA) 
  
  EVFA = subset(EVFA, select = c(GTAP, AgLabor))
  # Drop unmatched GTAP regions
  df.GS = join(df.GS,EVFA)
  df.GS.out = subset(df.GS, is.na(SIMPLE) == F)
  write.csv(df.GS.out, "non-US out/GSMapAgLabor.csv", row.names = F)
}

# Loop over all GCM

df.GS.out = read.csv("non-US out/GSMapAgLabor.csv", header = T)

SGU.reg.list = SGU.reg$String

SGU.reg.all = SGU.reg

# loop over GCM
for (i in 1:nrow(EXP.file))
{

  df.GS.out.sub = df.GS.out
  SGU.reg.sub = SGU.reg
  
  SGU.reg.sub$shock = NA
  
  EXP.name.GTAP = EXP.file[i,]$GTAPfile
  EXP.name.GCM = EXP.file[i,]$GCM
  
  print(EXP.name.GTAP)
  
  shock.sub = getGTAPShock(EXP.name.GTAP)
  df.GS.out.sub = join(df.GS.out.sub,shock.sub)
  df.GS.out.sub = subset(df.GS.out.sub, is.na(shock) == F)
  
  # loop over region
  for (reg in SGU.reg.list)
  {
    df.GS.out.sub.reg = subset(df.GS.out.sub, SIMPLE == reg)
    df.GS.out.sub.reg$weight = df.GS.out.sub.reg$AgLabor / sum(df.GS.out.sub.reg$AgLabor)
    df.GS.out.sub.reg$weightShock = df.GS.out.sub.reg$weight*df.GS.out.sub.reg$shock
    SGU.reg.sub[SGU.reg.sub$String == reg,]$shock = sum(df.GS.out.sub.reg$weightShock)
  }
  
  SGU.reg.sub = subset(SGU.reg.sub, select = c(String,GRID,shock))
  
  SGU.reg.sub.tojoin = subset(SGU.reg.sub, select = c(String,shock))
  colnames(SGU.reg.sub.tojoin)[2] = EXP.name.GCM
  SGU.reg.all = join(SGU.reg.all,SGU.reg.sub.tojoin)
  
  if(anyNA(SGU.reg.sub$shock))
  {
    print(paste0(EXP.name.GCM, " contains NA in shock"))
  } else {
    write.csv(SGU.reg.sub,paste0("non-US out/nonUSShock_",EXP.name.GCM,".csv"), row.names = F)
  }
}

write.csv(SGU.reg.all,paste0("non-US out/nonUSShock_","all",".csv"), row.names = F)

