genedir<-"/home/uvi/be/avs/lustre/evolution_male_reprod_proteomes/genes"
genelist<-list.files(genedir)
evoldata<-data.frame(gene=genelist)

library(stringr)
#Add columns with number of sequences and sequence length
nseqs<-as.numeric()
seqlength<-as.numeric()

for (i in 1:length(genelist)){
  
  myfile<-readLines(paste(genedir,"/",genelist[i],"/paml/","M0/out",sep=""))
  
  nseqs[i]<-as.numeric(sapply(strsplit(myfile[4],split = " "),"[",5))
  seqlength[i]<-as.numeric(sapply(strsplit(myfile[4]," "),tail,1))
  
}

evoldata<-cbind(evoldata,nseqs,seqlength)

#Get columns with evolutionary rates (dN, dS, dN/dS)
dN<-as.numeric()
dS<-as.numeric()
dNdS<-as.numeric()

for (i in 1:length(genelist)){
  
  myfile<-readLines(paste(genedir,"/",genelist[i],"/paml/","M0/out",sep=""))
  
    dN[i]<-as.numeric(str_sub(grep("dN:",myfile,value = T), start=-6))
  dS[i]<-as.numeric(str_sub(grep("dS:",myfile,value = T), start=-7))
  dNdS[i]<-as.numeric(str_sub(grep("omega",myfile,value = T), start=-7))
}

evoldata<-cbind(evoldata,dN,dS,dNdS)

##Get columns with results from selection models (M8 vs M8a)
lhM8=as.numeric()
lhM8a=as.numeric()

for (i in 1:length(genelist)){
  
  myfileM8a<-readLines(paste(genedir,"/",genelist[i],"/paml/","M8a/out",sep=""))
  lhM8a[i]<-as.numeric(sapply(strsplit(myfileM8a[grep("lnL",myfileM8a)],split=": |    "),"[",4))
  
  myfileM8<-readLines(paste(genedir,"/",genelist[i],"/paml/","M8/out",sep=""))
  lhM8[i]<-as.numeric(sapply(strsplit(myfileM8[grep("lnL",myfileM8)],split=": |    "),"[",4))
  
  
}

lrt<-2*(lhM8-lhM8a)
pval<-1-pchisq(lrt,1) #Likelihood ratio test
padj<-p.adjust(lrt,method="fdr", n=length(lrt)) #Correct p-value for multiple testing

#Positive selection (yes/no)
psgenes<-character()

for (i in 1:nrow(evoldata)) {
  if (padj[i] < 0.05) {
    psgenes[i]="yes"
  }
  else {psgenes[i] = "no"}
  
}

#Number of sites under positive selection
pss<-as.numeric()

for (i in 1:length(genelist)){
  myfile_lrtM8<-readLines(paste(genedir,"/",genelist[i],"/paml/",genelist[i],"_M8_M8a.out",sep=""))
  pss[i]<-length(grep("selected",myfile_lrtM8))
}

evoldata<-cbind(evoldata, lhM8a,lhM8,lrt, padj, psgenes,pss)

#Add the tissue for each gene
##Epididymis
epid_df<-read.table("data/tissue_specificity_rna_epididymis.tsv",header=T,sep="\t")
epid_dnds<-evoldata[evoldata$gene %in% epid_df[,1],]
epid_dnds$tissue<-rep("epididymis",nrow(epid_dnds))
epid_dnds$expression<-epid_df[epid_df$Gene %in% evoldata$gene,16]
rm(epid_df)

##Prostate
prost_df<-read.table("data/tissue_specificity_rna_prostate.tsv",header=T,sep="\t")
prost_dnds<-evoldata[evoldata$gene %in% prost_df[,1],]
prost_dnds$tissue<-rep("prostate",nrow(prost_dnds))
prost_dnds$expression<-prost_df[prost_df$Gene %in% evoldata$gene,16]
rm(prost_df)

##Seminal fluid
semin_df<-read.table("data/tissue_specificity_rna_seminal.tsv",header=T,sep="\t")
semin_dnds<-evoldata[evoldata$gene %in% semin_df[,1],]
semin_dnds$tissue<-rep("SV",nrow(semin_dnds))
semin_dnds$expression<-semin_df[semin_df$Gene %in% evoldata$gene,16]
rm(semin_df)

#Concatenate data frames
evoltissues<-rbind(epid_dnds,prost_dnds,semin_dnds)