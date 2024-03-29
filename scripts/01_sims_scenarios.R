# Let's make data for the three different scenarios
# Scenario 1: fixed home ranges
# Scenario 2: randomly-moving home ranges
# Scenario 3: directionally-moving home ranges
source("scripts/00.1_functions.R")
library(tidyverse)
library(viridis)
socLevels <- seq(from = 0, to = 1, by = 0.1)

# SIM 1 -------------------------------------------------------------------
r <- 0.01 # home range centers effectively not moving
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 0.01
hre <- 0.7

# sim1_ns <- simulateAgents(N = 30,
#                        Days = 50,
#                        DayLength = 50,
#                        Soc_Percep_Rng = 1000,
#                        Scl = 1000,
#                        seed = 9252023,
#                        EtaCRW = 0.7,
#                        StpSize_ind = baseAgentStep,
#                        StpStd_ind = 5,
#                        Kappa_ind = 4,
#                        quiet = T,
#                        sim_3 = F,
#                        socialWeight = 0,
#                        HREtaCRW = 0.7,
#                        HRStpSize = HRStpSize,
#                        HRStpStd = HRStpStd,
#                        HRKappa_ind = hrk)
# save(sim1_ns, file = "data/simulations/sim1_ns.Rda")
load("data/simulations/sim1_ns.Rda")

hr <- sim1_ns$HRCent %>% as.data.frame() %>% mutate(indiv = 1:nrow(.)) %>% rename("X" = V1, "Y" = V2)

ggplot() + 
  geom_point(data = sim1_ns$XY, aes(x = X, y = Y, col = day))+
  geom_point(data = hr, aes(x = X, y = Y), pch = 19, size = 5)+
  facet_wrap(~indiv, scales = "free")+theme_minimal()+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_viridis()+
  ggtitle("Scenario 1, non-sociable")

indivs <- sample(unique(sim1_ns$XY$indiv), 10)
p_s1_ns <- sim1_ns$XY %>% 
  filter(indiv %in% indivs) %>%
  ggplot() +
  geom_path(data = sim1_ns$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv), 
            linewidth = 1, alpha = 0.9)+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 1, non-sociable")
#geom_point(data = hr, aes(x = X, y = Y), col = "black", size = 3)
ggsave(p_s1_ns, file = "fig/trajectories/p_s1_ns.png", width = 6, height = 7)

# sim1_socLevels <- map(socLevels, ~{
#   sim <- simulateAgents(N = 30,
#                            Days = 50,
#                            DayLength = 50,
#                            Soc_Percep_Rng = 1000,
#                            Scl = 1000,
#                            seed = 9252023,
#                            EtaCRW = 0.7,
#                            StpSize_ind = baseAgentStep,
#                            StpStd_ind = 5,
#                            Kappa_ind = 4,
#                            quiet = T,
#                            sim_3 = F,
#                            socialWeight = .x,
#                            HREtaCRW = 0.7,
#                            HRStpSize = HRStpSize,
#                            HRStpStd = HRStpStd,
#                            HRKappa_ind = hrk)
#   return(sim)
# })
# save(sim1_socLevels, file = "data/simulations/sim1_socLevels.Rda")

# sim1_s <- simulateAgents(N = 30,
#                           Days = 50,
#                           DayLength = 50,
#                           Soc_Percep_Rng = 1000,
#                           Scl = 1000,
#                           seed = 9252023,
#                           EtaCRW = 0.7,
#                           StpSize_ind = baseAgentStep,
#                           StpStd_ind = 5,
#                           Kappa_ind = 4,
#                           quiet = T,
#                           sim_3 = F,
#                           socialWeight = 0.75,
#                           HREtaCRW = 0.7,
#                           HRStpSize = HRStpSize,
#                           HRStpStd = HRStpStd,
#                           HRKappa_ind = hrk)
# save(sim1_s, file = "data/simulations/sim1_s.Rda")
load("data/simulations/sim1_s.Rda")

hr <- sim1_s$HRCent %>% as.data.frame() %>% mutate(indiv = 1:nrow(.)) %>% rename("X" = V1, "Y" = V2)

# ggplot() + 
#   geom_point(data = sim1_s$XY, aes(x = X, y = Y, col = day))+
#   geom_point(data = hr, aes(x = X, y = Y), pch = 19, size = 5)+
#   facet_wrap(~indiv, scales = "free")+theme_minimal()+
#   theme(legend.position = "none", axis.text = element_text(size = 18))+
#   scale_color_viridis()+
#   ggtitle("Scenario 1, sociable")

indivs <- sample(unique(sim1_s$XY$indiv), 10)
p_s1_s <- sim1_s$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim1_s$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 1, sociable")
#geom_point(data = hr, aes(x = X, y = Y), col = "black", size = 3)
ggsave(p_s1_s, file = "fig/trajectories/p_s1_s.png", width = 6, height = 7)

# SIM 2 -------------------------------------------------------------------
r <- 10 # home range steps are 10x the size of agent steps
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 0.01 # effectively k = 0, random direction for home range movement.
hre <- 0.7

# sim2_ns <- simulateAgents(N = 30,
#                           Days = 50,
#                           DayLength = 50,
#                           Soc_Percep_Rng = 1000,
#                           Scl = 1000,
#                           seed = 9252023,
#                           EtaCRW = 0.7,
#                           StpSize_ind = baseAgentStep,
#                           StpStd_ind = 5,
#                           Kappa_ind = 4,
#                           quiet = T,
#                           sim_3 = T,
#                           socialWeight = 0,
#                           HREtaCRW = 0.7,
#                           HRStpSize = HRStpSize,
#                           HRStpStd = HRStpStd,
#                           HRKappa_ind = hrk)
# save(sim2_ns, file = "data/simulations/sim2_ns.Rda")
load("data/simulations/sim2_ns.Rda")
# 
# ggplot() + 
#   geom_point(data = sim2_ns$XY, aes(x = X, y = Y, col = day))+
#   geom_point(data = sim2_ns$HRCent, aes(x = X, y = Y, col = day), 
#              pch = 19, size = 5)+
#   facet_wrap(~indiv, scales = "free")+theme_minimal()+
#   theme(legend.position = "none", axis.text = element_text(size = 18))+
#   scale_color_viridis()+
#   ggtitle("Scenario 2, non-sociable")

indivs <- sample(unique(sim2_ns$XY$indiv), 10)
p_s2_ns <- sim2_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim2_ns$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 2, non-sociable")
ggsave(p_s2_ns, file = "fig/trajectories/p_s2_ns.png", width = 6, height = 7)

# sim2_socLevels <- map(socLevels, ~{
#   sim <- simulateAgents(N = 30,
#                  Days = 50,
#                  DayLength = 50,
#                  Soc_Percep_Rng = 1000,
#                  Scl = 1000,
#                  seed = 9252023,
#                  EtaCRW = 0.7,
#                  StpSize_ind = baseAgentStep,
#                  StpStd_ind = 5,
#                  Kappa_ind = 4,
#                  quiet = T,
#                  sim_3 = T,
#                  socialWeight = .x,
#                  HREtaCRW = 0.7,
#                  HRStpSize = HRStpSize,
#                  HRStpStd = HRStpStd,
#                  HRKappa_ind = hrk)
#   return(sim)
# })
# save(sim2_socLevels, file = "data/simulations/sim2_socLevels.Rda")

# sim2_s <- simulateAgents(N = 30,
#                           Days = 50,
#                           DayLength = 50,
#                           Soc_Percep_Rng = 1000,
#                           Scl = 1000,
#                           seed = 9252023,
#                           EtaCRW = 0.7,
#                           StpSize_ind = baseAgentStep,
#                           StpStd_ind = 5,
#                           Kappa_ind = 4,
#                           quiet = T,
#                           sim_3 = T,
#                           socialWeight = 0.75,
#                           HREtaCRW = 0.7,
#                           HRStpSize = HRStpSize,
#                           HRStpStd = HRStpStd,
#                           HRKappa_ind = hrk)
# save(sim2_s, file = "data/simulations/sim2_s.Rda")
load("data/simulations/sim2_s.Rda")

# ggplot() + 
#   geom_point(data = sim2_s$XY, aes(x = X, y = Y, col = day))+
#   geom_point(data = sim2_s$HRCent, aes(x = X, y = Y, col = day), 
#              pch = 19, size = 5)+
#   facet_wrap(~indiv, scales = "free")+theme_minimal()+
#   theme(legend.position = "none", axis.text = element_text(size = 18))+
#   scale_color_viridis()+
#   ggtitle("Scenario 2, sociable")

indivs <- sample(unique(sim2_s$XY$indiv), 10)
p_s2_s <- sim2_s$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim2_s$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 2, sociable")
ggsave(p_s2_s, file = "fig/trajectories/p_s2_s.png", width = 6, height = 7)

# SIM 3 -------------------------------------------------------------------
r <- 10 # home range steps are 10x the size of agent steps
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 20 # k = 20, highly directional
hre <- 0.7

# sim3_ns <- simulateAgents(N = 30,
#                           Days = 50,
#                           DayLength = 50,
#                           Soc_Percep_Rng = 1000,
#                           Scl = 1000,
#                           seed = 9252023,
#                           EtaCRW = 0.7,
#                           StpSize_ind = baseAgentStep,
#                           StpStd_ind = 5,
#                           Kappa_ind = 4,
#                           quiet = T,
#                           sim_3 = T,
#                           socialWeight = 0,
#                           HREtaCRW = 0.7,
#                           HRStpSize = HRStpSize,
#                           HRStpStd = HRStpStd,
#                           HRKappa_ind = hrk)
# save(sim3_ns, file = "data/simulations/sim3_ns.Rda")
load("data/simulations/sim3_ns.Rda")
# 
# ggplot() + 
#   geom_point(data = sim3_ns$XY, aes(x = X, y = Y, col = day))+
#   geom_point(data = sim3_ns$HRCent, aes(x = X, y = Y, col = day), 
#              pch = 19, size = 5)+
#   facet_wrap(~indiv, scales = "free")+theme_minimal()+
#   theme(legend.position = "none", axis.text = element_text(size = 18))+
#   scale_color_viridis()+
#   ggtitle("Scenario 3, non-sociable")

indivs <- sample(unique(sim3_ns$XY$indiv), 10)
p_s3_ns <- sim3_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim3_ns$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 3, non-sociable")
ggsave(p_s3_ns, file = "fig/trajectories/p_s3_ns.png", width = 7, height = 6)

# sim3_socLevels <- map(socLevels, ~{
#   sim3 <- simulateAgents(N = 30,
#                            Days = 50,
#                            DayLength = 50,
#                            Soc_Percep_Rng = 1000,
#                            Scl = 1000,
#                            seed = 9252023,
#                            EtaCRW = 0.7,
#                            StpSize_ind = baseAgentStep,
#                            StpStd_ind = 5,
#                            Kappa_ind = 4,
#                            quiet = T,
#                            sim_3 = T,
#                            socialWeight = .x,
#                            HREtaCRW = 0.7,
#                            HRStpSize = HRStpSize,
#                            HRStpStd = HRStpStd,
#                            HRKappa_ind = hrk)
#   return(sim)
# })
# save(sim3_socLevels, file = "data/simulations/sim3_socLevels.Rda")

# sim3_s <- simulateAgents(N = 30,
#                          Days = 50,
#                          DayLength = 50,
#                          Soc_Percep_Rng = 1000,
#                          Scl = 1000,
#                          seed = 9252023,
#                          EtaCRW = 0.7,
#                          StpSize_ind = baseAgentStep,
#                          StpStd_ind = 5,
#                          Kappa_ind = 4,
#                          quiet = T,
#                          sim_3 = T,
#                          socialWeight = 0.75,
#                          HREtaCRW = 0.7,
#                          HRStpSize = HRStpSize,
#                          HRStpStd = HRStpStd,
#                          HRKappa_ind = hrk)
# save(sim3_s, file = "data/simulations/sim3_s.Rda")
load("data/simulations/sim3_s.Rda")

# ggplot() + 
#   geom_point(data = sim3_s$XY, aes(x = X, y = Y, col = day))+
#   #geom_point(data = sim3_s$HRCent, aes(x = X, y = Y, col = day), pch = 19, size = 5)+
#   facet_wrap(~indiv, scales = "free")+theme_minimal()+
#   theme(legend.position = "none", axis.text = element_text(size = 18))+
#   scale_color_viridis()+
#   ggtitle("Scenario 3, sociable")

indivs <- sample(unique(sim3_s$XY$indiv), 10)
p_s3_s <- sim3_s$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim3_s$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 3, sociable")
ggsave(p_s3_s, file = "fig/trajectories/p_s3_s.png", width = 7, height = 6)

# Put all 6 plots together, removing their titles
a <- p_s1_ns + theme(title = element_blank(),
                     axis.text = element_text(size = 18))+ylim(c(-475, 400))+xlim(c(-500, 400))
b <- p_s1_s + theme(title = element_blank(),
                    axis.text.y = element_blank(),
                    axis.text.x = element_text(size = 18))+ylim(c(-475, 400))+xlim(c(-500, 400))

c <- p_s2_ns + theme(title = element_blank(),
                     axis.text = element_text(size = 18))+ ylim(c(-1200, 1100))+xlim(c(-1000, 900))
d <- p_s2_s + theme(title = element_blank(),
                    axis.text.y = element_blank(),
                    axis.text.x = element_text(size = 18))+ ylim(c(-1200, 1100))+xlim(c(-1000, 900))

e <- p_s3_ns + theme(title = element_blank(),
                     axis.text = element_text(size = 18))+xlim(c(-500, 3100))+ylim(c(-3100, 3400))
f <- p_s3_s + theme(title = element_blank(),
                    axis.text.y = element_blank(),
                    axis.text.x = element_text(size = 18))+xlim(c(-500, 3100))+ylim(c(-3100, 3400))

trajectories_patchwork <- ggpubr::ggarrange(plotlist = list(a, b, c, d, e, f), ncol = 2, nrow = 3)
trajectories_patchwork
ggsave(trajectories_patchwork, filename = "fig/trajectories/trajectories_patchwork.png", width = 11, height = 16)

# This one would need to be re-done, removing different axis labels, or not removing any axis labels at all.
# trajectories_patchwork_horizontal <- ((a+c+e)/(b+d+f))+
#   theme(text = element_text('mono', size = 15))
# trajectories_patchwork_horizontal
# ggsave(trajectories_patchwork_horizontal, filename = "fig/trajectories/trajectories_patchwork_horizontal.png", width = 16, height = 11)

# Daily displacement distances for each simulation ------------------------
# Trajectory-long displacements -------------------------------------------

# ATTRACTOR TESTING --------

Scl <- 1000

staticAttractors <- data.frame()
for(i in 1:4){
  for(j in 1:4){
    # runif(n=1, min=-Scl/2, max=Scl/2 )
    x <- i * Scl/4 - 2 * Scl/4
    y <- j * Scl/4 - 2 * Scl/4
    staticAttractors <- rbind(staticAttractors, c(x, y))
  }
}
colnames(staticAttractors) <- c("x", "y")

## SIM 1 -------------------------------------------------------------------
r <- 0.01 # home range centers effectively not moving
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 0.01
hre <- 0.7

sim1_ns <- simulateAgents(N = 5,
                       Days = 10,
                       DayLength = 50,
                       Soc_Percep_Rng = 1000,
                       Scl = Scl,
                       seed = 9252023,
                       EtaCRW = 0.7,
                       StpSize_ind = 7,
                       StpStd_ind = 5,
                       Kappa_ind = 4,
                       quiet = T,
                       sim_3 = T,
                       socialWeight = 0,
                       HREtaCRW = 0.7,
                       HRStpSize = HRStpSize,
                       HRStpStd = HRStpStd,
                       HRKappa_ind = hrk,
                       spatialAttractors = staticAttractors,
                       roostThreshhold = 0.7)

# hr <- sim1_ns$HRCent %>% as.data.frame() %>% mutate(indiv = 1:nrow(.)) %>% rename("X" = X, "Y" = Y)

ggplot() +
  geom_point(data = sim1_ns$XY %>% filter(indiv == 1, day %in% 1), aes(x = X, y = Y, col = StepInDay))+
  geom_point(data = sim1_ns$HRCent %>% filter(indiv == 1, day %in% 1:2), aes(x = X, y = Y), pch = 19, size = 5)+
  # geom_point(data = staticAttractors, aes(x = x, y = y)) +
  facet_wrap(~indiv, scales = "free")+theme_minimal()+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_viridis()+
  ggtitle("Scenario 1, non-sociable")

indivs <- sample(unique(sim1_ns$XY$indiv), 5)
p_s1_ns <- sim1_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot() +
  geom_path(data = sim1_ns$XY %>% filter(!indiv %in% indivs),
            aes(x=  X, y = Y, group = indiv),
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9)+
  geom_point(data = staticAttractors, aes(x = x, y = y)) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 1, non-sociable")

## SIM 3 -------------------------------------------------------------------
r <- 10 # home range steps are 10x the size of agent steps
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 20 # k = 20, highly directional
hre <- 0.7

sim3_ns <- simulateAgents(N = 5,
                          Days = 20,
                          DayLength = 50,
                          Soc_Percep_Rng = 1000,
                          Scl = 1000,
                          seed = 9252023,
                          EtaCRW = 0.7,
                          StpSize_ind = baseAgentStep,
                          StpStd_ind = 5,
                          Kappa_ind = 4,
                          quiet = T,
                          sim_3 = T,
                          socialWeight = 0,
                          HREtaCRW = 0.7,
                          HRStpSize = HRStpSize,
                          HRStpStd = HRStpStd,
                          HRKappa_ind = hrk,
                          spatialAttractors = staticAttractors,
                          roostThreshhold = 0.7)

sim3_ns$XY$phase <- ifelse(sim3_ns$XY$StepInDay > 35, "roost", "flying")

ggplot() +
  geom_point(data = staticAttractors, aes(x = x, y = y)) +
  geom_point(data = sim3_ns$HRCent %>% filter(day %in% 1:3), aes(x = X, y = Y),
             pch = 19, size = 5)+
  geom_point(data = sim3_ns$XY %>% filter(day %in% 1:3) , aes(x = X, y = Y, col = phase))+
  # facet_wrap(~indiv, scales = "free")+theme_minimal()+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  # scale_color_viridis()+
  ggtitle("Scenario 3, non-sociable")

indivs <- sample(unique(sim3_ns$XY$indiv), 5)
p_s3_ns <- sim3_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim3_ns$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  geom_point(data = staticAttractors, aes(x = x, y = y)) + 
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 3, non-sociable")
p_s3_ns

# TORUS TESTING ------------

## SIM 3 ---------
r <- 10 # home range steps are 10x the size of agent steps
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 20 # k = 20, highly directional
hre <- 0.7

sim3_ns <- simulateAgents(N = 5,
                          Days = 20,
                          DayLength = 50,
                          Soc_Percep_Rng = 1000,
                          Scl = 1000,
                          seed = 9252023,
                          EtaCRW = 0.7,
                          StpSize_ind = baseAgentStep,
                          StpStd_ind = 5,
                          Kappa_ind = 4,
                          quiet = T,
                          sim_3 = T,
                          socialWeight = 0,
                          HREtaCRW = 0.7,
                          HRStpSize = HRStpSize,
                          HRStpStd = HRStpStd,
                          HRKappa_ind = hrk,
                          spherical = T)



leaded <- sim3_ns$XY %>% group_by(indiv) %>% mutate(X = lead(X, default = 0), Y = lead(Y, default = 0))
groups <- list()
groupNum <- 1
for(i in 1:max(sim3_ns$XY$indiv)){
  xy_data <- sim3_ns$XY %>% filter(indiv == i)
  xy_data <- xy_data[c("X", "Y")]
  leaded_xy_data <- leaded %>% filter(indiv == i)
  leaded_xy_data <- leaded_xy_data[c("X", "Y")]
  groups[[i]] <- head(diag(dist(xy_data, leaded_xy_data)), -1)
  index <- 2
  groupNum <- 1
  groups[[i]][1] <- groupNum
  for(dist in groups[[i]]){
    if(dist > baseAgentStep * 20){
      groupNum <- groupNum + 1
    }
    groups[[i]][index] <- groupNum
    index <- index + 1
  }
  groupNum <- groupNum + 1
}

sim3_ns$XY <- sim3_ns$XY %>% group_by(indiv) %>% mutate(group = groups[[cur_group_id()]]) %>% ungroup

ggplot() +
  geom_point(data = sim3_ns$HRCent %>% filter(day %in% 1:20), aes(x = X, y = Y),
             pch = 19, size = 5)+
  geom_point(data = sim3_ns$XY %>% filter(day %in% 1:3) , aes(x = X, y = Y))+
  facet_wrap(~indiv, scales = "free")+theme_minimal()+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_viridis()+
  ggtitle("Scenario 3, non-sociable")

indivs <- sample(unique(sim3_ns$XY$indiv), 5)
p_s3_ns <- sim3_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot(aes(group = interaction(indiv,group)))+
  geom_path(data = sim3_ns$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = interaction(indiv, group)), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 3, non-sociable")
p_s3_ns

# CARCASS TESTING ----------

## SIM 1 --------

r <- 0.01 # home range centers effectively not moving
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 0.01
hre <- 0.7

sim1_ns <- simulateAgents(N = 5,
                          Days = 10,
                          DayLength = 50,
                          Soc_Percep_Rng = 1000,
                          Scl = 1000,
                          seed = 9252023,
                          EtaCRW = 0.7,
                          StpSize_ind = 7,
                          StpStd_ind = 5,
                          Kappa_ind = 4,
                          quiet = T,
                          sim_3 = T,
                          socialWeight = 0,
                          HREtaCRW = 0.7,
                          HRStpSize = HRStpSize,
                          HRStpStd = HRStpStd,
                          HRKappa_ind = hrk,
                          carcasses=T,
                          carcassPercepRange = 200,
                          carcassWeight = 1,
                          carcassesPerDay = 5,
                          carcassChance = 0.5)

# hr <- sim1_ns$HRCent %>% as.data.frame() %>% mutate(indiv = 1:nrow(.)) %>% rename("X" = X, "Y" = Y)

ggplot() +
  geom_point(data = sim1_ns$XY %>% filter(indiv == 1, day %in% 1), aes(x = X, y = Y, col = StepInDay))+
  geom_point(data = sim1_ns$HRCent %>% filter(indiv == 1, day %in% 1:2), aes(x = X, y = Y), pch = 19, size = 5)+
  facet_wrap(~indiv, scales = "free")+theme_minimal()+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_viridis()+
  ggtitle("Scenario 1, non-sociable")

indivs <- sample(unique(sim1_ns$XY$indiv), 5)
p_s1_ns <- sim1_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot() +
  geom_path(data = sim1_ns$XY %>% filter(!indiv %in% indivs),
            aes(x=  X, y = Y, group = indiv),
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9)+
  geom_point(aes(x=x, y=y, size=day+(timeToStart/50)), data=sim1_ns$carcasses)+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 1, non-sociable, with carcasses")

## SIM 3 --------

r <- 10 # home range steps are 10x the size of agent steps
baseAgentStep <- 7
HRStpSize <- baseAgentStep*r
HRStpStd <- HRStpSize*0.75 # leaving this here for now--could go back and change later if we want. 
hrk <- 2 # k = 20, highly directional
hre <- 0.7

sim3_ns <- simulateAgents(N = 5,
                          Days = 20,
                          DayLength = 50,
                          Soc_Percep_Rng = 1000,
                          Scl = 1000,
                          seed = 9252023,
                          EtaCRW = 0.7,
                          StpSize_ind = baseAgentStep,
                          StpStd_ind = 5,
                          Kappa_ind = 4,
                          quiet = T,
                          sim_3 = T,
                          socialWeight = 0,
                          HREtaCRW = hre,
                          HRStpSize = HRStpSize,
                          HRStpStd = HRStpStd,
                          HRKappa_ind = hrk,
                          carcasses=T,
                          carcassPercepRange = 200,
                          carcassWeight = 0.5,
                          carcassesPerDay = 5,
                          carcassChance = 0.5)

ggplot() +
  geom_point(data = sim3_ns$HRCent %>% filter(day %in% 1:20), aes(x = X, y = Y),
             pch = 19, size = 5)+
  geom_point(data = sim3_ns$XY %>% filter(day %in% 1:3) , aes(x = X, y = Y))+
  facet_wrap(~indiv, scales = "free")+theme_minimal()+
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  scale_color_viridis()+
  ggtitle("Scenario 3, non-sociable")

indivs <- sample(unique(sim3_ns$XY$indiv), 5)
p_s3_ns <- sim3_ns$XY %>%
  filter(indiv %in% indivs) %>%
  ggplot()+
  geom_path(data = sim3_ns$XY %>% filter(!indiv %in% indivs), 
            aes(x=  X, y = Y, group = indiv), 
            col = "black", linewidth = 0.1, alpha = 0.2)+
  geom_path(aes(x = X, y = Y, col = indiv),
            linewidth = 1, alpha = 0.9) +
  theme(legend.position = "none", axis.text = element_text(size = 18))+
  geom_point(aes(x=x, y=y), data=sim3_ns$carcasses)+
  scale_color_manual(values = as.character(tencolors))+
  theme_minimal()+
  theme(legend.position = "none")+
  ggtitle("Scenario 3, non-sociable, with carcasses")
p_s3_ns
