### ANOVA on accuracy as a function of rotation, samediff, and sex

f.tab0102 <- function () {
    infile <- "data01.rda";
    outfile <- "tab0102.txt";

    exit.function <- function () {
        while (sink.number() > 0) sink();
    }
    on.exit(exit.function());

    load(infile);

    sink(outfile);
    cat("ANOVA on accuracy as a function of rotation,\n");
    cat("samediff, and sex\n");
    print(summary(aov(Acc ~ Rotation * SameDiff * Sex +
                          Error(Subject / (Rotation * SameDiff)),
                      data01)));

    cat("\n\n\n");
    cat("ANOVA on accuracy as a function of rotation and sex,\n");
    cat("same trials only\n");
    print(summary(aov(Acc ~ Rotation * Sex +
                          Error(Subject / (Rotation)),
                      data01[data01$SameDiff == "same", ])));

    cat("\n\n\n");
    cat("ANOVA on accuracy as a function of rotation and sex,\n");
    cat("diff trials only\n");
    print(summary(aov(Acc ~ Rotation * Sex +
                          Error(Subject / (Rotation)),
                      data01[data01$SameDiff == "diff", ])));
    
}

f.tab0102();
rm(f.tab0102);
