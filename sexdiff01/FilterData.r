### Filter full data set
###
### Filter out practice sessions and problematic subjects from the combined
### data file, then save to a binary file.

f.FilterData <- function () {
    infile <- "CombineData.rda";
    outfile <- "FilterData.rda";

    load(infile);

    cat("Before filtering, ", length(unique(allData$Subject)),
        " subjects in dataset\n", sep="");

    ## Filter out practice trials and any bad responses
    allData <- allData[allData$TrialType == "exp" & allData$Acc >= 0, ];
    allData$TrialType <- factor(as.character(allData$TrialType));
    allData$Response <- factor(as.character(allData$Response));

    ## Filter out subjects known to have problems.
    ##  - None yet
    ## allData <- allData[allData$Subject != 61 & allData$Subject != 78 &
    ##                    allData$Subject != 109 & allData$Subject != 123 &
    ##                    allData$Subject != 143 & allData$Subject != 250 &
    ##                    allData$Subject != 255, ];

    ## Filter out subjects with overall accuracy less than 60%
    allData <- allData[allData$Subject != 40 & allData$Subject != 45 &
                       allData$Subject !=  5 & allData$Subject != 11 &
                       allData$Subject != 49 & allData$Subject != 53, ];

    ## Make subjects a factor
    allData$Subject <- factor(allData$Subject);

    cat("After filtering, ", length(levels(allData$Subject)),
        " subjects remain\n", sep="");

    ## Print overall accuracy of lowest 10 remaining subjects
    cat("\nLowest 10 accuracies on all trials:\n");
    acc <- sort(round(with(allData,
                           tapply(Acc, list(Subject), mean)), 3));
    if (length(acc) > 10) {
        print(acc[1:10]);
    } else {
        print(acc);
    }
    cat("\nLowest 10 accuracies on same trials:\n");
    acc <- sort(round(with(allData[allData$SameDiff == "same", ],
                           tapply(Acc, list(Subject), mean)), 3));
    if (length(acc) > 10) {
        print(acc[1:10]);
    } else {
        print(acc);
    }
    cat("\nLowest 10 accuracies on different trials:\n");
    acc <- sort(round(with(allData[allData$SameDiff == "diff", ],
                           tapply(Acc, list(Subject), mean)), 3));
    if (length(acc) > 10) {
        print(acc[1:10]);
    } else {
        print(acc);
    }

    ## Save data file
    filteredData <- allData;
    save(filteredData, file=outfile);
}

f.FilterData();
rm(f.FilterData);
