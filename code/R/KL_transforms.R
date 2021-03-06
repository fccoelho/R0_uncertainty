### This piece of code implements the KL divergence minimization for transforms
# The idea is as follows: 
# Let y = M(x), where both x and y can be multivariate and M() is a continuous function. [obviously, dim(x) = dim(y)]
# Imagine each expert gives a distribution for x, f_i(x), without taking into account the induced distribution on y, g_i(y)
# If one pools the distributions for x using L(F(x); alpha) one obtains \pi(x), which in turn induces a distribution q_1(y)
# through the transform M().
# At this point we might want to choose alpha such that the divergence between each induced distribution g_i(y) and q_1(y)
# is minimized.
# The problem is then pick an \alpha such that L = sum(KL(g_i(y)||q_1(y))) attains a minimum
source("elicit_gamma.R")
source("gamma_ratio.R")
source("../../CODE/maxent_aux.R")
source("R0Example_four_gammas_parameters.r")
########################################
########################################
# Transform + min KL section. These functions only apply to the R_0 example.
# It's possible to write more general ones, though.
kl.transform <- function(alpha, a1v, b1v, a2v, b2v, Nv,  ga1, gb1, ga2, gb2, gN){
  # Computing the induced distribution using pool-then-induce (PI)
  # q_1(y) = M(\pi(x))[*] = dgamma.ratio(y, a1 = sum(alpha*a1v), b1 = sum(alpha*b1v), a2 = sum(alpha*a2v), b2 = sum(alpha*b2v))
  # g_i(y) = M(f_i(x)) =  dgamma.ratio(y, k1 = a1i, t1 = b1i, k2 = a2i, t2 = b2i)
  # * - beware of the abuse of notation
  kl2int <- function(y){
    dgamma.ratio(y, k1 = ga1, t1 = gb1, k2 = ga2, t2 = gb2, N = gN)* log(
      dgamma.ratio(y, k1 = ga1, t1 = gb1, k2 = ga2, t2 = gb2, N = gN)/
        dgamma.ratio(y, k1 = sum(alpha*a1v), t1 = sum(alpha*b1v),
                     k2 = sum(alpha*a2v), t2 = sum(alpha*b2v), N = sum(alpha*Nv))  
    )
  }  
  integrate(kl2int, 0, Inf)$value
}
###
optkltransform <- function(alpha, a1p, b1p, a2p, b2p, Np){
  # Let's first compute q_1(y) = M(\pi(x))
  K <- length(alpha)
  ds <- rep(NA, K) # the distances from each f_i to \pi
  for (i in 1:K){
    ds[i] <-  kl.transform(alpha = alpha, a1v = a1p, b1v = b1p,
                           a2v = a2p, b2v = b2p, Nv = Np, 
                           ga1 = a1p[i], gb1 = b1p[i],
                           ga2 = a2p[i], gb2 = b2p[i], gN = Np[i])
  } 
  return(ds)
}
optkltransform.inv <- function(alpha.inv, a1p, b1p, a2p, b2p, Np){
  alpha <- alpha.01(alpha.inv)
  sum(optkltransform(alpha, a1p, b1p, a2p, b2p, Np))
}

a <- optim(c(0, 0, 0), optkltransform.inv, a1p = k1v, b1p = t1v, a2p = k2v, b2p = t2v, Np = Nv)
#            method = "SANN", control=list(maxit = 100000))
(round(alpha.opt <- alpha.01(a$par), 2))
########################################
########################################
(k1star <- sum(alpha.opt*k1v)) 
(t1star <- 1/sum(alpha.opt*t1v))
(k2star <- sum(alpha.opt*k2v))
(t2star <- 1/sum(alpha.opt*t2v))
(Nstar <-  sum(alpha.opt*Nv))
## The pooled distribution for x[1] = \beta
pdf("../figures/minKL_infection.pdf")
curve(dgamma(x, k1star, t1star), 0, 3E-3, main = expression("Pooled distribution for the transmission rate", beta),
      ylab = expression(pi(beta)), xlab = expression(beta), col = 2, lwd = 3)
for (i in 1:length(Nv)){
  curve(dgamma(x, k1v[i], 1/(t1v[i]) ), 0, 3E-3, lty = i+1, lwd = 2, add = TRUE)  
}
legend(x = "topright", col = "red", lwd = 2, lty = 1, legend = "Pooled distribution", bty = "n")
dev.off()
## Now \pi(x[2]) = \pi(\gamma)
pdf("../figures/minKL_recovery.pdf")
curve(dgamma(x, k2star, t2star), 0, .5, main = expression("Pooled distribution for the recovery/removal rate", gamma),
      ylab = expression(pi(gamma)), xlab = expression(gamma), col = 3, lwd = 2)
for (i in 1:length(Nv)){
  curve(dgamma(x, k2v[i], 1/(t2v[i]) ), 0, .5, lty = i+1, lwd = 2, add = TRUE)  
}
legend(x = "topright", col = "green", lwd = 2, lty = 1, legend = "Pooled distribution", bty = "n")
dev.off()
## And finally what we got for R_0
pdf("../figures/minKL_R0.pdf")
curve(dgamma.ratio(x, k1 = k1star, t1 = 1/t1star, k2 = k2star, t2 = 1/t2star, N = Nstar), 0, 15,
      main = expression("Pooled distribution for the reproductive number", R[0]),
      ylab = expression(pi(R[0])), xlab = expression(R[0]), col = 4, lwd = 2)
for (i in 1:length(Nv)){
  curve(dgamma.ratio(x, k1 = k1v[i], t1 = t1v[i], k2 = k2v[i], t2 = t2v[i], N = Nv[i]), 0, 15,
        lty = i+1, lwd = 2, add = TRUE)  
}
legend(x = "topright", col = "blue", lwd = 2, lty = 1, legend = "Pooled distribution", bty = "n")
dev.off()