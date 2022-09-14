library(shiny)
library(shinythemes)
library(shinycssloaders)
library(googlesheets4)
library(survival)
library(dplyr)
library(survminer)

gs4_deauth()

clinicalinfo_id<-"https://docs.google.com/spreadsheets/d/1n8YEW0WwiNCbQcuyLEfjEd7DXEUN16qobov_qA1sgoI/edit?usp=sharing"
genetpms_id<-"https://docs.google.com/spreadsheets/d/1vMyDJGSjHu9ayzNzlxZZ8rpp8FTXCbOaWn58q6CI6Y8/edit?usp=sharing"
clinicalinfo<-as.data.frame(read_sheet(clinicalinfo_id))
genetpms<-as.data.frame(read_sheet(genetpms_id))
ui <- fluidPage(theme=shinytheme("yeti"),
                titlePanel(
                  h1(HTML("Kaplan-Meier Plots for Cholangiocarcinoma Survival"),
                  style={'background-color:#8BD3E6; padding:20px;align: top;'}
                )),
                h4("Please select the gene of interest from the dropdown menu. The KM curves will show the effect of the gene's expression on survival in cholangiocarcinoma patients"),
                sidebarLayout (
                  sidebarPanel(
                    selectizeInput("input_gene", "Select the gene of interest",
                    choices=NULL),
                    actionButton('submit_btn', 'Plot KM Curve',
                                 style="color: #fff; background-color: #337ab7; border-color: #2e6da4")
                  ),
                  mainPanel(
                    plotOutput("kmplot", width = "100%") %>% withSpinner(color="#0dc5c1")
                  )
                )
)
server <- function(input, output, session){
  updateSelectizeInput(session, 'input_gene', choices = as.vector(genetpms[[1]]), server=TRUE)
  kmplotobj<-eventReactive(
    input$submit_btn, {
      clinicalfile<-subset(clinicalfile, select=c(case_submitter_id, days_to_death,  vital_status))
      clinicalfile<-clinicalfile[!duplicated(clinicalfile), ]
      rownames(clinicalfile)<-clinicalfile[[1]]
      clinicalfile<-clinicalfile[rownames(clinicalfile) %in% col_tpms, ]
      osdata<-clinicalfile[["days_to_death"]]
      
      
      #Create a single object for survival analysis
      osdata<-c()
      #Columns required: id, time, status, expression
      gene<-input$input_gene
      generow<-t(subset(genetpms, Gene==gene))
      generow<-generow[-1,]
      generow<-as.data.frame(as.numeric(generow))
      colnames(generow)<-c("expr")
      median_expr<-median(generow$expr)
      generow$expr_grp<-ifelse(generow$expr>median_expr, "High Expression", "Low Expression")
      clinicalfile$expr_grp<-generow$expr_grp
      osdata<-clinicalfile
      osdata[[2]]<-as.numeric(osdata[[2]])
      osdata<-subset(osdata, vital_status=="Dead")
      osdata$vital_status<-ifelse(osdata$vital_status=="Dead", 1, 0)
      
      
      #Plot KM curves
      sfit <- survfit(Surv(days_to_death, vital_status)~expr_grp, data=osdata)
      return(sfit)
    }
  )
  
  output$kmplot<-renderPlot({
    ggsurvplot(kmplotobj(), pval=TRUE, legend.labs=c("High", "Low"),
               title=paste("Kaplan-Meier Curve for Cholangiocarcinoma Survival based on Expression of", isolate(input$input_gene), "Gene"),
               legend.title="Gene Expression") 
  })
  

}
