### Filter full data set
###
### Filter out practice sessions and problematic subjects from the combined
### data file, then save to a binary file.

f.FilterData <- function () {
    infile <- "AllData.rda";
    outfile <- "FilteredData.rda";

    load(infile);

    cat("Before filtering, ", length(unique(allData$Subject)),
        " subjects in dataset\n", sep="");

    ## Filter out practice trials and any bad responses
    allData <- allData[allData$TrialType == "exp" & allData$Acc >= 0, ];
    allData$TrialType <- factor(as.character(allData$TrialType));
    allData$Response <- factor(as.character(allData$Response));

    ## Filter out subjects known to have problems.
    ##  - Obviously unmotivated: 61, 143
    ##  - Ran twice: 78
    ##  - Blatant fast guesses: 109, 123
    ##  - Forgot to obtain consent: 250
    ##  - Handicap interferred with responses: 255
    allData <- allData[allData$Subject != 61 & allData$Subject != 78 &
                       allData$Subject != 109 & allData$Subject != 123 &
                       allData$Subject != 143 & allData$Subject != 250 &
                       allData$Subject != 255, ];

    ## Filter out subjects with overall accuracy less than 60%
    allData <- allData[allData$Subject != 17 & allData$Subject != 23 &
                       allData$Subject != 41 & allData$Subject != 50 &
                       allData$Subject != 53 & allData$Subject != 62 &
                       allData$Subject != 65 & allData$Subject != 75 &
                       allData$Subject != 76 & allData$Subject != 93 &
                       allData$Subject != 96 & allData$Subject != 100 &
                       allData$Subject != 113 & allData$Subject != 151 &
                       allData$Subject != 233 & allData$Subject != 247 &
                       allData$Subject != 251 & allData$Subject != 253 &
                       allData$Subject != 254 & allData$Subject != 263 &
                       allData$Subject != 272 & allData$Subject != 279 &
                       allData$Subject != 281 & allData$Subject != 290 &
                       allData$Subject != 297 & allData$Subject != 300 &
                       allData$Subject != 314 & allData$Subject != 319 &
                       allData$Subject != 323 & allData$Subject != 332 &
                       allData$Subject != 333, ];

    cat("After filtering, ", length(unique(allData$Subject)),
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
