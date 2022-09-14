# KMPlot-CHOL
A Shiny app to plot Kaplan-Meier curves for Cholangiocarcinoma survival based on gene expression data from the TCGA-CHOL project

### To run the app:
runGitHub("KMPlot-CHOL", "vtbhat")


### Data retrieval from TCGA
WHile packages such as TCGAbiolinks can be used to download the transcriptomic data for a particular TCGA project, ther ehva ebeen mulitple instances when the comple list of genes is not retrieved. Hence, the below code was use dto obtain the TPM values of the prtein-coding genes fromca folder containing all the transcriptome count files for the TCGA-CHOL project:

```
base_dir<-"GDCdata/TCGA-CHOL/"
counts_files<-paste0(base_dir, list.files(base_dir, recursive = TRUE))
genetpms<-data.frame(matrix(ncol=length(counts_files)+2, nrow=60664))
col_tpms<-c()
index = 3
for(file in counts_files)
{
  counts<-read.table(file, header=TRUE, fill=TRUE)
  file_basename<-basename(file)
  col_tpms<-append(col_tpms, caseids[[file_basename]])
  genetpms[index]<-counts[[7]]
  index<-index+1
}
genetpms[[1]]<-counts[[2]]
genetpms[[2]]<-counts[[3]]
colnames(genetpms)<-c("Gene", "Gene_Type", col_tpms)

#Remove non-protein-coding genes
genetpms<-subset(genetpms, Gene_Type=="protein_coding")
genetpms<-subset(genetpms, select=-c(Gene_Type))

```
