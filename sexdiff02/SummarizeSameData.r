### Generate data summaries
###
### Generate summaries from filtered data, then output to a tab-delimited
### text file.

f.SummarizeData <- function () {
    infile <- "FilteredData.rda";
    outfile <- "DataSummary-4802-20144.txt";

    load(infile);

    ## Filter out different trials
    filteredData <- filteredData[filteredData$SameDiff == "same", ];

    ## Correct age for averaging
    filteredData$Age[is.na(filteredData$Age)] <- -1;

    ## Prepare summary table
    dt <- with(filteredData,
               aggregate(data.frame(dropThisColumn=Acc),
                         list(Subject=Subject, Experimenter=Experimenter,
                              Age=Age, Sex=Sex, Class=Experiment), mean));
    dt <- dt[, colnames(dt) != "dropThisColumn"];
    dt <- dt[order(dt$Subject), ];
    row.names(dt) <- 1:dim(dt)[1];

    ## Calculate accuracies
    acc <- round(100 * with(filteredData, tapply(Acc, list(Subject, Rotation), mean)), 1);
    colnames(acc) <- paste("Accuracy", levels(filteredData$Rotation), sep="")
    dt <- cbind(dt, acc);

    ## Calculate RTs on correct trials
    rt <- round(with(filteredData[filteredData$Acc == 1, ],
                     tapply(RT, list(Subject, Rotation), mean)), 0);
    colnames(rt) <- paste("RT", levels(filteredData$Rotation), sep="");
    dt <- cbind(dt, rt);

    write.table(dt, file=outfile, quote=FALSE, sep="\t",
                row.names=FALSE, col.names=TRUE);
}

f.SummarizeData();
rm(f.SummarizeData);
