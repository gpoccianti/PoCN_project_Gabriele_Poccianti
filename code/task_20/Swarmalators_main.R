library(igraph)
library(ggplot2)
library(RColorBrewer)
library(rgl)
library(deSolve)
library(gganimate)
library(dplyr)

source("Swarmalators.R")

set.seed(10)
# Set the number of nodes
N <- 300
# Set the total simulation time
t_f <- 300
# Set the number or independent MC realizations to generate
MC <- 1
#Set the integration step
dt <- 5e-2

# Calculates the length of the time series to generate
M <- ceiling(t_f/dt)

p <- 1/N
#generate a sample network
g <- erdos.renyi.game(N, p=p, directed=FALSE)
#g <- make_full_graph(N)

#We will work on unweighted networks
E(g)$weight <- 1


#Swarmalators equations
v_x <- 0
v_y <- 0
w <- 0
A <- 1
B <- 1
K <-  -0.6 
J <-  0.9

par <- data.frame(v_x = rep(v_x, N),
                  v_y = rep(v_y, N),
                  w = rep(w, N), 
                  A = rep(A, N), 
                  B = rep(B, N), 
                  J = rep(J, N), 
                  K = rep(K, N))

#par[] <- lapply(par, as.numeric)

res <- SWARM(g, size=M, parms=par,dt=dt)
phase <- res$th
x <- res$x
y <- res$y
plot.MultiTS(phase)


print <- FALSE  #decide if the plots/animations should be saved on a file
if(print == TRUE) {
  path_fig <- "Figures/ER_Network"
  path_anim <- "Animations/ER_Network"
  
  # Check if the directory exists, if not, create it
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  
  filename <- sprintf("swarmalators_complete_phase=%d,T=%d,dt=%.2f,K=%.2f,J=%.2f.jpg", N, M, dt, K, J)
  full_path <- file.path(path_fig, filename)
  
  # Open a jpeg device to save the plot
  jpeg(full_path, width = 800, height = 600)
  
  # Plot the phase
  plot.MultiTS(phase)
  
  # Close the jpeg device
  dev.off()
  
  message("Plot saved as ", full_path)
}

#Plot Network evolution in space
create_phase_palette <- function() {
  colorRampPalette(c("red","blue", "cyan", "green", "yellow", "red"))(100)
}

plot_movie_gganimate <- function(x, y, phase, write = FALSE, file_name = sprintf("swarmalators_ER_N=%d,p=%.2f,T=%d,dt=%.2f,K=%.2f,J=%.2f.mp4",N,p,M,dt,K,J)) {
  full_path <- file_name
  
  phase <- lapply(phase, function(p) p %% (2 * pi))
  
  # Create a data frame for plotting
  df <- data.frame(time = rep(seq_along(x[[1]]), length(x))*dt,
                   node = rep(seq_along(x), each = length(x[[1]])),
                   x = unlist(x),
                   y = unlist(y),
                   phase = unlist(phase))
  
  # Create the plot
  p <- ggplot(df, aes(x = x, y = y, color = phase)) +
    geom_point(size = 4, alpha = 0.7) +
    scale_color_gradientn(colors = create_phase_palette(), 
                          limits = c(0, 2*pi),
                          breaks = c(0, pi/2, pi, 3*pi/2, 2*pi),
                          labels = c("0", "π/2", "π", "3π/2", "2π")) +
    theme_minimal() +
    labs(
      title = 'Time: {sprintf("%.2f", frame_time)}', 
      x = 'X Position', 
      y = 'Y Position', 
      color = 'Phase'
    ) +
    transition_time(time) +
    ease_aes('linear')
  
  # If write == TRUE, save the animation to a file
  if (write) {
    anim <- animate(p, nframes = length(unique(df$time)), fps = 50, width = 600, height = 600, renderer = ffmpeg_renderer())
    
    # Save the animation
    anim_save(full_path, animation = anim)
    message("Animation saved to ", full_path)
    
  } else {
    # Otherwise, just plot the animation in the environment
    animate(p, nframes = length(unique(df$time)), fps = 50, width = 600, height = 600)
  }
}


plot_state <- function(x, y, phase, t, d=dt, write = FALSE, file_name = sprintf("swarmalators_state_t=%d_N=%d_K=%.2f_J=%.2f.jpg", t, N, K, J)) {
  full_path <- file_name
  # Ensure the phase values are within [0, 2*pi]
  phase <- lapply(phase, function(p) p %% (2 * pi))
  
  # Create a data frame for the time step t
  df <- data.frame(
    x = sapply(x, `[`, t),
    y = sapply(y, `[`, t),
    phase = sapply(phase, `[`, t)
  )
  
  # Create the plot with the same aesthetics as plot_movie_gganimate
  p <- ggplot(df, aes(x = x, y = y, color = phase)) +
    geom_point(size = 4, alpha = 0.7) +  # Set point size and transparency as the animation
    scale_color_gradientn(colors = create_phase_palette(), 
                          limits = c(0, 2 * pi),
                          breaks = c(0, pi/2, pi, 3 * pi/2, 2 * pi),
                          labels = c("0", "π/2", "π", "3π/2", "2π")) +
    coord_fixed() +
    theme_minimal() +
    labs(
      title = sprintf('State at t = %.2f', t * d),
      x = 'X Position', 
      y = 'Y Position', 
      color = 'Phase'
    )
  
  if (write) {
    jpeg(full_path, width = 600, height = 600)
    print(p)
    dev.off()
    message("Plot saved as ", full_path)
  } else {
    dev.new(width = 6, height = 6)
    print(p)
  }
}

#plot_movie_gganimate(x,y,phase,write=print)
t <- 300
plot_state(x, y, phase, write = FALSE,t=t/dt)


#Order parameter visualization


calculate_r <- function(MultiTS, N, M) {
  x <- 0
  y <- 0
  for(i in 1:length(MultiTS$th)){
    theta <- MultiTS$th[[i]][M]
    x <- x + cos(theta)
    y <- y + sin(theta)
  }
  x <- x/N
  y <- y/N
  
  r <- sqrt(x^2 + y^2)
  return(r)
}





calculate_S <- function(MultiTS, N, M) {
  x1 <- 0
  y1 <- 0
  x2 <- 0
  y2 <- 0
  
  for(i in 1:length(MultiTS$th)){
    theta <- MultiTS$th[[i]][M]
    x <- MultiTS$x[[i]][M]
    y <- MultiTS$y[[i]][M]
    angle <- atan2(y, x)
    #       angle <- atan(y/x)
    
    x1 <- x1 + cos(theta + angle)
    y1 <- y1 + sin(theta + angle)
    x2 <- x2 + cos(-theta + angle)
    y2 <- y2 + sin(-theta + angle)
  }
  
  # Normalize by number of swarmalators
  x1 <- x1 / N
  y1 <- y1 / N
  x2 <- x2 / N
  y2 <- y2 / N
  
  # Calculate S1 and S2
  S1 <- sqrt(x1^2 + y1^2)
  S2 <- sqrt(x2^2 + y2^2)
  
  # Return the maximum of S1 and S2
  S <- max(S1, S2)
  
  return(S)
}


calculate_U <- function(MultiTS, N, M) {
  completed_swarmalators <- 0
  
  for(i in 1:length(MultiTS$th)) {
    # Initialize cumulative changes in phase and space
    cumulative_phase_change <- 0
    cumulative_angle_change <- 0
    
    has_completed_circle_in_space <- FALSE
    has_completed_circle_in_phase <- FALSE
    
    for(t in 2:M) {
      # Extract previous and current phases
      previous_phase <- MultiTS$th[[i]][t - 1]
      current_phase <- MultiTS$th[[i]][t]
      
      # Extract previous and current positions
      previous_x <- MultiTS$x[[i]][t - 1]
      previous_y <- MultiTS$y[[i]][t - 1]
      current_x <- MultiTS$x[[i]][t]
      current_y <- MultiTS$y[[i]][t]
      
      # Calculate the angle in space for previous and current time steps
      previous_angle <- atan2(previous_y, previous_x)
      current_angle <- atan2(current_y, current_x)
      
      # Calculate the change in space angle
      angle_diff_in_space <- current_angle - previous_angle
      
      # Account for angle wrapping
      if (angle_diff_in_space > pi) {
        angle_diff_in_space <- angle_diff_in_space - 2 * pi
      } else if (angle_diff_in_space < -pi) {
        angle_diff_in_space <- angle_diff_in_space + 2 * pi
      }
      
      # Accumulate angle changes in space
      cumulative_angle_change <- cumulative_angle_change + angle_diff_in_space
      
      # Check if a full circle (2 * pi) is completed in space
      if (abs(cumulative_angle_change) >= 2 * pi) {
        has_completed_circle_in_space <- TRUE
      }
      
      # Calculate the change in phase
      phase_diff <- current_phase - previous_phase
      
      # Handle phase wrapping around 2*pi
      if (phase_diff > pi) {
        phase_diff <- phase_diff - 2 * pi
      } else if (phase_diff < -pi) {
        phase_diff <- phase_diff + 2 * pi
      }
      
      # Accumulate phase changes
      cumulative_phase_change <- cumulative_phase_change + phase_diff
      
      # Check if a full circle (2 * pi) is completed in phase
      if (abs(cumulative_phase_change) >= 2 * pi) {
        has_completed_circle_in_phase <- TRUE
      }
      
      # If both space and phase circles are completed, break early
      if (has_completed_circle_in_space && has_completed_circle_in_phase) {
        break
      }
    }
    
    # If both conditions are satisfied, count the swarmalator
    if (has_completed_circle_in_space && has_completed_circle_in_phase) {
      completed_swarmalators <- completed_swarmalators + 1
    }
  }
  
  # Calculate the fraction U
  U <- completed_swarmalators / N
  return(U)
}


p_seq <- c(0.5/N,1/N,2/N,0.1,0.3,0.5,0.7,0.8,0.9,1)
#res_r <- data.frame()
res_S <- data.frame()
res_U <- data.frame()
for(m in 1:10){
  cat(paste("\nMC #", m, "\n"))
  for(p in p_seq){ #in our case sigma is K
    g <- erdos.renyi.game(N, p=p, directed=FALSE)
    E(g)$weight <- 1
    MultiTS <- SWARM(g, size=M, parms = par)
    
    # Calculate order parameters
    #          r <- calculate_r(MultiTS,N,M)
    S <- calculate_S(MultiTS,N,M)
    U <- calculate_U(MultiTS,N,M)
    
    
    # Store results
    #          res_r <- rbind(res_r, data.frame(mc=m,p=p, r=r))
    res_S <- rbind(res_S, data.frame(mc=m, p=p, S=S))
    res_U <- rbind(res_U, data.frame(mc=m,p=p, U=U))
  }
}

#Plotting

#1) S
res_mean <- aggregate(S~p, res_S, mean)
res_sd <- aggregate(S~p, res_S, sd)
res_agg_S <- merge(res_mean, res_sd, by="p")
colnames(res_agg_S) <- c("p", "S_mean", "S_sd")

p_S <- ggplot(res_agg_S, aes(p, S_mean)) + 
  theme_bw() + 
  geom_point(color="steelblue", size=3) + 
  geom_errorbar(aes(ymin=S_mean-S_sd, ymax=S_mean+S_sd), color="steelblue") + 
  geom_smooth(color="tomato")
plot(p_S)

#2) U
res_mean <- aggregate(U~p, res_U, mean)
res_sd <- aggregate(U~p, res_U, sd)
res_agg_U <- merge(res_mean, res_sd, by="p")
colnames(res_agg_U) <- c("p", "U_mean", "U_sd")

p_U <- ggplot(res_agg_U, aes(p, U_mean)) + 
  theme_bw() + 
  geom_point(color="steelblue", size=3) + 
  geom_errorbar(aes(ymin=U_mean-U_sd, ymax=U_mean+U_sd), color="steelblue") + 
  geom_smooth(color="tomato")
plot(p_U)

#3) S+U
p <- ggplot(res_combined, aes(x = p)) + 
  theme_bw() + 
  
  geom_point(aes(y = S_mean, color = "S"), size = 3) + 
  geom_errorbar(aes(ymin = S_mean - S_sd, ymax = S_mean + S_sd, color = "S")) + 
  geom_smooth(aes(y = S_mean, color = "S"), se = FALSE) +
  
  geom_point(aes(y = U_mean, color = "U"), size = 3) + 
  geom_errorbar(aes(ymin = U_mean - U_sd, ymax = U_mean + U_sd, color = "U")) + 
  geom_smooth(aes(y = U_mean, color = "U"), se = FALSE) +
  
  labs(y = "mean", x = "p") +
  
  scale_color_manual(name = "order parameter",
                     values = c("S" = "tomato", "U" = "steelblue")) +
  
  theme(legend.position = "right")

plot(p)