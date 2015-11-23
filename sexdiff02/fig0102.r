### Plot average accuracy as a function of rotation, separated by samediff
### and sex

f.fig0102 <- function () {
    infile <- "data01.rda";
    outfile <- "fig0102.pdf";

    exit.function <- function () {
        if (exists("opar")) par(opar);
        if (any(names(dev.cur()) == "pdf")) dev.off();
    }
    on.exit(exit.function());

    load(infile);

    ## extract relevant data
    dt <- with(data01, tapply(Acc, list(Rotation, SameDiff, Sex), mean));
    x <- as.numeric(dimnames(dt)[[1]]);

    ## open plot file and set it up
    pdf(outfile, width=6, height=6, pointsize=12);
    opar <- par(mfrow=c(1, 1), las=1, pty="m", cex.axis=.6,
                xpd=NA, bg="white");
    col <- c("blue", "green3"); # female, male
    lty <- c(2, 1); # diff, same

    ## generate plot layout
    matplot(x, cbind(dt[, , 1], dt[, , 2]),
            type="n", bty="n",
            xlab="Rotation (degrees)", ylab="Proportion correct");
    axis(1, x);
    axis(2);

    ## add lines to plot
    for (i in 1:dim(dt)[2]) {
        for (j in 1:dim(dt)[3]) {
            matlines(x, dt[, i, j], type="o",
                     lty=lty[i], col=col[j],
                     pch=21, lwd=2, cex=1.5, bg="white");
        }
    }

    ## add legends
    legend("topright", dimnames(dt)[[3]],
           bty="n", cex=.75, pt.cex=1.2, pt.bg="white",
           col=col, pch=21, lty=1, lwd=2);
    legend("topright", dimnames(dt)[[2]], inset=c(0.15, 0),
           bty="n", cex=.75, pt.cex=1.2, pt.bg="white",
           col="black", lty=lty, lwd=2);
}

f.fig0102();
rm(f.fig0102);
