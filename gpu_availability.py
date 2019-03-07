#!/usr/bin/env python
#
# Author: Christoph Schild <cvs46@nau.edu>
# This program displays information about GPU availability on HPC clusters
# Information about the GPUs installed is pulled from /etc/slurm/slurm.conf
# Note: Must be run from account with access to slurm.conf. (Read only) 
#

import os, sys

# Change as appropriate
SLURM_CONFIG="/etc/slurm/slurm.conf"

# Main Method
def run():

	# Declare empty dict for GPU info
	gpus = {}

	# Count of jobs
	pd_job_count = os.popen("squeue -t PD | grep gpu | wc -l").read().strip("\n")

	# Count of GPUs
	total_count = 0

	# Count of used GPUs
	total_used = 0

	# Get Slurm info about GPU nodes
	gpu_nodes = filter(None, os.popen("cat " + SLURM_CONFIG + " | grep Gres=").read().split("\n"))
	
	# Figure out which nodes are used
	used_nodes = filter(None, os.popen("squeue -t R | grep gpu | rev | cut -d ' ' -f1 | rev").read().split("\n"))
	
	# Loop through nodes in use
	for node in used_nodes:
		total_used += 1

	# Loop through nodes in config file and grab information
	for node in gpu_nodes:
		gpu_architecture = node.split("Feature=")[1].split(",")[-1]
		gpu_count = int(node.split("Gres=")[1].split(" ")[0].split(":")[-1])
		gpu_node_name = node.split("NodeName=")[1].split(" ")[0]
		temp_total_used = 0

		# add number of GPUs for current architecture to total (temp)
		for gpu_node in used_nodes:
			if gpu_node == gpu_node_name:
				temp_total_used += 1

		# Add new GPUs to total count
		total_count += gpu_count

		# Check if architecture is already present (add to existing count or add new entry into dict as appropriate)
		if gpu_architecture in gpus:
			gpus[gpu_architecture]["total"] += gpu_count
			gpus[gpu_architecture]["used"] += temp_total_used
			gpus[gpu_architecture]["NodeName"].append(gpu_node_name)

		else:
			gpus[gpu_architecture] = {"total" : gpu_count, "used" : temp_total_used, "NodeName" : [gpu_node_name]}


	# Print information for user to see system stats
	print("Available GPUs:" + str(total_count - total_used) + "/" + str(total_count) + "\n")
	for key, value in gpus.items():
		print(str(key) + ": " + str(value["total"] - value["used"]) + "/" + str(value["total"]))
	print("\nPending Jobs: " + pd_job_count)
run()
