### Counts the number of men and women with overal accuracy at or above
### certain levels

f.tab0001 <- function () {
    infile <- "FilterData.rda";
    outfile <- "tab0001.txt";
    accuracy.levels <- c(.95, .90, .80, .75, .7, .6, .5);

    exit.function <- function () {
        while (sink.number() > 0) sink();
    }
    on.exit(exit.function());

    load(infile);

    ## Compute each subject's average accuracy
    dt <- with(filteredData, aggregate(data.frame(Acc=Acc),
                                       list(Subject=Subject, Sex=Sex), mean));
    print(summary(dt));

    ## Prepare table
    acc.table <- array(dim=c(length(accuracy.levels), 3),
                       dimnames=list(1:length(accuracy.levels),
                           c("Min Accuracy", "Men", "Women")));
    acc.table[, 1] <- accuracy.levels;

    ## Count subjects
    for (i in 1:length(accuracy.levels)) {
        a <- accuracy.levels[i];
        acc.table[i, "Men"] <- sum(dt$Sex == "M" & dt$Acc >= a);
        acc.table[i, "Women"] <- sum(dt$Sex == "F" & dt$Acc >= a);
    }
    print(acc.table);
}

f.tab0001();
rm(f.tab0001);
