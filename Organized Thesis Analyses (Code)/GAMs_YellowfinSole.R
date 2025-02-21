####Generalized Additive Analyses: Yellowfin Sole 
#the following code creates generalized additive models for eggs and larvae of yellowfin sole. 
#these analyses form the basis of my MS thesis. 
#egg data uses an averaged sea surface temperature for the month of March in the Southeastern Bering Sea
#May index was chosen because it is two months before the peak of yellowfin sole CPUE, and thus May 
#conditions are likely more relevant to spawning behavior than temperatures in later months. 
#load egg and larval data: 

yfsub<-read.csv(file='./Ichthyo Data/Cleaned_Cut_YfEggs.csv',header=TRUE,check.names=TRUE)

yflarv.ctd<-read.csv(file='./Ichthyo Data/Cleaned_Cut_YfLarv_wCTD.csv',header=TRUE,check.names=TRUE)


###EGGS: Spawning Behavior 
##Load in local and regional temperature index for May (2 mos before peak in egg CPUE in July) 
reg.sst<-read.csv('./Environmental Data/May_SST_RegionalIndex_NCEP_BS.csv',header=TRUE,check.names=TRUE)
head(reg.sst) #range of regional average: lon: -180 to -151, lat: 50.5 to 67.5

for(i in 1:nrow(yfsub)){
  yfsub$reg.SST[i]<-reg.sst$SST[reg.sst$year==yfsub$year[i]]}


#base: 
eg.base<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy)+s(bottom_depth,k=5),
             data=yfsub,family=tw(link='log'),method='REML')

summary(eg.base)

windows(width=12,height=8)
plot(eg.base,shade=TRUE,shade.col='skyblue3',page=1,
     seWithMean=TRUE,scale=0)

windows(width=12,height=8)
par(mfrow=c(1,2))
plot(eg.base,select=1,scheme=2,too.far=0.025,xlab='Longitude',
     ylab='Latitude',main='Base Egg Model, YF')
map("world",fill=T,col="snow4",add=T)
plot(eg.base,select=2,xlab='Day of Year',shade=TRUE,shade.col='skyblue3')
abline(h=0,col='sienna3',lty=2,lwd=2)

##threshold phenology curve: 
temps<-sort(unique(reg.sst$SST))
bd<-4
temps.in<-temps[bd:(length(temps)-bd)]
aic.pheno<-NA*(temps.in)
thr.pheno<-as.list(1:(length(temps.in)))

for(i in 1:length(temps.in)){
  yfsub$th<-factor(yfsub$reg.SST<=temps.in[i])
  thr.pheno[[i]]<-gam((Cper10m2+1)~factor(year)+
                        s(lon,lat)+
                        s(bottom_depth,k=5)+
                        s(doy,by=th),
                      data=yfsub,family=tw(link='log'),method='REML')
  aic.pheno[i]<-AIC(thr.pheno[[i]])
}

best.index.phe<-order(aic.pheno)[1]
thr.pheno<-thr.pheno[[best.index.phe]]

windows()
plot(temps.in,aic.pheno,type='b',lwd=2,ylim=range(c(AIC(eg.base),aic.pheno)),
     main='Temperature Threshold Flexible Phenology',ylab='AIC Index',
     xlab='Temperature (degC)')
abline(h=AIC(eg.base),lty=2,lwd=2,col='sienna3')
abline(v=temps.in[best.index.phe],lty=2,lwd=2,col='steelblue3')

summary(thr.pheno)


windows(width=12,height=8)
plot(thr.pheno,shade=TRUE,shade.col='skyblue3',page=1,
     seWithMean=TRUE,scale=0)

col<-adjustcolor('tomato4',alpha.f=0.3)

windows()
par(oma=c(1,1,1,0.5),mar=c(3,3,3,1.5))
plot(thr.pheno,select=4,main='Yellowfin Sole Phenology, Eggs',seWithMean=TRUE,
     ylim=c(-3.5,3.5))
abline(h=0,col='mistyrose4',lty=2,lwd=1.3)
par(oma=c(1,1,1,0.5),mar=c(3,3,3,1.5),new=TRUE)
plot(thr.pheno,select=3,seWithMean=TRUE,shade=TRUE,shade.col=col,ylim=c(-3.5,3.5))
legend('topright',legend=c('Below','Above'),col=c(NA,col),lwd=c(2,2),cex=0.8)
mtext(c("Day of Year","Anomalies in log(CPUE+1)"),side=c(1,2),line=2.5)

windows()
par(mfrow=c(2,2))
gam.check(thr.pheno)

#temp threshold geo: 
temps<-sort(unique(reg.sst$SST))
bd<-4
temps.in<-temps[bd:(length(temps)-bd)]

aic.geo<-NA*(temps.in)
thr.geo<-as.list(1:(length(temps.in)))

for(i in 1:length(temps.in)){
  yfsub$th<-factor(yfsub$reg.SST<=temps.in[i])
  thr.geo[[i]]<-gam((Cper10m2+1)~factor(year)+s(doy)+s(bottom_depth,k=5)+
                      s(lon,lat,by=th),data=yfsub,
                    family=tw(link='log'),method='REML')
  aic.geo[i]<-AIC(thr.geo[[i]])
}

best.index.geo<-order(aic.geo)[1]
thr.geo<-thr.geo[[best.index.geo]]

windows()
plot(temps.in,aic.geo,type='b',lwd=2,ylim=range(c(AIC(eg.base),aic.geo)),
     main='Temperature Threshold Flex Geography',xlab="Temperature (degC)")
abline(h=AIC(eg.base),lty=2,lwd=2,col='sienna3')
abline(v=temps.in[best.index.geo],lty=2,lwd=2,col='steelblue3')

summary(thr.geo)

windows(width=12,height=8)
plot(thr.geo,page=1,scale=0,shade=TRUE,shade.col='skyblue3',
     seWithMean=TRUE)

windows(width=12,height=8)
par(mfrow=c(1,2))
plot(thr.geo,select=4,scheme=2,too.far=0.025,
     main=paste('Below',round(temps.in[best.index.geo],digits=3),sep=" "),
     shade=TRUE,seWithMean=TRUE,xlab='Longitude',ylab='Latitude')
map("world",fill=T,col="snow4",add=T)
plot(thr.geo,select=3,scheme=2,too.far=0.025,
     main=paste('Above',round(temps.in[best.index.geo],digits=3),sep=" "),
     shade=TRUE,seWithMean=TRUE,xlab='Longitude',ylab='Latitude')
map("world",fill=T,col="snow4",add=T)

windows()
par(mfrow=c(2,2))
gam.check(thr.geo)

#vc temp pheno: 
vc.pheno<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy)+s(bottom_depth,k=5)+
                s(doy,by=reg.SST),data=yfsub,family=tw(link='log'),
              method='REML')
summary(vc.pheno)

windows(width=12,height=8)
plot(vc.pheno,shade=TRUE,shade.col='skyblue3',
     page=1,scale=0,main='V-C Temp Flexible Phenology, yf Eggs',
     seWithMean=TRUE)

col<-adjustcolor('tomato4',alpha.f=0.3)

windows()
par(oma=c(1,1,1,0.5),mar=c(3,3,3,1.5))
plot(vc.pheno,select=2,main='Yellowfin Sole VC Phenology, Eggs',seWithMean=TRUE,
     ylim=c(-6.5,5))
abline(h=0,col='mistyrose4',lty=2,lwd=1.3)
par(oma=c(1,1,1,0.5),mar=c(3,3,3,1.5),new=TRUE)
plot(vc.pheno,select=4,seWithMean=TRUE,shade=TRUE,shade.col=col,ylim=c(-6.5,5))
legend('topleft',legend=c('Flexible Phenology Smooth','Deviation from Avg.Phenology'),
       col=c(NA,col),lwd=c(2,2),cex=0.8)
mtext(c("Day of Year","Anomalies in log(CPUE+1)"),side=c(1,2),line=2.5)

windows()
par(mfrow=c(2,2))
gam.check(vc.pheno)

#vc temp geo: 
vc.geo<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy)+s(bottom_depth,k=5)+
              s(lon,lat,by=reg.SST),data=yfsub,family=tw(link='log'),
            method='REML')
summary(vc.geo)

windows(width=12,height=8)
plot(vc.geo,shade=TRUE,shade.col='skyblue3',
     page=1,seWithMean=TRUE,main='V-C Flex Geo')

windows(width=15,height=8)
par(mfrow=c(1,2))
plot(vc.geo,select=1,scheme=2,too.far=0.025,shade=TRUE,shade.col='skyblue3',
     seWithMean=TRUE,xlab='Longitude',ylab='Latitude',
     main='V-C yf Egg Flex Geo, Avg. Variation')
map("world",fill=T,col="snow4",add=T)
plot(vc.geo,select=4,scheme=2,too.far=0.025,shade=TRUE,shade.col='skyblue3',
     xlab='Longitude',ylab='Latitude',seWithMean=TRUE,
     main='V-C Flex Geo, Deviation from Avg. Variation')
map("world",fill=T,col="snow4",add=T)

windows()
par(mfrow=c(2,2))
gam.check(vc.geo)

#all models for eggs in one place: 
eg.base<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy)+s(bottom_depth,k=5),
             data=yfsub,family=tw(link='log'),method='REML')

summary(eg.base)

temps<-sort(unique(reg.sst$SST))
bd<-4
temps.in<-temps[bd:(length(temps)-bd)]
aic.pheno<-NA*(temps.in)
thr.pheno<-as.list(1:(length(temps.in)))

for(i in 1:length(temps.in)){
  yfsub$th<-factor(reg.SST<=temps.in[i])
  thr.pheno[[i]]<-gam((Cper10m2+1)~factor(year)+
                        s(lon,lat)+
                        s(bottom_depth,k=5)+
                        s(doy,by=th),
                      data=yfsub,family=tw(link='log'),method='REML')
  aic.pheno[i]<-AIC(thr.pheno[[i]])
}

best.index.phe<-order(aic.pheno)[1]
thr.pheno<-thr.pheno[[best.index.phe]]
summary(thr.pheno)

temps<-sort(unique(reg.sst$SST))
bd<-4
temps.in<-temps[bd:(length(temps)-bd)]

aic.geo<-NA*(temps.in)
thr.geo<-as.list(1:(length(temps.in)))

for(i in 1:length(temps.in)){
  yfsub$th<-factor(reg.SST<=temps.in[i])
  thr.geo[[i]]<-gam((Cper10m2+1)~factor(year)+s(doy)+s(bottom_depth,k=5)+
                      s(lon,lat,by=th),data=yfsub,
                    family=tw(link='log'),method='REML')
  aic.geo[i]<-AIC(thr.geo[[i]])
}

best.index.geo<-order(aic.geo)[1]
thr.geo<-thr.geo[[best.index.geo]]
summary(thr.geo)

vc.pheno<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy)+s(bottom_depth,k=5)+
                s(doy,by=reg.SST),data=yfsub,family=tw(link='log'),
              method='REML')
summary(vc.pheno)

vc.geo<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy)+s(bottom_depth,k=5)+
              s(lon,lat,by=reg.SST),data=yfsub,family=tw(link='log'),
            method='REML')
summary(vc.geo)

##SAVE AND RELOAD LATER
saveRDS(eg.base,file="./GAM Models/yf_egg_base.rds")
saveRDS(thr.pheno,file="./GAM Models/yf_egg_thr_pheno.rds")
saveRDS(temps.in,file="./GAM Models/yf_egg_temps_in.rds")
saveRDS(best.index.phe,file="./GAM Models/yf_egg_best_index_phe.rds")
saveRDS(thr.geo,file="./GAM Models/yf_egg_thr_geo.rds")
saveRDS(best.index.geo,file="./GAM Models/yf_egg_best_index_geo.rds")
saveRDS(vc.pheno,file="./GAM Models/yf_egg_vc_pheno.rds")
saveRDS(vc.geo,file="./GAM Models/yf_egg_vc_geo.rds")

eg.base<-readRDS("./GAM Models/yf_egg_base.rds")
thr.pheno<-readRDS("./GAM Models/yf_egg_thr_pheno.rds")
temps.in<-readRDS("./GAM Models/yf_egg_temps_in.rds")
best.index.phe<-readRDS("./GAM Models/yf_egg_best_index_phe.rds")
thr.geo<-readRDS("./GAM Models/yf_egg_thr_geo.rds")
best.index.geo<-readRDS("./GAM Models/yf_egg_best_index_geo.rds")
vc.pheno<-readRDS("./GAM Models/yf_egg_vc_pheno.rds")
vc.geo<-readRDS("./GAM Models/yf_egg_vc_geo.rds")
                                                      
#checking based on AIC: 
aic.base<-AIC(eg.base)
aic.thrph<-AIC(thr.pheno)
aic.thrge<-AIC(thr.geo)
aic.vcph<-AIC(vc.pheno)
aic.vcgeo<-AIC(vc.geo)

aic.yfegg<-data.frame('model'=c('Base','Threshold Pheno','Threshold Geo',
                                'VC Pheno','VC Geo'),
                      'AIC_value'=c(aic.base,aic.thrph,aic.thrge,
                                    aic.vcph,aic.vcgeo))

windows()
plot(c(1:5),aic.yfegg$AIC_value,main='AIC Results for YF Egg Models',
     col=c( "#482173FF", "#38598CFF","#1E9B8AFF", "#51C56AFF","#FDE725FF"),
     pch=19,cex=2,ylab='AIC Value',xlab='')
grid(nx=5,ny=14,col="lightgray")
text(c(1:5),aic.yfegg$AIC_value,labels=round(aic.yfegg$AIC_value),pos=c(4,3,3,3,2))
legend("bottomright",legend=c('Base','Threshold Pheno','Threshold Geo',
                             'VC Pheno','VC Geo'),
       col=c( "#482173FF", "#38598CFF","#1E9B8AFF", "#51C56AFF","#FDE725FF"),
       lwd=3,lty=1)

###LARVAE: Water Mass Associations
lv.base<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
               s(bottom_depth,k=5),
             data=yflarv.ctd,family=tw(link='log'),method='REML')
summary(lv.base)

windows(width=12,height=8)
par(mfrow=c(2,2))
plot(lv.base,select=1,shade=TRUE,shade.col='skyblue3',
     seWithMean=TRUE,scale=0,main='Base Larval Presence GAM, W/O Residuals')
abline(h=0,col='sienna3',lty=2,lwd=2)
plot(lv.base,select=2,scheme=2,too.far=0.025,
     shade=TRUE,shade.col='skyblue3',
     seWithMean=TRUE,scale=0)
map("world",fill=T,col="snow4",add=T)
plot(lv.base,select=3,shade=TRUE,shade.col='skyblue3',
     seWithMean=TRUE,scale=0)
abline(h=0,col='sienna3',lty=2,lwd=2)

#add salinity
lv.add.sal<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
                  s(bottom_depth,k=5)+
                  s(salinity),data=yflarv.ctd,family=tw(link='log'),
                method='REML')
summary(lv.add.sal)

windows(width=12,height=8)
plot(lv.add.sal,page=1,scale=0,shade=TRUE,shade.col="skyblue4",
     seWithMean=TRUE)

windows(width=14,height=8)
par(mfrow=c(1,2))
plot(lv.add.sal,select=1,seWithMean=TRUE,shade=TRUE,shade.col="skyblue4",
     main='Seasonal Presence, Added Sal Model (No resids.)')
abline(h=0,col='sienna3',lty=2,lwd=2)
plot(lv.add.sal,select=2,scheme=2,seWithMean=TRUE,too.far=0.025,
     xlab='Longitude',ylab='Latitude',main='Biogeography')
map("world",fill=T,col="snow4",add=T)

windows(width=12,height=8)
plot(lv.add.sal,select=4,shade=TRUE,shade.col="skyblue4",
     seWithMean=TRUE,main='Effect of Salinity, W/O Residuals',
     xlab='Salinity (PSU)')
abline(h=0,col='sienna3',lty=2,lwd=2) #remove residuals because it can make the pattern hard to discern

#add temperature
lv.add.temp<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
                   s(bottom_depth,k=5)+
                   s(temperature),data=yflarv.ctd,family=tw(link='log'),
                 method='REML')
summary(lv.add.temp)

windows()
plot(lv.add.temp,page=1,shade=TRUE,shade.col="skyblue4",
     seWithMean=TRUE,main='Larval Log(Cper10m2+1) w Temp',scale=0)

windows(width=14,height=8)
par(mfrow=c(1,2))
plot(lv.add.temp,select=1,seWithMean=TRUE,shade=TRUE,shade.col="skyblue4",
     main='Seasonal Presence, Added Temp Model (No resids.)')
abline(h=0,col='sienna3',lty=2,lwd=2)
plot(lv.add.temp,select=2,scheme=2,seWithMean=TRUE,too.far=0.025,
     xlab='Longitude',ylab='Latitude',main='Biogeography')
map("world",fill=T,col="snow4",add=T)

windows(width=12,height=8)
plot(lv.add.temp,select=4,shade=TRUE,shade.col="skyblue4",
     seWithMean=TRUE,main='Larval Log(CPer10m2+1), Effect of Temperature',
     xlab='Temperature (degC)')
abline(h=0,col='sienna3',lty=2,lwd=2)

#additive both temp and sal
lv.temp.sal<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
                   s(bottom_depth,k=5)+
                   s(temperature)+s(salinity),data=yflarv.ctd,
                 family=tw(link='log'),method='REML')
summary(lv.temp.sal)

windows()
plot(lv.temp.sal,page=1,shade=TRUE,shade.col='skyblue4',
     main='Larval Log Presence Temp and Sal',
     seWithMean=TRUE,scale=0)

windows()
par(mfrow=c(2,2))
plot(lv.temp.sal,select=1,seWithMean=TRUE,shade=TRUE,
     shade.col='skyblue4',main='Temp and Sal Model (No resids.)')
abline(h=0,col='sienna3',lty=2,lwd=2)
plot(lv.temp.sal,select=2,scheme=2,seWithMean=TRUE,too.far=0.025,
     xlab='Longitude',ylab='Latitude',main='Biogeography')
map("world",fill=T,col="snow4",add=T)
plot(lv.temp.sal,select=4,shade=TRUE,shade.col='skyblue4',
     seWithMean=TRUE,main='Effect of Temp',xlab='Temperature (degC)')
abline(h=0,col='sienna3',lty=2,lwd=2)
plot(lv.temp.sal,select=5,shade=TRUE,shade.col='skyblue4',
     seWithMean=TRUE,main='Effect of Salinity',xlab='Salinity (psu)')
abline(h=0,col='sienna3',lty=2,lwd=2)

##2D Smooth with temp and sal: 
lv.2d<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy,k=7)+s(bottom_depth)+
             s(salinity,temperature),data=yflarv.ctd,family=tw(link='log'),
           method='REML')
summary(lv.2d)

windows()
plot(lv.2d,page=1,shade=TRUE,shade.col='skyblue4',
     main='Larval Log Presence, 2D Temp and Sal',
     seWithMean=TRUE,scale=0)

windows()
par(mfrow=c(1,2))
plot(lv.2d,select=2,seWithMean=TRUE,shade=TRUE,shade.col='skyblue4',
     main='Seasonal Presence, 2D Temp+Sal Model (No resids.)')
abline(h=0,col='sienna3',lty=2,lwd=2)
plot(lv.2d,select=1,scheme=2,seWithMean=TRUE,too.far=0.025,
     xlab='Longitude',ylab='Latitude',main='Biogeography')
map("world",fill=T,col="snow4",add=T)

windows()
plot(lv.2d,select=4,scheme=2,main='Larval Log Presence, 2D Temp and Sal Effect',
     too.far=0.025,
     xlab='Salinity (psu)',ylab='Temperature (degC)')

#all larval models in one place: 
lv.base<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
               s(bottom_depth,k=5),
             data=yflarv.ctd,family=tw(link='log'),method='REML')
summary(lv.base)

lv.add.sal<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
                  s(bottom_depth,k=5)+
                  s(salinity),data=yflarv.ctd,family=tw(link='log'),
                method='REML')
summary(lv.add.sal)

lv.add.temp<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
                   s(bottom_depth,k=5)+
                   s(temperature),data=yflarv.ctd,family=tw(link='log'),
                 method='REML')
summary(lv.add.temp)

lv.temp.sal<-gam((Cper10m2+1)~factor(year)+s(doy,k=7)+s(lon,lat)+
                   s(bottom_depth,k=5)+
                   s(temperature)+s(salinity),data=yflarv.ctd,
                 family=tw(link='log'),method='REML')
summary(lv.temp.sal)

lv.2d<-gam((Cper10m2+1)~factor(year)+s(lon,lat)+s(doy,k=7)+s(bottom_depth)+
             s(salinity,temperature),data=yflarv.ctd,family=tw(link='log'),
           method='REML')
summary(lv.2d)

#Saving and loading models: 
saveRDS(lv.base,file="./GAM Models/yf_larvae_base.rds")
saveRDS(lv.add.sal,file="./GAM Models/yf_larvae_addsal.rds")
saveRDS(lv.add.temp,file="./GAM Models/yf_larvae_addtemp.rds")
saveRDS(lv.temp.sal,file="./GAM Models/yf_larvae_addtempsal.rds")
saveRDS(lv.2d,file="./GAM Models/yf_larvae_2d.rds")

lv.base<-readRDS("./GAM Models/yf_larvae_base.rds")
lv.add.sal<-readRDS("./GAM Models/yf_larvae_addsal.rds")
lv.add.temp<-readRDS("./GAM Models/yf_larvae_addtemp.rds")
lv.temp.sal<-readRDS("./GAM Models/yf_larvae_addtempsal.rds")
lv.2d<-readRDS("./GAM Models/yf_larvae_2d.rds")

#checking based on AIC: 
aic.base.lv<-AIC(lv.base)
aic.sal<-AIC(lv.add.sal)
aic.temp<-AIC(lv.add.temp)
aic.tempsal<-AIC(lv.temp.sal)
aic.2d<-AIC(lv.2d)

aic.yflarv<-data.frame('model'=c('Base BioGeo','Add Sal','Add Temp',
                                 'Add Sal, Temp','Sal-Temp 2D'),
                       'AIC_value'=c(aic.base.lv,aic.sal,aic.temp,
                                     aic.tempsal,aic.2d))

windows()
plot(c(1:5),aic.yflarv$AIC_value,main='AIC Results for yf Larvae Models',
     col=c( "#482173FF", "#38598CFF","#1E9B8AFF", "#51C56AFF","#FDE725FF"),
     pch=19,cex=2,ylab='AIC Value',xlab='')
grid(nx=5,ny=14,col="lightgray")
text(c(1:5),aic.yflarv$AIC_value,labels=round(aic.yflarv$AIC_value),pos=c(4,3,3,3,2))
legend("bottomleft",legend=c('Base BioGeo','Add Sal','Add Temp',
                             'Add Sal, Temp','Sal-Temp 2D'),
       col=c( "#482173FF", "#38598CFF","#1E9B8AFF", "#51C56AFF","#FDE725FF"),
       lwd=3,lty=1)

#finding salinity/temperature hotspots 
viridis<-colorRampPalette(c("#440154FF", "#482173FF", "#433E85FF", "#38598CFF", "#2D708EFF", "#25858EFF", "#1E9B8AFF",
                            "#2BB07FFF", "#51C56AFF", "#85D54AFF", "#C2DF23FF", "#FDE725FF")) #viridis palette

stsweet<-yflarv.ctd[yflarv.ctd$temperature>9&yflarv.ctd$salinity<32.6,]#dim 249, 27
tt<-table(stsweet$year)

stsweet<-subset(stsweet,year%in%names(tt[tt>5]))
table(stsweet$year) #only includes 2002,2003,2005,2009,2012,2014,2015,2016 
stsweet<-subset(stsweet,Cper10m2>0)

stsweet$color<-NA
stsweet$month_nm<-NA
stsweet<-stsweet %>% mutate(color=case_when(
  stsweet$month==7~'#433E85FF',
  stsweet$month==8~'#1E9B8AFF',
  stsweet$month==9~'#51C56AFF',
  stsweet$month==10~'#C2DF23FF'))
stsweet<-stsweet %>%mutate(month_nm=case_when(
  stsweet$month==7~'July',
  stsweet$month==8~'August',
  stsweet$month==9~'September',
  stsweet$month==10~'October'
))

test<-stsweet[stsweet$year==2002,]

windows()
plot(test$lon,test$lat,xlim=range(yflarv.ctd$lon),ylim=range(yflarv.ctd$lat),
     col=test$color,pch=19,cex=2,
     xlab='Longitude',ylab='Latitude',main='Test, Salinity/Temperature Hot Spots')
symbols(test$lon,test$lat,circles=test$Cper10m2,inches=0.15,add=T)
map("worldHires",fill=T,col="snow4",add=T) 
#NOTE: when bathymetry is figured out, can add station points via points()

years<-sort(unique(stsweet$year))
tmp1<-1:ceiling(length(years)/4)
lg.text<-unique(stsweet$month_nm)
lg.values<-c('#433E85FF','#1E9B8AFF',
             '#51C56AFF','#C2DF23FF')

for(j in 1:length(tmp1)){
  windows(width=24,height=14)
  par(mfcol=c(2,2),omi=c(0.25,0.3,0.55,0.25),mai=c(0.2,0.4,0.4,0.1))
  for(i in (4*tmp1[j]-3):min(length(years),(4*tmp1[j]))){
    plot(stsweet$lon[stsweet$year==years[i]],stsweet$lat[stsweet$year==years[i]],
         col=stsweet$color[stsweet$year==years[i]],pch=19,cex=2,
         main=as.character(years[i]),
         ylim=range(stsweet$lat),xlim=range(stsweet$lon),
         ylab=expression(paste("Latitude ("^0,'N)')),
         xlab=expression(paste("Longitude ("^0,'E)')))
    symbols(yflarv.ctd$lon[yflarv.ctd$Cper10m2>0&yflarv.ctd$year==years[i]],
            yflarv.ctd$lat[yflarv.ctd$Cper10m2>0&yflarv.ctd$year==years[i]],
            circles=yflarv.ctd$Cper10m2[yflarv.ctd$Cper10m2>0&yflarv.ctd$year==years[i]],inches=0.15,add=T)
    map("worldHires",fill=T,col="snow4",add=T)
  }
  legend("topright",legend=c('July','August','September','October'),
          col=c('#433E85FF','#1E9B8AFF','#51C56AFF','#C2DF23FF'),lwd=3,lty=1,
         bg='lightgrey')
  mtext("YF Sole +Cper10m2 Catch Plotted Against T-S 'Sweet Spots'",outer=TRUE,cex=1,line=1)
}
























