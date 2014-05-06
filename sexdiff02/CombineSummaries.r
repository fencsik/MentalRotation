### Collect data summary files
###
### Combine all the data summary files into a single data set.  Filter out practice sessions and know problem subjects.  Output to a tab-delimited text file.

f.CombineSummaries <- function () {
    datadir <- "datasummary";
    outfile <- "AllData-4802-20142.txt";

    infiles <- file.path(datadir, dir(datadir));

    varnames <- NULL;
    varnamesFromFile <- NULL;
    allData <- NULL;
    n.files.loaded <- 0;

    for (f in infiles) {
        if (!file.exists(f)) stop("cannot find input file ", f);
        dt <- read.delim(f);

        if (is.null(varnames)) {
            varnames <- colnames(dt);
            varnamesFromFile <- f;
        } else if (dim(dt)[2] != length(varnames) || !all(names(dt) == varnames)) {
            warning("column names in ", f, " do not match those in ", varnamesFromFile);
            dt <- dt[, varnames];
        }

        if (is.null(allData)) {
            allData <- dt;
        } else {
            allData <- rbind(allData, dt);
        }
        n.files.loaded <- n.files.loaded + 1;
    }

    cat("Loaded ", n.files.loaded, " data files with ",
        length(unique(allData$Subject)), " subjects\n", sep="");

    ## Filter out practice sessions, which were run on 2nd day of class
    ## with version 0.98 of the code.  The actual experiment was v1.0.
    allData <- allData[allData$Version != 0.98, ]

    ## Filter out subjects known to have problems.
    ##  - Obviously unmotivated: 61,
    ##  - Ran twice: 78
    ##  - Blatant fast guesses: 109, 123
    allData <- allData[allData$Subject != 61 & allData$Subject != 78 &
                       allData$Subject != 109 & allData$Subject != 123, ];

    ## Filter out subjects with overall "same" accuracy less than 60%: 20,
    ## 23, 50, 100, and 113
    allData <- allData[allData$Subject != 20 & allData$Subject != 23 &
                       allData$Subject != 50 & allData$Subject != 100 &
                       allData$Subject != 113, ];

    ## Capitalize Experimenter ID
    allData$Experimenter <- factor(toupper(as.character(allData$Experimenter)));

    ## Correct sex variable (make them all M or F).  R gets confused and
    ## sometimes things F is FALSE, and students entered different codes.
    allData$Sex <- toupper(as.character(allData$Sex));
    allData$Sex[allData$Sex == FALSE] <- "F";
    allData$Sex[allData$Sex == "FALSE"] <- "F";
    allData$Sex[allData$Sex == "FEMALE"] <- "F";
    allData$Sex <- factor(allData$Sex);

    cat("After filtering, ", length(unique(allData$Subject)),
        " subjects remain \n", sep="");

    write.table(allData, file=outfile, quote=FALSE, sep="\t",
                row.names=FALSE, col.names=TRUE);
}

f.CombineSummaries();
rm(f.CombineSummaries);
