### Write down what package versions work with your R code, and
### attempt to download and load those packages. The first argument is
### the version of R that you used, e.g. "3.0.2" and then the rest of
### the arguments are package versions. For
### CRAN/Bioconductor/R-Forge/etc packages, write
### e.g. RColorBrewer="1.0.5" and if RColorBrewer is not installed
### then we use install.packages to get the most recent version, and
### warn if the installed version is not the indicated version. For
### GitHub packages, write "user/repo@commit"
### e.g. "tdhock/animint@f877163cd181f390de3ef9a38bb8bdd0396d08a4" and
### we use install_github to get it, if necessary.
works_with_R <- function(Rvers,...){
  pkg_ok_have <- function(pkg,ok,have){
    stopifnot(is.character(ok))
    if(!as.character(have) %in% ok){
      warning("works with ",pkg," version ",
              paste(ok,collapse=" or "),
              ", have ",have)
    }
  }
  pkg_ok_have("R",Rvers,getRversion())
  pkg.vers <- list(...)
  for(pkg.i in seq_along(pkg.vers)){
    vers <- pkg.vers[[pkg.i]]
    pkg <- if(is.null(names(pkg.vers))){
      ""
    }else{
      names(pkg.vers)[[pkg.i]]
    }
    if(pkg == ""){# Then it is from GitHub.
      ## suppressWarnings is quieter than quiet.
      if(!suppressWarnings(require(requireGitHub))){
        ## If requireGitHub is not available, then install it using
        ## devtools.
        if(!suppressWarnings(require(devtools))){
          install.packages("devtools")
          require(devtools)
        }
        install_github("tdhock/requireGitHub")
        require(requireGitHub)
      }
      requireGitHub(vers)
    }else{# it is from a CRAN-like repos.
      if(!suppressWarnings(require(pkg, character.only=TRUE))){
        install.packages(pkg)
      }
      pkg_ok_have(pkg, vers, packageVersion(pkg))
      library(pkg, character.only=TRUE)
    }
  }
}
works_with_R(
  "3.3.3",
  partykit="2.0.2",#R CMD INSTALL partykit/pkg/devel/partykit/
  libcoin="0.9.1",
  mlt="0.1.3",
  trtf="0.1.1",#R CMD INSTALL ctm/pkg/trtf/
  "tdhock/penaltyLearning@2e9ad040a97e2baf4623549f114d3817b10e5fbf",
  survival="2.41.2")

data(neuroblastomaProcessed, package="penaltyLearning")
finite.targets <- with(neuroblastomaProcessed, {
  data.frame(log.penalty=target.mat[is.finite(target.mat)])
})
m <- ctm(as.basis(~log.penalty, data=finite.targets), todistr="Normal")
train.Surv <- with(neuroblastomaProcessed, {
  Surv(target.mat[, 1], target.mat[,2], type="interval2")
})

## Train on n=50 observations and p=2 features => learned constant
## model (predict all 1).
train.feature.mat <- neuroblastomaProcessed$feature.mat[, c("log.n", "log.mad")]
train.df <- data.frame(log.penalty=train.Surv, train.feature.mat)[1:50,]
mlt.fit <- mlt(m, data=train.df)
tree.fit <- trafotree(
  m, formula = log.penalty ~ ., data=train.df,
  mltargs=list(theta=coef(mlt.fit)))
predict(tree.fit)

## Train on n=30 observations and p=2 features => learned constant
## model (predict all 1), and Warning message: In
## object$optimfct(theta, weights = weights, scale = scale, optim =
## optim) : Optimisation did not converge.
train.feature.mat <- neuroblastomaProcessed$feature.mat[, c("log.n", "log.mad")]
train.df <- data.frame(log.penalty=train.Surv, train.feature.mat)[1:30,]
mlt.fit <- mlt(m, data=train.df)
tree.fit <- trafotree(
  m, formula = log.penalty ~ ., data=train.df,
  mltargs=list(theta=coef(mlt.fit)))
predict(tree.fit)

## Train on all n=3418 observations and p=2 features => learns
## non-trivial model.
train.feature.mat <- neuroblastomaProcessed$feature.mat[, c("log.n", "log.mad")]
train.df <- data.frame(log.penalty=train.Surv, train.feature.mat)
mlt.fit <- mlt(m, data=train.df)
tree.fit <- trafotree(
  m, formula = log.penalty ~ ., data=train.df,
  mltargs=list(theta=coef(mlt.fit)))
node_party(tree.fit) # 15-node tree.
tree.fit$coef # 8 leaf nodes.

## I'm not sure if this is the right way to get predicted output
## values:
pred.vec <- predict(tree.fit)
pred.log.penalty <- tree.fit$coef[names(pred.vec), "(Intercept)"]
is.lo <- pred.log.penalty < neuroblastomaProcessed$target.mat[, 1]
is.hi <- neuroblastomaProcessed$target.mat[, 2] < pred.log.penalty
is.error <- is.lo | is.hi
mean(is.error)

## Ultimately, I would like to train on all n=3418 observations and
## all p=117 features.
train.df <- data.frame(
  log.penalty=train.Surv, neuroblastomaProcessed$feature.mat)
mlt.fit <- mlt(m, data=train.df)
tree.fit <- trafotree(
  m, formula = log.penalty ~ ., data=train.df,
  mltargs=list(theta=coef(mlt.fit)))
node_party(tree.fit) # 19-node tree.
tree.fit$coef 
