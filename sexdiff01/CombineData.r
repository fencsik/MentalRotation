### Combine data files
###
### Gather all the data files into a single data set, then output it to a
### binary file.

f.CombineData <- function () {
    datadir <- "data";
    outfile <- "CombineData.rda";

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

        ## correct sex
        dt$Sex <- as.character(dt$Sex);

        if (is.null(allData)) {
            allData <- dt;
        } else {
            allData <- rbind(allData, dt);
        }
        n.files.loaded <- n.files.loaded + 1;
    }

    cat("Loaded ", n.files.loaded, " data files with ",
        length(unique(allData$Subject)), " subjects\n", sep="");

    ## Correct sex variable (make them all M or F).  R gets confused and
    ## sometimes thinks F is FALSE, and students entered different codes.
    allData$Sex <- toupper(as.character(allData$Sex));
    allData$Sex[allData$Sex == "FALSE"] <- "F";
    allData$Sex[allData$Sex == "FEMALE"] <- "F";
    allData$Sex[allData$Sex == "MALE"] <- "M";
    allData$Sex[allData$Sex == " M"] <- "M";
    allData$Sex <- factor(allData$Sex);
    cat("\nLevels of sex:\n");
    print(levels(allData$Sex));

    ## Create factor for Rotation variable
    allData$Rotation <- factor(allData$Rotation);
    cat("\nLevels of angle:\n");
    print(levels(allData$Rotation));

    ## Correct age
    allData$Age[allData$Age == -1] <- NA;

    ## Save data file
    save(allData, file=outfile);
}

f.CombineData();
rm(f.CombineData);
