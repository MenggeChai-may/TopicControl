# setwd("D:/Eclipse/workspaces/Networks")
# source("TopicControl/src/tests.R")

source("TopicControl/src/functions.R")

library("igraph")

# parameters
beta <- 0.3
betas <- c(0.01, 0.1, 0.5, 0.8, 0.99)
#alpha <- 0.1
alphas <- c(0.01, 0.1, 0.5, 0.8, 0.99)

# set up net folders
data.folder <- "TopicControl/data/"
folders <- c(
		"CKM_Physicians_Innovation/",
		"CS_Aarhus/",
#		"EU_Air_Transport/", # 37 link types, that's too many for now
		"Kapferer_Tailor_Shop/",
		"Krackhardt8-High_Tech/",
		"Lazega_Law_Firm/",
		"London_Transport/",
		"Padgett_Florence_Families/",
		"Vickers_Chan_7thGraders/"
)

# init performance matrix
perfs.raw <- matrix(NA, nrow=length(folders), ncol=length(betas)*length(alphas))
rownames(perfs.raw) <- folders
colnames(perfs.raw) <- apply(expand.grid(paste("a=",alphas,sep=""),paste("b=",betas,sep="")), 1, paste, collapse=";")
perfs.norm <- matrix(NA, nrow=length(folders), ncol=length(betas)*length(alphas))
rownames(perfs.norm) <- rownames(perfs.raw)
colnames(perfs.norm) <- colnames(perfs.raw)

# process each real world network
for(folder in folders)
{	# init file names
	net.folder <- paste(data.folder, folder, sep="")
	net.file <- paste(net.folder, "network.graphml", sep="")
	
	# load graph
	g <- read.graph(file=net.file,format="graphml")
	nodes <- vcount(g)
	topics <- length(unique(E(g)$type))
	
	# build adjacency matrix
	adj <- array(0,c(nodes,nodes,topics))
	for(t in 1:topics)
	{	g2 <- subgraph.edges(graph=g, eids=which(E(g)$type==t), delete.vertices=FALSE)
		adj[,,t] <- as.matrix(get.adjacency(graph=g2, type="both"))
	}
	# normalize matrix
	adj <- adj / apply(X=adj,MARGIN=1, FUN=sum)
	adj[which(is.nan(adj))] <- 0
	
	# init k (normal law)
	k <- rnorm(n=nodes*topics,0.5,0.5)
	k <- k + min(k)
	k <- matrix(k, nrow=nodes, ncol=topics)
	k <- k / apply(X=k, MARGIN=1, FUN=sum)
	
	# solve control pb
	col <- 1
	for(alpha in alphas)
	{	for(beta in betas)
		{	sol <- Control(E=adj,k,alpha,beta)
			print(sol)
			perfs.raw[folder, col] <- sol$solutionNorm
			perfs.norm[folder, col] <- sol$solutionNorm / nodes
			col <- col + 1
		}
	}
}

# record perf tables
perf.file <- paste(data.folder, "performances.raw.txt", sep="")
write.table(x=perfs.raw, file=perf.file, row.names=TRUE, col.names=TRUE)
perf.file <- paste(data.folder, "performances.norm.txt", sep="")
write.table(x=perfs.norm, file=perf.file, row.names=TRUE, col.names=TRUE)
