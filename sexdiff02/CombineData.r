### Combine data files
###
### Gather all the data files into a single data set.  Filter out practice
### sessions and subjects, generate summaries, then output to a
### tab-delimited text file.

f.CombineData <- function () {
    datadir <- "data";
    outfile <- "AllData-4802-20144.txt";

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

    ## Filter out practice sessions, which were run on 2nd day of class in
    ## Spring 2014 with version 0.98 of the code.  The actual experiment
    ## was v1.0 in Spring 2014 and part of Fall 2014, then v1.0.1 for most
    ## of Fall 2014.
    allData <- allData[allData$Version != 0.98, ]

    ## Filter out practice trials and any bad responses
    allData <- allData[allData$TrialType == "exp" & allData$Acc >= 0, ];

    ## Filter out subjects known to have problems.
    ##  - Obviously unmotivated: 61, 143
    ##  - Ran twice: 78
    ##  - Blatant fast guesses: 109, 123
    ##  - Forgot to obtain consent: 250
    ##  - Handicap interferred with responsed: 255
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
        " subjects remain \n", sep="");

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

    ## Filter out different trials
    allData <- allData[allData$SameDiff == "same", ];

    ## Capitalize Experimenter ID
    allData$Experimenter <- factor(toupper(as.character(allData$Experimenter)));

    ## Correct subject ages.  Anything less than 17 is a -1 (not given) or
    ## a mistake.
    allData$Age[allData$Age < 17] <- -1;

    ## Correct sex variable (make them all M or F).  R gets confused and
    ## sometimes things F is FALSE, and students entered different codes.
    allData$Sex <- toupper(as.character(allData$Sex));
    allData$Sex[allData$Sex == FALSE] <- "F";
    allData$Sex[allData$Sex == "FALSE"] <- "F";
    allData$Sex[allData$Sex == "FEMALE"] <- "F";
    allData$Sex[allData$Sex == "MALE"] <- "M";
    allData$Sex <- factor(allData$Sex);
    cat("\nLevels of sex:\n");
    print(levels(allData$Sex));

    ## Create factor for Rotation variable
    allData$Rotation <- factor(allData$Rotation);
    cat("\nLevels of angle:\n");
    print(levels(allData$Rotation));

    ## Prepare summary table
    dt <- with(allData,
               aggregate(data.frame(dropThisColumn=Acc),
                         list(Subject=Subject, Experimenter=Experimenter,
                              Age=Age, Sex=Sex, Class=Experiment), mean));
    dt <- dt[, colnames(dt) != "dropThisColumn"];
    dt <- dt[order(dt$Subject), ];
    row.names(dt) <- 1:dim(dt)[1];

    ## Calculate accuracies
    acc <- round(100 * with(allData, tapply(Acc, list(Subject, Rotation), mean)), 1);
    colnames(acc) <- paste("Accuracy", levels(allData$Rotation), sep="")
    dt <- cbind(dt, acc);

    ## Calculate RTs on correct trials
    rt <- round(with(allData[allData$Acc == 1, ],
                     tapply(RT, list(Subject, Rotation), mean)), 0);
    colnames(rt) <- paste("RT", levels(allData$Rotation), sep="");
    dt <- cbind(dt, rt);

    ## Correct age
    dt$Age[dt$Age == -1] <- NA;

    write.table(dt, file=outfile, quote=FALSE, sep="\t",
                row.names=FALSE, col.names=TRUE);
}

f.CombineData();
rm(f.CombineData);
