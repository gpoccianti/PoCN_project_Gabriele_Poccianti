set.seed(1234)
library(igraph)
library(ggplot2)
library(RColorBrewer)
library(rgl)
library(dplyr)

##Functions
#Function to plot the square lattice

plot_grid <- function(S,g,bi=TRUE,label=TRUE) {
  state_colors <- c("red", "black", "white")
  S_colors <- state_colors[S]
  
  layout_matrix <- layout_on_grid(g)  
  
  L <- sqrt(vcount(g))
  node_size <- 230/L  # Adjust this factor to control overall plot size
  
  plot(g, 
       layout = layout_matrix, 
       vertex.size = node_size,               
       vertex.color = S_colors,      
       vertex.shape = "square",
       vertex.frame.color = NA,       
       vertex.label = NA,             
       edge.color = NA,                
       margin = -0.1
  )
  
  if(label) {
    if (bi) { #handle the labels for the two types of models
      legend_labels <- c("Language A", "Language B", "Bilingual")
    } else {
      legend_labels <- c("Language A", "Language B")
      state_colors <- state_colors[1:2]  # Only include the colors for Language A and B
    }
    
    legend("topright", 
           legend=legend_labels,
           col = "black",                      # Border color for the squares in the legend
           pt.bg = state_colors,               # Fill color for the squares in the legend
           pch = 22,                           # Square with border
           pt.cex = 1.5,                       # Size of the squares in the legend
           bty = "n",                          
           cex = 0.8                           
    )
  }
}


#One step evolution function (bilingual model)
  
step_bi <- function(S,g) {
  N <- vcount(g)
  #neighbors
  n_i <- lapply(1:N,function(v) neighbors(g,v))
  n <- sapply(n_i,length)
  #fractions of language users
  s_A <- sapply(n_i,function(j) (length(which(S[j]==1))))/n
  s_B <-sapply(n_i,function(j) (length(which(S[j]==2))))/n
  s_AB <- sapply(n_i,function(j) (length(which(S[j]==3))))/n
  
  #We randomly pick a node which has some probability to evolve into a different node
  #(has at least a neighbor of a different type)
  #idx <- which(s_A!=1 & s_B!=1 & s_AB!=1)
  idx_no <- which((s_A==1 & S==1) | (s_B==1 & S==2) | (s_AB==1 & S==3)) #we don't want all neigh of same type as i
  idx <- setdiff(1:N, idx_no)
  if(length(idx)==0) {
    return(S)
  }
  i <- sample(idx,1) 
  #update probability rule
  S[i] <- switch(S[i],
                 sample(c(3,1),size=1,p=c(0.5*s_B[i],1-0.5*s_B[i])),
                 sample(c(3,2),size=1,p=c(0.5*s_A[i],1-0.5*s_A[i])),
                 sample(c(1,2,3),size=1,p=c(0.5*(1-s_B[i]),0.5*(1-s_A[i]),0.5*(s_A[i]+s_B[i])))
  )
  return(S)
}


#One step evolution function (agent based Abrams-Strogatz model)
  
step_Str <- function(S,g) {
  N <- vcount(g)
  #neighbors
  n_i <- lapply(1:N,function(v) neighbors(g,v))
  n <- sapply(n_i,length)
  #fractions of language users
  s_A <- sapply(n_i,function(j) (length(which(S[j]==1))))/n
  s_B <-sapply(n_i,function(j) (length(which(S[j]==2))))/n
  
  #We randomly pick a node which has some probability to evolve into a different node
  #(has at least a neighbor of a different type)
  #idx <- which(s_A!=1 & s_B!=1 & s_AB!=1)
  idx_no <- which((s_A==1 & S==1) | (s_B==1 & S==2)) #we don't want all neigh of same type as i
  idx <- setdiff(1:N, idx_no)
  if(length(idx)==0) {
    return(S)
  }
  i <- sample(idx,1) 
  #update probability rule
  S[i] <- switch(S[i],
                 sample(c(1,2),size=1,p=c(1-0.5*s_B[i],0.5*s_B[i])),
                 sample(c(1,2),size=1,p=c(0.5*s_A[i],1-0.5*s_A[i]))
  )
  return(S)
}




##2D regular network
#Bilingual model

#side of the network
L <- 25
#number of nodes
N <- L^2

#Number of iterations in the dynamics
T_f <- 5000



#create the network
g <- make_lattice(dim = 2, length=L, circular = TRUE) #we impose PBC
#states vector (random initialization)
S <- sample(c(1,2,3),N,replace=TRUE) #state 1: first language, 2: second lanugage, 3: both (bilingual)
state_colors <- c("red", "black", "white")  # red for state 1, black for state 2, white for state 3




plot_grid(S,g)






#Evolution dynamics

#number of time steps
#T <- 10*N^1.8 #N^1.8 scaling of the expected time to reach the extinction of one language
T <- T_f
for (t in 1:T) {
  
  S <- step_bi(S,g)
  if((t %% 1000)==0 | t==1) { #take a shot every 1000 iterations
    png(filename = sprintf("Images/regular_net/bi/regular_net_bi_t=%d.png",t), width = 2000, height = 2000, res = 100)
    plot_grid(S,g,label=FALSE)
    dev.off()
  }
  if(all(S==S[1])) { #If one language dominates
    cat(sprintf("the system reached equilibrium at time %d",t))
    break 
  }
}


plot_grid(S,g)

#Save plot on file (optional)

plot <- TRUE
if(plot) {
  png(filename = sprintf("Images/regular_net/bi/regular_net_bi_t=%d.png",t), width = 2000, height = 2000, res = 100)
  plot_grid(S,g,label=FALSE)
  dev.off()
}


###Agent-based version of Abrams-Strogatz
#Similar transition rules, but no bilinguism

#create the network
g <- make_lattice(dim = 2, length=L, circular = TRUE) #we impose PBC
#states vector (random initialization)
S <- sample(c(1,2),N,replace=TRUE) #state 1: first language, 2: second lanugage
state_colors <- c("red", "black")  # red for state 1, black for state 2



plot_grid(S,g,bi=FALSE)



#Evolution dynamics

#number of time steps
#T <- 10*N^1.8 #N^1.8 scaling of the expected time to reach the extinction of one language
T <- T_f
for (t in 1:T) {
  
  S <- step_Str(S,g)
  if((t %% 1000)==0 | t==1) {
    png(filename = sprintf("Images/regular_net/Strogatz/regular_net_Str_t=%d.png",t), width = 2000, height = 2000, res = 100)
    plot_grid(S,g,label=FALSE)
    dev.off()
  }
  if(all(S==S[1])) { #If one language dominates
    cat(sprintf("the system reached equilibrium at time %d",t))
    break 
  }
}

plot_grid(S,g,bi=FALSE)


#Save plot on file (optional)

if(plot) {
  png(filename = sprintf("Images/regular_net/Strogatz/regular_net_Str_t=%d.png",t), width = 2000, height = 2000, res = 100)
  plot_grid(S,g,label=FALSE)
  dev.off()
}







##Small world network
###Bilingual model

# Parameters
p <- 0.1    # Rewiring probability
nei <- 1    # Neighborhood radius (each node is connected to 4 nearest neighbors)

#2D small-world network
small_world_net_2d <- sample_smallworld(dim = 2, size = L, nei = nei, p = p, loops = FALSE, multiple = FALSE)

S <- sample(c(1,2,3),N,replace=TRUE)

# Plot the network
plot(small_world_net_2d, 
     layout = layout_on_grid(small_world_net_2d), 
     vertex.size = 5,
     vertex.color=state_colors[S],
     vertex.label = NA,
     edge.color = "grey",
     edge.width = 0.5)

plot_grid(S,g)


if(plot) {
  png(filename = sprintf("Images/smallw/bi/smallw_bi_t2=%d.png",t), width = 2000, height = 2000,res=100)
  plot_grid(S,g,label=FALSE)
  dev.off()
}


#Evolution dynamics

#number of time steps
T <- T_f
for (t in 1:T) {
  
  S <- step_bi(S,g)
  if((t %% 1000)==0 | t==1) { #take a shot every 1000 iterations
    png(filename = sprintf("Images/smallw/bi/smallw_bi_t=%d.png",t), width = 2000, height = 2000, res = 100)
    plot_grid(S,g,label=FALSE)
    dev.off()
  }
  if(all(S==S[1])) { #If one language dominates
    cat(sprintf("the system reached equilibrium at time %d",t))
    break 
  }
}


plot_grid(S,g)



if(plot) {
  png(filename = sprintf("Images/smallw/bi/smallw_bi_t=%d.png",t), width = 2000, height = 2000, res = 100)
  plot_grid(S,g,label=FALSE)
  dev.off()
}





###Abrams-Strogatz

# Parameters
p <- 0.1    # Rewiring probability
nei <- 1    # Neighborhood radius (each node is connected to 4 nearest neighbors)

#2D small-world network
small_world_net_2d <- sample_smallworld(dim = 2, size = L, nei = nei, p = p, loops = FALSE, multiple = FALSE)

S <- sample(c(1,2),N,replace=TRUE)

# Plot the network
plot(small_world_net_2d, 
     layout = layout_on_grid(small_world_net_2d), 
     vertex.size = 5,
     vertex.color = state_colors[S],
     vertex.label = NA,
     edge.color = "grey",
     edge.width = 0.5)

plot_grid(S,g,bi=FALSE)



if(plot) {
  png(filename = sprintf("Images/smallw/Strogatz/smallw_Strogatz_t=%d.png",t), width = 2000, height = 2000, res = 100)
  plot_grid(S,g,label=FALSE)
  dev.off()
}


#Evolution dynamics

#number of time steps
T <- T_f
for (t in 1:T) {
  S <- step_Str(S,g)
  if((t %% 1000)==0 | t==1) { #take a shot every 1000 iterations
    png(filename = sprintf("Images/smallw/Strogatz/smallw_Strogatz_t=%d.png",t), width = 2000, height = 2000, res = 100)
    plot_grid(S,g,label=FALSE)
    dev.off()
  }
  if(all(S==S[1])) { #If one language dominates
    cat(sprintf("the system reached equilibrium at time %d",t))
    break 
  }
}

plot_grid(S,g,bi=FALSE)






if(plot) {
  png(filename = sprintf("Images/smallw/Strogatz/smallw_Strogatz_t=%d.png",t), width = 2000, height = 2000, res = 100)
  plot_grid(S,g,label=FALSE)
  dev.off()
}

