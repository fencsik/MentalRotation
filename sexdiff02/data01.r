### Aggregate accuracy and RT by subject, sex, samediff, and rotation

f.data01 <- function () {
    infile <- "FilteredData.rda";
    outfile <- "data01.rda";

    load(infile);

    ## generate datasets with all trials and with just correct responses
    dt.all <- filteredData;
    dt.cor <- filteredData[filteredData$Acc == 1, ];

    ## generate factor levels for both datasets
    factors.all <- with(dt.all, list(Subject=Subject, Sex=Sex,
                                     SameDiff=SameDiff, Rotation=Rotation));
    factors.cor <- with(dt.cor, list(Subject=Subject, Sex=Sex,
                                     SameDiff=SameDiff, Rotation=Rotation));

    ## collapse across the factors
    data01 <- aggregate(data.frame(Acc=dt.all$Acc), factors.all, mean);
    data01$RT.all <- aggregate(dt.all$RT, factors.all, mean)$x;
    data01$RT <- aggregate(dt.cor$RT, factors.cor, mean)$x;

    save(data01, file=outfile);
}

f.data01();
rm(f.data01);
