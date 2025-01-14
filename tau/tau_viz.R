################
#Jenny Bower
#Elemental analysis
#11-9-2020
#This script was made during a global pandemic
################
library('readxl')
library('tidyverse')
library('ggplot2')
library('reshape')
library('gridExtra')
library('dplyr')
library('car')
library('dunn.test')

#to do: incorporate bulk density, make applicable to soil and rock alike
setwd("~/Documents/uvm/phd/research/data/lab/Exchangeable/VT/Soil_Analyses/tau/exports/")

#fix all this so it looks better
nocsvs <- print(list.files('values_tau/hb/'))
taulist <- list()
for(a in seq_along(c(1:length(nocsvs)))){
  csvdata <- read.csv(paste0('values_tau/hb/',nocsvs[a]), header = TRUE, sep = ",")
  taulist[[a]] <- csvdata
}
taulist

#note that your deep C values are tau'ed against their average!!

taudata <- do.call(rbind, taulist)
taudatab <- cbind(taudata, "LV" = "")
taudatas <- cbind(taudatab, "Hor" = "")

i <- sapply(taudatas, is.factor)
taudatas[i] <- lapply(taudatas[i], as.character)

listy <- list()

for(a in c(1:nrow(taudatas))){
  if(as.numeric(substr(taudatas$Name[a],4,4)<4)){
    taudatas[a,grep("LV",colnames(taudatas))] <- "L"
  }
  else{
    taudatas[a,grep("LV",colnames(taudatas))] <- "V"
  }
  listy[a] <- str_extract_all(substr(taudatas$Name[a],nchar(taudatas$Pedon[a])+2,nchar(taudatas$Name[a])),"[:alpha:]")
  taudatas[a,grep("Hor",colnames(taudatas))] <- as.character(paste(listy[[a]],collapse=""))
}

prettylabs <- c("Lateral E", "Lateral Bhs", "Vertical E", "Vertical Bhs", "Deep C")
sdata <- cbind(taudatas, Cat = str_c(taudatas$LV, taudatas$Hor))

write.csv(sdata, "datalist.csv")
sdata <- read.csv("values_tau/processed/datalist.csv", header = TRUE, stringsAsFactors = FALSE)

#added extra pedons and took out PFM Bhs horizon
dpc <- read_csv("../extra/hb_soil_alldeep.csv")
cdata <- cbind(dpc, LV = "", Hor = "", Cat = "DC")

names(cdata) <- names(sdata)
soildata <- rbind(sdata, cdata)
soilsub <- subset(soildata, soildata$Cat == "LE" | soildata$Cat == "LBhs" | soildata$Cat == "VE" | soildata$Cat == "VBhs" | soildata$Cat == "DC")
soilsub$Cat <- factor(soilsub$Cat, levels=c("LE", "LBhs", "VE", "VBhs", "DC"))
soilsub <- soilsub[!(soilsub$Pedon == "52_3_X3.1" & soilsub$Cat == "LE"),]

p1 <- ggplot(soilsub, aes(x = Cat, y = tau_Al, fill = Cat)) + geom_hline(yintercept=0, linetype="dashed", color = "gray", size = 0.5) + geom_boxplot() + geom_point() + theme_classic() + labs(title = "", x = "Horizon", y = expression(τ[Al])) + scale_y_continuous(breaks = c(-0.5,0,0.5)) + theme(legend.position = "none") + theme(plot.title = element_text(size=20,face="bold")) +  theme(axis.text.y = element_text(size=12)) + scale_fill_manual(values = c("#cccccc","#90593f","#cccccc","#90593f","#fcff54")) + scale_x_discrete(labels = prettylabs) + theme(axis.title.x = element_blank(), axis.title.y = element_text(size=15, face="plain"))
p2 <- ggplot(soilsub, aes(x = Cat, y = tau_Ca, fill = Cat)) + geom_hline(yintercept=0, linetype="dashed", color = "gray", size = 0.5) + geom_boxplot() + geom_point() + theme_classic() + labs(title = "", x = "Horizon", y = expression(τ[Ca])) + theme(legend.position = "none") + theme(plot.title = element_text(size=20,face="bold")) +  theme(axis.text.y = element_text(size=12)) + scale_fill_manual(values = c("#cccccc","#90593f","#cccccc","#90593f","#fcff54")) + scale_x_discrete(labels = prettylabs) + theme(axis.title.x = element_blank(), axis.title.y = element_text(size=15, face="plain"))
p3 <- ggplot(soilsub, aes(x = Cat, y = tau_Fe, fill = Cat)) + geom_hline(yintercept=0, linetype="dashed", color = "gray", size = 0.5) + geom_boxplot() + geom_point() + theme_classic() + labs(title = "", x = "Horizon", y = expression(τ[Fe])) + theme(legend.position = "none") + theme(plot.title = element_text(size=20,face="bold")) +  theme(axis.text.y = element_text(size=12)) + scale_fill_manual(values = c("#cccccc","#90593f","#cccccc","#90593f","#fcff54")) + scale_x_discrete(labels = prettylabs) + theme(axis.title.x = element_text(size=15, face="plain"), axis.title.y = element_text(size=15, face="plain"))

grid.arrange(p1, p2, p3, nrow = 3)
g <- arrangeGrob(p1, p2, p3, nrow=3)
ggsave(filename = "all3_soil_box_withextra.png", g)

grilled <- melt(soilsub, id=c("X","Pedon","TDepth","BDepth","Name","Depth","Cat","LV","Hor"))
grilled
cheese <- ddply(grilled, c("Pedon", "variable", "Cat"), summarise,
                  N = length(Pedon),
                  mean = mean(value),
                  sd = sd(value),
                  se = sd / sqrt(N))
cheese

qqPlot(soilsub$tau_Si)

#take out lateral E from Bhs
cheese2 <- cheese[!(cheese$Pedon == "52_3_X3.1" & cheese$Cat == "LE"),]
write.csv(cheese2,"values_tau/processed/means_datalist1.csv")

#anova
test <- aov(formula = tau_Ca ~ Cat, data = soilsub)
plot(test, 1)
plot(test, 2)
leveneTest(tau_Ca ~ Cat, data = soilsub)
TukeyHSD(test)


le <- filter(soilsub, Cat == "LE")
lb <- filter(soilsub, Cat == "LBhs")
ve <- filter(soilsub, Cat == "VE")
vb <- filter(soilsub, Cat == "VBhs")
c <- filter(soilsub, Cat == "DC")

hist(c$Ti)

avo <- cheese2[,1:5]
bread <- pivot_wider(avo, names_from = variable, values_from = mean)
nobutter <- bread[which(bread$Cat != "DC"),]
nopickle <- nobutter[which(nobutter$Cat != "VBhs" & nobutter$Cat != "VE"),]
sandy <- nobutter[which(nobutter$Cat != "LBhs" & nobutter$Cat != "VBhs"),]

ktest <- kruskal.test(tau_Ca ~ Cat, data = nobutter)

le2 <- filter(nobutter, Cat == "LE")
ve2 <- filter(nobutter, Cat == "VE")
vbhs2 <- filter(nobutter, Cat == "VBhs")
lbhs2 <- filter(nobutter, Cat == "LBhs")

wilcox.test(ve2$tau_Al, le2$tau_Al, alternative = "two.sided")
wilcox.test(ve2$tau_Al, vbhs2$tau_Al, alternative = "two.sided")
wilcox.test(le2$tau_Al, lbhs2$tau_Al, alternative = "two.sided")

prettylabs <- c("Lateral E", "Vertical E")
#cccccc
#fcff54

png(filename=paste0("dual_boxplot_7.png"), 
    units="in", 
    width=5, 
    height=6, 
    pointsize=12, 
    res=400)
ggplot(sandy, aes(x = Cat, y = tau_Al, fill = Cat), color = "black") +
  scale_y_continuous(breaks = c(-1,0,0.5)) + ylim(-1,0.2) + geom_hline(yintercept=0, linetype="dashed", color = "dark grey", size = 1) + geom_boxplot(outlier.shape = NA) + geom_point(size = 4, alpha = 0.5, shape = 2, position = position_jitterdodge(jitter.width = 1)) + theme_classic() + scale_x_discrete(labels = prettylabs) + labs(y = expression(τ[Al])) + theme(legend.position = 'none', axis.title.x = element_blank(), axis.text.x = element_text(size = 20), axis.title.y = element_text(size = 30), axis.text.y = element_text(size = 16)) + scale_fill_manual(values = c("#cccccc", "#fcff54"))
dev.off()

hist(ve$tau_Ca)
shapiro.test(le$tau_Ca)

ktest

#normality assumption is met for the whole dataset

dunn.test(nobutter$tau_P, nobutter$Cat, kw=TRUE, method = "bonferroni", altp = TRUE)
dunn.test(nobutter$tau_Al, nobutter$Cat, kw=TRUE, method = "bonferroni", altp = TRUE)
dunn.test(nobutter$tau_Si, nobutter$Cat, kw=TRUE, method = "bonferroni", altp = TRUE)
dunn.test(nopickle$tau_Ca, nopickle$Cat, kw=TRUE, method = "bonferroni", altp = TRUE)
dunn.test(nobutter$Ti, nobutter$Cat, kw=TRUE, method = "bonferroni", altp = TRUE)

?dunn.test()

?dunn.test
