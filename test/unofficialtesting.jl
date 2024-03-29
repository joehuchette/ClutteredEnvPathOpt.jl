using ClutteredEnvPathOpt
using LinearAlgebra
using Test
using Pipe
using Plots
using JuMP
using Gurobi

# import GLPK
using LightGraphs
import Polyhedra
using PiecewiseLinearOpt

########################################################################################
################################### solve_steps ########################################
# Create obstacles
num_obs = 2;
seed = 25;
obstacles = ClutteredEnvPathOpt.gen_field_random(num_obs, seed = seed)
ClutteredEnvPathOpt.plot_field(obstacles)
points = ClutteredEnvPathOpt.find_points(obstacles)
ClutteredEnvPathOpt.plot_points(points)
display(plot!())

# Set parameters
N = 20  # number of steps
f1 = [0.0, 0.1, 0.0]  # initial footstep pose 1
f2 = [0.0, 0.0, 0.0]  # initial footstep pose 2
goal = [1.0, 1.0, 0.0]  # goal pose
Q_g = 10 * Matrix{Float64}(I, 3, 3)  # weight between final footstep and goal pose
Q_r = Matrix{Float64}(I, 3, 3) # weight between footsteps
q_t = -.05  # weight for trimming unused steps
# TODO: Assure second footstep is within reachability given first

# Optional named arguments
# d1 = 0.2  # radius of reference foot circle
# d2 = 0.2  # radius of moving foot circle
# p1 = [0. 0.07]  # center of reference foot circle
# p2 = [0, -0.27]  # center of moving foot circle
# # delta_x_y_max = 0.1  # max stride norm in space
# # delta_θ_max = pi/4  # max difference in θ
# relax = false  # if true, solve as continuous relaxation

# Compute optimal path
x, y, θ, t, stats = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method="merged")
term_status, obj_val, solve_time, rel_gap, simplex_iters, barrier_iters, node_count, num_vertices, merged_size, full_size, num_free_faces, num_free_face_ineq, method_used = stats

x2, y2, θ2, t2, stats2 = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method="full")
term_status2, obj_val2, solve_time2, rel_gap2, simplex_iters2, barrier_iters2, r_node_count2, num_vertices2, merged_size2, full_size2, num_free_faces2, num_free_face_ineq2, method_used2 = stats2

x3, y3, θ3, t3, stats3 = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method="bigM")
term_status3, obj_val3, solve_time3, rel_gap3, simplex_iters3, barrier_iters3, node_count3, num_vertices3, merged_size3, full_size3, num_free_faces3, num_free_face_ineq3, method_used3 = stats3

seed_range = 1:3
num_obs_range = 1:4
time_diffs = []
for seed in seed_range
    for num_obs in num_obs_range
        println("\nOn test Seed = $seed, Num_Obs = $num_obs")
        obstacles = ClutteredEnvPathOpt.gen_field_random(num_obs, seed = seed)
        _,_,_,_,stats = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method = "merged")
        _,_,_,_,stats2 = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method="full")
        _,_,_,_,stats3 = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method="bigM")              
        term_status, solve_time, rel_gap, simplex_iters, node_count, num_vertices, merged_size, full_size, num_free_faces, num_free_face_ineq, method_used = stats
        term_status2, solve_time2, rel_gap2, simplex_iters2, node_count2, num_vertices2, merged_size2, full_size2, num_free_faces2, num_free_face_ineq2, method_used2 = stats2
        term_status3, solve_time3, rel_gap3, simplex_iters3, node_count3, num_vertices3, merged_size3, full_size3, num_free_faces3, num_free_face_ineq3, method_used3 = stats3
        # Merged biclique times vs bigM
        t_diff = solve_time3 - solve_time
        push!(time_diffs, t_diff)
    end
end

# Trim excess steps
num_to_trim = length(filter(tj -> tj > 0.5, t[3:end]))
if num_to_trim % 2 == 0
    x = vcat(x[1:2], x[num_to_trim + 3 : end]);
    y = vcat(y[1:2], y[num_to_trim + 3 : end]);
    θ = vcat(θ[1:2], θ[num_to_trim + 3 : end]);
else
    x = vcat(x[1], x[num_to_trim + 3 : end]);
    y = vcat(y[1], y[num_to_trim + 3 : end]);
    θ = vcat(θ[1], θ[num_to_trim + 3 : end]);
end

num_to_trim2 = length(filter(tj -> tj > 0.5, t2[3:end]))
if num_to_trim2 % 2 == 0
    x2 = vcat(x2[1:2], x2[num_to_trim2 + 3 : end]);
    y2 = vcat(y2[1:2], y2[num_to_trim2 + 3 : end]);
    θ2 = vcat(θ2[1:2], θ2[num_to_trim2 + 3 : end]);
else
    x2 = vcat(x2[1], x2[num_to_trim2 + 3 : end]);
    y2 = vcat(y2[1], y2[num_to_trim2 + 3 : end]);
    θ2 = vcat(θ2[1], θ2[num_to_trim2 + 3 : end]);
end

num_to_trim3 = length(filter(tj -> tj > 0.5, t3[3:end]))
if num_to_trim3 % 2 == 0
    x3 = vcat(x3[1:2], x3[num_to_trim3 + 3 : end]);
    y3 = vcat(y3[1:2], y3[num_to_trim3 + 3 : end]);
    θ3 = vcat(θ3[1:2], θ3[num_to_trim3 + 3 : end]);
else
    x3 = vcat(x3[1], x3[num_to_trim3 + 3 : end]);
    y3 = vcat(y3[1], y3[num_to_trim3 + 3 : end]);
    θ3 = vcat(θ3[1], θ3[num_to_trim3 + 3 : end]);
end

# Plot footstep plan
plot_steps(obstacles, x, y, θ)
plot!(title="Footsteps")
png("Optimal Path Seed $seed Num Obs $num_obs Merged Faces true Method merged")
# savefig("Poster Optimal Path Seed $seed Num Obs $num_obs Merged Faces true Method merged.pdf")
plot_steps(obstacles, x2, y2, θ2)
plot!(title="Footsteps")
png("Optimal Path Seed $seed Num Obs $num_obs Merged Faces true Method full")
plot_steps(obstacles, x3, y3, θ3)
plot!(title="Footsteps")
png("Optimal Path Seed $seed Num Obs $num_obs Merged Faces true Method bigM")


# Plot intersections of circles
plot_circles(x, y, θ)
plot_circles(x2, y2, θ2)
plot_circles(x3, y3, θ3)

######################################################################################
################################ Inspect Instances ###################################

num_obs = 2;
seed = 17;
merge_faces = true;
partition = "CDT";
obstacles, points, g, obstacle_faces, free_faces = ClutteredEnvPathOpt.plot_new(num_obs, "Obstacles Seed $seed Num Obs $num_obs", seed=seed, partition=partition, merge_faces=merge_faces)
skeleton = LabeledGraph(g)
all_faces = Set{Vector{Int64}}(union(obstacle_faces, free_faces))

# Plot obstacles
ClutteredEnvPathOpt.plot_field(obstacles, title="Obstacles")
# points = ClutteredEnvPathOpt.find_points(obstacles)
# ClutteredEnvPathOpt.plot_points(points, vertices=skeleton.labels)
# ClutteredEnvPathOpt.plot_lines(obstacles)
# ClutteredEnvPathOpt.plot_borders()
# ClutteredEnvPathOpt.plot_intersections(obstacles);
# plot!(title="",axis=([], false))
png("$partition Obstacles Seed $seed Num Obs $num_obs")
# png("$partition Obstacles Seed $seed Num Obs $num_obs No Axis")
ClutteredEnvPathOpt.plot_points(points, vertices=skeleton.labels)
png("$partition Obstacles with Points Seed $seed Num Obs $num_obs")
# png("$partition Obstacles with Points Seed $seed Num Obs $num_obs No Axis")
display(plot!())
savefig("Poster Obstacles Seed $seed Num Obs $num_obs.pdf")

# Plot faces
ClutteredEnvPathOpt.plot_faces(free_faces, points, plot_name = "Free Faces")
ClutteredEnvPathOpt.plot_faces(free_faces, points, plot_name = "Free Space Partition")
# plot!(title="",axis=([], false))
png("$partition Free Faces Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition Free Faces Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")
savefig("Poster $partition Free Faces Seed $seed Num Obs $num_obs Merged Faces $merge_faces.pdf")

ClutteredEnvPathOpt.plot_faces(obstacle_faces, points, plot_name = "Obstacle Faces", col = "dodgerblue")
# plot!(title="",axis=([], false))
png("Obstacle Faces Seed $seed Num Obs $num_obs")

ClutteredEnvPathOpt.plot_faces(all_faces, points, plot_name = "All Faces", col = "red")
ClutteredEnvPathOpt.plot_faces(all_faces, points, plot_name = "All Faces", new_plot = false)
# plot!(title="",axis=([], false))
png("$partition All Faces Seed $seed Num Obs $num_obs")

# Plot faces individually
ClutteredEnvPathOpt.plot_faces(obstacle_faces, points, col = "dodgerblue", individually = true)
ClutteredEnvPathOpt.plot_faces(free_faces, points, individually = true)

# Plot edges
ClutteredEnvPathOpt.plot_edges(skeleton, points, plot_name = "Skeleton", col="black", vertices=skeleton.labels)
# plot!(title="",axis=([], false))
png("$partition Skeleton Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition Skeleton Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")

feg = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(free_faces))
ClutteredEnvPathOpt.plot_edges(feg, points, plot_name = "Finite Element Graph of S",col="black", vertices=feg_S.labels)
ClutteredEnvPathOpt.plot_edges(feg, points, plot_name = "G_S",col="black", vertices=feg_S.labels, with_labels=false)
# plot!(title="",axis=([], false))
png("$partition FEG of S Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition FEG of S Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")
savefig("Poster $partition FEG of S Seed $seed Num Obs $num_obs Merged Faces $merge_faces.pdf")

# Plot conflict graph
conflict = LightGraphs.complement(feg.graph)
conflict_lg = LabeledGraph(conflict, feg.labels)
ClutteredEnvPathOpt.plot_edges(conflict_lg, points, plot_name = "Conflict Graph", col="black", with_labels=false)
png("$partition Conflict Graph Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
savefig("Poster $partition Conflict Graph Seed $seed Num Obs $num_obs Merged Faces $merge_faces.pdf")

# feg_obs = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(obstacle_faces))
# ClutteredEnvPathOpt.plot_edges(feg_obs, points, plot_name = "Finite Element Graph Obstacle Faces")
# # plot!(title="",axis=([], false))
# png("$partition FEG Obstacles Seed $seed Num Obs $num_obs")

# feg_all = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(all_faces))
# ClutteredEnvPathOpt.plot_edges(feg_all, points, plot_name = "Finite Element Graph")
# # plot!(title="",axis=([], false))
# png("$partition FEG All Seed $seed Num Obs $num_obs")


# cover3 = ClutteredEnvPathOpt._find_biclique_cover_visual(skeleton, free_faces, points)
# tree = ClutteredEnvPathOpt.find_biclique_cover_as_tree(skeleton, free_faces)

# Free Faces Cover
cover = ClutteredEnvPathOpt.find_biclique_cover(skeleton, free_faces)
feg = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(free_faces))
(valid_cover, size_diff, missing_edges, missing_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, cover)

merged_cover = ClutteredEnvPathOpt.biclique_merger(cover, feg)
(valid_cover, size_diff, missing_edges, missing_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, merged_cover)

ClutteredEnvPathOpt.plot_edges(missing_edges_lg, points, plot_name = "Missing Edges",vertices=missing_edges_lg.labels)
png("$partitition Missing Edges Seed $seed Num Obs $num_obs Merged Faces $merge_faces")

# Plot biclique
ClutteredEnvPathOpt.plot_biclique_cover(feg, points, merged_cover; with_all=true, name="Poster Biclique")



# file_name = "Biclique Cover Debug Output Seed $seed Num Obs $num_obs Free Unedited.txt"
# f = open(file_name, "w")
# write(f, "Plot 1\n")
# flush(f)
# close(f)
# cover2 = ClutteredEnvPathOpt.find_biclique_cover_debug(skeleton, free_faces, points, obstacles, file_name)

# To produce individual FEGs/Skeletons in the recursion process
(C,A,B), skeleton_ac, faces_ac, skeleton_bc, faces_bc = ClutteredEnvPathOpt.find_biclique_cover_one_iter(skeleton, free_faces)
feg_S_ac = ClutteredEnvPathOpt._find_finite_element_graph(skeleton_ac, ClutteredEnvPathOpt._find_face_pairs(faces_ac))
feg_S_bc = ClutteredEnvPathOpt._find_finite_element_graph(skeleton_bc, ClutteredEnvPathOpt._find_face_pairs(faces_bc))

ClutteredEnvPathOpt.plot_edges(skeleton_ac, points, plot_name = "Skeleton S_ac",vertices=skeleton_ac.labels,col="black")
# plot!(title="",axis=([], false))
png("$partition Skeleton of S_ac Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition Skeleton of S_ac Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")
ClutteredEnvPathOpt.plot_edges(feg_S_ac, points, plot_name = "Finite Element Graph of S_ac",vertices=feg_S_ac.labels,col="black")
# plot!(title="",axis=([], false))
png("$partition FEG of S_ac Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition FEG of S_ac Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")

ClutteredEnvPathOpt.plot_edges(skeleton_bc, points, plot_name = "Skeleton S_bc",vertices=skeleton_bc.labels,col="black")
# plot!(title="",axis=([], false))
png("$partition Skeleton of S_bc Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition Skeleton of S_bc Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")
ClutteredEnvPathOpt.plot_edges(feg_S_bc, points, plot_name = "Finite Element Graph of S_bc",vertices=feg_S_bc.labels,col="black")
# plot!(title="",axis=([], false))
png("$partition FEG of S_bc Seed $seed Num Obs $num_obs Merged Faces $merge_faces")
# png("$partition FEG of S_bc Seed $seed Num Obs $num_obs Merged Faces $merge_faces No Axis")


#######################################################################################
########################### Biclique Cover Validity Tests #############################

# Biclique cover validity tester function
function biclique_cover_validity_tests(seed_range, num_obs_range; faces::String="free", with_plots::Bool=false,partition="CDT",merge_faces::Bool=true)
    # fails = 0
    tuples = []
    for seed = seed_range
        for num_obs = num_obs_range
            println("On test Seed = $seed, Num_Obs = $num_obs")
            obstacles, points, g, obstacle_faces, free_faces = ClutteredEnvPathOpt.plot_new(num_obs,"Obstacles Seed $seed Num Obs $num_obs",seed=seed, partition=partition, merge_faces=merge_faces)
            skeleton = LabeledGraph(g)
            all_faces = Set{Vector{Int64}}(union(obstacle_faces, free_faces))
            if faces == "all"
                cover = ClutteredEnvPathOpt.find_biclique_cover(skeleton, all_faces);
                feg = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(all_faces));
                merged_cover = ClutteredEnvPathOpt.biclique_merger(cover, feg)
                # (valid_cov, size_diff, miss_edges, miss_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, cover);
                (valid_cov, size_diff, miss_edges, miss_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, merged_cover);
                # println("Difference: $(length(cover)-length(merged_cover)) | Merged: $(length(merged_cover)) | Original: $(length(cover))")
            else
                cover = ClutteredEnvPathOpt.find_biclique_cover(skeleton, free_faces);
                feg = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(free_faces));
                merged_cover = ClutteredEnvPathOpt.biclique_merger(cover, feg)
                # (valid_cov, size_diff, miss_edges, miss_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, cover);
                (valid_cov, size_diff, miss_edges, miss_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, merged_cover);
                # println("Difference: $(length(cover)-length(merged_cover)) | Merged: $(length(merged_cover)) | Original: $(length(cover))")
            end
            if size_diff != 0
                # fails += 1
                push!(tuples, (seed, num_obs))
                println("Test Failed")

                if with_plots
                    ClutteredEnvPathOpt.plot_field(obstacles, title="Obstacles")
                    # points = ClutteredEnvPathOpt.find_points(obstacles)
                    ClutteredEnvPathOpt.plot_points(points)
                    # ClutteredEnvPathOpt.plot_lines(obstacles)
                    # ClutteredEnvPathOpt.plot_borders()
                    # ClutteredEnvPathOpt.plot_intersections(obstacles);
                    display(plot!())
                    png("$partition Obstacles Seed $seed Num Obs $num_obs")

                    ClutteredEnvPathOpt.plot_faces(free_faces, points, plot_name = "Free Faces")
                    png("$partition Free Faces Seed $seed Num Obs $num_obs")

                    ClutteredEnvPathOpt.plot_edges(skeleton, points, plot_name = "Skeleton")
                    png("$partition Skeleton Seed $seed Num Obs $num_obs")

                    if size_diff > 0
                        ClutteredEnvPathOpt.plot_edges(miss_edges_lg, points, plot_name = "Missing Edges")
                        if faces == "all"
                            png("$partition Missing Edges All Faces Used Seed $seed Num Obs $num_obs")
                        else
                            png("$partition Missing Edges Free Faces Used Seed $seed Num Obs $num_obs")
                        end
                    end
                end
            end
        end
    end
    return tuples
end

seed_range = 1:100
num_obs_range = 1:4
partition = "CDT"
merge_faces = true
# fail_tuples = biclique_cover_validity_tests(seed_range, num_obs_range, faces = "all", partition=partition)
fail_tuples = biclique_cover_validity_tests(seed_range, num_obs_range, faces = "free", with_plots=true, partition=partition)


######################################################################################
############################ Biclique Cover Merging Stats ############################

# Biclique cover merger function for stats
function biclique_cover_merger_stats(seed_range, num_obs_range; file_name="Biclique Cover Merging Stats.txt", partition="CDT", merge_faces=true)
    # file_name = "Biclique Cover Merging Stats.txt" #Seed Range = $seed_range, Num Obs Range = $num_obs_range.txt"
    f = open(file_name, "w")
    write(f, "Seed Range = $seed_range, Num Obs Range = $num_obs_range\n")
    flush(f)
    close(f)
    
    f = open(file_name, "a")
    write(f, "Seed\tNum_obs\tNum_free_faces\tFull_cover\tMerged_cover\tDecrease\tPercent_decrease\n")
    tuples = []
    num_free_faces_vec = []
    percent_vec = []
    cover_vec = []
    merged_cover_vec = []
    for seed = seed_range
        for num_obs = num_obs_range
            # f = open(file_name, "a")
            # write(f, "\nTest Seed = $seed, Num_Obs = $num_obs\n")
            write(f, "$seed\t$num_obs")
            # flush(f)
            # close(f)

            # println("On test Seed = $seed, Num_Obs = $num_obs")
            obstacles, points, g, obstacle_faces, free_faces = ClutteredEnvPathOpt.plot_new(num_obs,"Obstacles Seed $seed Num Obs $num_obs",seed=seed,partition=partition,merge_faces=merge_faces);
            skeleton = LabeledGraph(g)
            # all_faces = Set{Vector{Int64}}(union(obstacle_faces, free_faces))
            write(f, "\t$(length(free_faces))")
            push!(num_free_faces_vec, (length(free_faces)))
            
            cover = ClutteredEnvPathOpt.find_biclique_cover(skeleton, free_faces);
            feg = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(free_faces));
            merged_cover = ClutteredEnvPathOpt.biclique_merger(cover, feg)
            (valid_cover, size_diff, miss_edges, miss_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, cover);
            (valid_cover_merged, size_diff, miss_edges, miss_edges_lg) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, merged_cover);
            # println("Difference: $(length(cover)-length(merged_cover)) | Merged: $(length(merged_cover)) | Original: $(length(cover))")

            # if valid_cover && valid_cover_merged
            #     write(f,"Difference: $(length(cover)-length(merged_cover)) | Merged: $(length(merged_cover)) | Original: $(length(cover))")
            #     percent = round( ((length(cover)-length(merged_cover)) / length(cover)) * 100, digits = 2)
            #     write(f," | Percent Decrease: $percent\n")
            #     push!(percent_vec, percent)
            # else
            #     fails += 1
            #     push!(tuples, (seed, num_obs))
            #     if !valid_cover_merged
            #         write(f,"Merged cover invalid.\n")
            #     else
            #         write(f,"Original cover invalid.\n")
            #     end
            # end
            if valid_cover && valid_cover_merged
                percent = round( ((length(cover)-length(merged_cover)) / length(cover)) * 100, digits = 2)
                write(f,"\t$(length(cover))\t$(length(merged_cover))\t$(length(cover)-length(merged_cover))\t$percent\n")
                push!(percent_vec, percent)
                push!(cover_vec, length(cover))
                push!(merged_cover_vec, length(merged_cover))
            elseif valid_cover
                percent = round( ((length(cover)-0) / length(cover)) * 100, digits = 2)
                write(f,"\t$(length(cover))\t0\t$(length(cover)-0)\t$percent\n")
                push!(percent_vec, percent)
                push!(cover_vec, -1)
                push!(merged_cover_vec, -1)

                push!(tuples, (seed, num_obs))
                # if !valid_cover_merged
                #     write(f,"Merged cover invalid.\n")
                # else
                #     write(f,"Original cover invalid.\n")
                # end
            end
        end
    end

    # write(f, "\nTotal Fails: $length(tuples).\nTuples: $tuples")
    flush(f)
    close(f)

    return percent_vec, tuples, cover_vec, merged_cover_vec, num_free_faces_vec
end

file_name = "Biclique Cover Merging Stats Partition $partition.txt"
file_name_dt = "Biclique Cover Merging Stats Partition CDT.txt"
file_name_hp = "Biclique Cover Merging Stats Partition HP.txt"
percent_decreases_dt, tuples_dt, c_sizes_dt, mc_sizes_dt, num_free_faces_dt = biclique_cover_merger_stats(seed_range, num_obs_range, file_name=file_name_dt, partition="CDT")
percent_decreases_hp, tuples_hp, c_sizes_hp, mc_sizes_hp, num_free_faces_hp = biclique_cover_merger_stats(seed_range, num_obs_range, file_name=file_name_hp, partition="HP")
size_diff_cover = c_sizes_hp - c_sizes_dt
size_diff_merged_cover = mc_sizes_hp - mc_sizes_dt
size_diff_free_faces = num_free_faces_hp - num_free_faces_dt

maximum(size_diff_free_faces) # 68
minimum(size_diff_free_faces) # 0
Statistics.mean(size_diff_free_faces) # 17.79
count(t-> t > 0, size_diff_free_faces) # 373
count(t-> t < 0, size_diff_free_faces) # 0
count(t-> t == 0, size_diff_free_faces) # 27

maximum(size_diff_merged_cover) # 16
minimum(size_diff_merged_cover) # -1
Statistics.mean(size_diff_merged_cover) # 4.975
count(t-> t > 0, size_diff_merged_cover) # 353
count(t-> t < 0, size_diff_merged_cover) # 9
count(t-> t == 0, size_diff_merged_cover) # 38


# TODO: Add number of points, ratio (percentage) of num_free_faces for HP vs DT
# file_name = "Biclique Cover Merging and Free Faces Comparison.txt"
# f = open(file_name, "w")
# write(f, "Title\n")
# write(f, "Header1\tHeader2\n")
for i = 1:length(percent_decreases_dt)
    # percent decreases etc
    write()
end
# flush(f)
# close(f)

# TODO: WRITE STATS TO FILE
# function size_stats()

# end


######################################################################################
################################# Solve Time Stats ###################################

# method <- "merged" for the compact biclique cover, "full" for the original biclique cover, "bigM" for big-M constraints
function solve_time_stats(seed_range, num_obs_range; file_name="Solve Time Stats.txt", method="merged", partition="CDT", merge_faces=true, relax=false)
    # file_name = "Solve Time Stats.txt" #Seed Range = $seed_range, Num Obs Range = $num_obs_range.txt"
    # f = open(file_name, "a")
    # write(f, "Method = $method, Seed Range = $seed_range, Num Obs Range = $num_obs_range\n")
    # flush(f)
    # close(f)

    # Set parameters
    N = 20  # number of steps
    f1 = [0.0, 0.1, 0.0]  # initial footstep pose 1
    f2 = [0.0, 0.0, 0.0]  # initial footstep pose 2
    goal = [1, 1, 0]  # goal pose
    Q_g = 10*Matrix{Float64}(I, 3, 3)  # weight between final footstep and goal pose
    Q_r = Matrix{Float64}(I, 3, 3)  # weight between footsteps
    q_t = -.05  # weight for trimming unused steps
    # Optional named arguments
    # d1 = 0.2 <- radius of reference foot circle
    # d2 = 0.2 <- radius of moving foot circle
    # p1 = [0, 0.07] <- center of reference foot circle
    # p2 = [0, -0.27] <- center of moving foot circle
    # delta_x_y_max = 0.10  # max stride norm in space (no longer used)
    # delta_θ_max = pi/4  # max difference in θ (no longer used)
    # relax = false <- if true, solve as continuous relaxation
    
    f = open(file_name, "a")   # file is created outside of function
    write(f, "Seed\tNum_obs\tTerm_status\tObj_val\tSolve_time\tRel_gap\tSimplex_iterations\tBarrier_iterations\tNodes_explored")
    write(f, "\tNum_vertices\tBC_merged_size\tBC_full_size\tNum_free_faces\tNum_free_face_inequalities\n")
    times = zeros(length(seed_range) * length(num_obs_range))
    i = 1
    for seed = seed_range
        for num_obs = num_obs_range
            # f = open(file_name, "a")
            # write(f, "Seed = $seed, Num_Obs = $num_obs\n")
            # flush(f)
            # close(f)
            # println("On test Seed = $seed, Num_Obs = $num_obs")

            # Create obstacles
            obstacles = ClutteredEnvPathOpt.gen_field_random(num_obs, seed = seed)

            x, y, θ, t, stats = solve_steps(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method=method, partition=partition, merge_faces=merge_faces, relax=relax)
            term_status, obj_val, solve_time, rel_gap, simplex_iters, barrier_iters, node_count, num_vertices, merged_size, full_size, num_free_faces, num_free_face_ineq, method_used = stats

            if method_used == method
                times[i] = solve_time   # time
            else
                times[i] = -1
            end
            write(f, "$seed\t$num_obs\t$(term_status)\t$obj_val\t$(times[i])\t$rel_gap\t$simplex_iters\t$barrier_iters\t$node_count")
            write(f, "\t$num_vertices\t$merged_size\t$full_size\t$num_free_faces\t$num_free_face_ineq\n")
            flush(f)

            i += 1

            # # Trim excess steps
            # num_to_trim = length(filter(tj -> tj > 0.5, t[3:end]))
            # if num_to_trim % 2 == 0
            #     x = vcat(x[1:2], x[num_to_trim + 3 : end]);
            #     y = vcat(y[1:2], y[num_to_trim + 3 : end]);
            #     θ = vcat(θ[1:2], θ[num_to_trim + 3 : end]);
            # else
            #     x = vcat(x[1], x[num_to_trim + 3 : end]);
            #     y = vcat(y[1], y[num_to_trim + 3 : end]);
            #     θ = vcat(θ[1], θ[num_to_trim + 3 : end]);
            # end
            # plot_steps(obstacles, x, y, θ)
            # plot_circles(x, y, θ, p1=p1, p2=p2)

        end
    end

    # write(f, "\nEND")
    # flush(f)
    close(f)

    return times

end

# Run seeds 1-5 with CDT for MIP only
seed_start = 1
seed_end = 50
seed_range = seed_start:seed_end
num_obs = 3
num_obs_range = num_obs:num_obs
# partitions = ["CDT", "HP"]
partitions = ["CDT"]
# merge_faces = [true, false]
merge_faces = [true]
# merge_faces = [false]
# methods = ["merged", "full", "bigM"]
methods = ["merged"]
# methods = ["full"]
# methods = ["bigM"]
relax = false
for partition in partitions
    if partition == "CDT"
        for merge_face in merge_faces
            for method in methods
                file_name = "./Experiments/Solve Times/Solve Time Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition Merge Face $merge_face.txt"
                # file_name = "./Experiments/Solve Times Parameters Off/Solve Time Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition Merge Face $merge_face.txt"
                # file_name = "./Experiments/Solve Times Relaxed/Relaxed Solve Time Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition Merge Face $merge_face.txt"
                f = open(file_name, "w")   # write or append appropriately
                write(f, "Seed Range = $seed_range, Num Obs Range = $num_obs_range\nMethod = $method\tPartition = $partition\tMerge Face = $merge_face\n")
                flush(f)
                close(f)
                _ = solve_time_stats(seed_range, num_obs_range, file_name=file_name, method=method, partition=partition, merge_faces=merge_face, relax=relax)
            end
        end
    else
        for method in methods            
            file_name = "./Experiments/Solve Times/Solve Time Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition.txt"
            # file_name = "./Experiments/Solve Times Parameters Off/Solve Time Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition.txt"
            # file_name = "./Experiments/Solve Times Relaxed/Relaxed Solve Time Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition.txt"
            f = open(file_name, "w")   # write or append appropriately
            write(f, "Seed Range = $seed_range, Num Obs Range = $num_obs_range\nMethod = $method\tPartition = $partition\n")
            flush(f)
            close(f)
            _ = solve_time_stats(seed_range, num_obs_range, file_name=file_name, method=method, partition=partition, relax=relax)
        end
    end
end


######################################################################################
################################# Problem Size Stats #################################
# Problem size before and after presolve (print model; see how these work: show_constraints_summary, constraints_string)
# Size of disjunctive constraints

function compute_problem_size(obstacles, N, f1, f2, g, Q_g, Q_r, q_t; method="merged", partition="CDT", merge_faces=true, d1=0.2, d2=0.2, p1=[0, 0.07], p2=[0, -0.27])
    if partition == "CDT"
        _, points, graph, _, free_faces = ClutteredEnvPathOpt.construct_graph_delaunay(obstacles, merge_faces=merge_faces)
    else
        _, points, graph, _, free_faces = ClutteredEnvPathOpt.construct_graph(obstacles)
    end

    # model = JuMP.Model(JuMP.optimizer_with_attributes(Gurobi.Optimizer, "MIPGap" => .01, "TimeLimit" => 300))

    # Problem size counters
    all_cont_variables = 0
    all_bin_variables = 0
    disjunctive_cont_variables = 0
    disjunctive_bin_variables = 0
    # all_ineq_constraints = 0
    # all_eq_constraints = 0
    disjunctive_ineq_constraints = 0
    disjunctive_eq_constraints = 0

    # # model has scalar variables x, y, θ, binary variable t
    # JuMP.@variable(model, x[1:N])
    # JuMP.@variable(model, y[1:N])
    # JuMP.@variable(model, θ[1:N])
    # JuMP.@variable(model, t[1:N], Bin)
    all_cont_variables += 3*N
    all_bin_variables += N

    # Objective
    # f = vec([[x[j], y[j], θ[j]] for j in 1:N])
    # f_no_theta = vec([[x[j], y[j]] for j in 1:N])
    # JuMP.@objective(
    #     model,
    #     Min,
    #     ((f[N] - g)' * Q_g * (f[N] - g)) + sum(q_t * t) + sum((f[j + 1] - f[j])' * Q_r * (f[j + 1] - f[j]) for j in 1:(N-1))
    # )

    cover = Set{Pair{Set{Int64}, Set{Int64}}}()
    merged_cover = Set{Pair{Set{Int64}, Set{Int64}}}()
    num_free_face_ineq = 0

    if method != "bigM"
        skeleton = LabeledGraph(graph)
        cover = ClutteredEnvPathOpt.find_biclique_cover(skeleton, free_faces)
        feg = ClutteredEnvPathOpt._find_finite_element_graph(skeleton, ClutteredEnvPathOpt._find_face_pairs(free_faces))
        merged_cover = ClutteredEnvPathOpt.biclique_merger(cover, feg)

        (valid_cover, _, _, _) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, cover)
        (valid_cover_merged, _, _, _) = ClutteredEnvPathOpt._is_valid_biclique_cover_diff(feg, merged_cover)
    end
    
    # Footstep location constraints
    if method == "merged" && valid_cover_merged
        J = LightGraphs.nv(skeleton.graph)
        
        # JuMP.@variable(model, λ[1:N, 1:J] >= 0)
        disjunctive_cont_variables += N * J

        # JuMP.@variable(model, z[1:N, 1:length(merged_cover)], Bin)
        disjunctive_bin_variables += N * (length(merged_cover))
        for i in 1:N
            for (j,(A,B)) in enumerate(merged_cover)
                # JuMP.@constraint(model, sum(λ[i, v] for v in A) <= z[i, j])
                # JuMP.@constraint(model, sum(λ[i, v] for v in B) <= 1 - z[i, j])
                disjunctive_ineq_constraints += 2
            end
            # JuMP.@constraint(model, sum(λ[i,:]) == 1)
            # JuMP.@constraint(model, x[i] == sum(points[j].first * λ[i, j] for j in 1:J))
            # JuMP.@constraint(model, y[i] == sum(points[j].second * λ[i, j] for j in 1:J))
            disjunctive_eq_constraints += 3
        end
    elseif method != "bigM" && valid_cover
        J = LightGraphs.nv(skeleton.graph)

        # JuMP.@variable(model, λ[1:N, 1:J] >= 0)
        disjunctive_cont_variables += N * J

        # JuMP.@variable(model, z[1:N, 1:length(cover)], Bin)
        disjunctive_bin_variables += N * (length(cover))
        for i in 1:N
            for (j,(A,B)) in enumerate(cover)
                # JuMP.@constraint(model, sum(λ[i, v] for v in A) <= z[i, j])
                # JuMP.@constraint(model, sum(λ[i, v] for v in B) <= 1 - z[i, j])
                disjunctive_ineq_constraints += 2
            end
            # JuMP.@constraint(model, sum(λ[i,:]) == 1)
            # JuMP.@constraint(model, x[i] == sum(points[j].first * λ[i, j] for j in 1:J))
            # JuMP.@constraint(model, y[i] == sum(points[j].second * λ[i, j] for j in 1:J))
            disjunctive_eq_constraints += 3
        end
    else
        # Runs if method = "bigM", or if a valid biclique cover is not found
        M, A, b, acc = ClutteredEnvPathOpt.get_M_A_b(points, free_faces)
        num_free_face_ineq = length(M)
        # JuMP.@variable(model, z[1:N, 1:length(free_faces)], Bin)
        disjunctive_bin_variables = N * length(free_faces)
        for j in 1:N
            for r in 1:length(free_faces)
                ids = (acc[r]+1):(acc[r+1])
                for i in ids
                    # JuMP.@constraint(model, A[i, :]' * [x[j]; y[j]] <= b[i] * z[j, r] + M[i] * (1 - z[j, r]))
                    disjunctive_ineq_constraints += 1
                end
            end
            # JuMP.@constraint(model, sum(z[j, :]) == 1)
            disjunctive_eq_constraints += 1
        end
    end

    all_cont_variables += disjunctive_cont_variables
    all_bin_variables += disjunctive_bin_variables
    # all_ineq_constraints += disjunctive_ineq_constraints
    # all_eq_constraints += disjunctive_eq_constraints

    # # Reachability
    # # Breakpoints need to be strategically chosen
    # s_break_pts = [0, 5pi/16, 11pi/16, 21pi/16, 27pi/16, 2pi]
    # c_break_pts = [0, 3pi/16, 13pi/16, 19pi/16, 29pi/16, 2pi]
    # s = [piecewiselinear(model, θ[j], s_break_pts, sin) for j in 1:N]
    # c = [piecewiselinear(model, θ[j], c_break_pts, cos) for j in 1:N]

    # For footstep j, the cirles are created from the frame of reference of footstep j-1
    # Use negative if in frame of reference of right foot (j = 1 is left foot)
    # Position is with respect to θ = 0
    # for j in 2:N
    #     if j % 2 == 1
    #         # In frame of reference of right foot
    #         JuMP.@constraint(
    #             model,
    #             [
    #                 d1,
    #                 x[j] - x[j - 1] - c[j-1] * (-p1[1]) + s[j-1] * (-p1[2]),
    #                 y[j] - y[j - 1] - s[j-1] * (-p1[1]) - c[j-1] * (-p1[2])
    #             ] in SecondOrderCone()
    #         )

    #         JuMP.@constraint(
    #             model,
    #             [
    #                 d2,
    #                 x[j] - x[j - 1] - c[j-1] * (-p2[1]) + s[j-1] * (-p2[2]),
    #                 y[j] - y[j - 1] - s[j-1] * (-p2[1]) - c[j-1] * (-p2[2])
    #             ] in SecondOrderCone()
    #         )
    #     else
    #         # In frame of reference left foot
    #         JuMP.@constraint(
    #             model,
    #             [
    #                 d1,
    #                 x[j] - x[j - 1] - c[j-1] * p1[1] + s[j-1] * p1[2],
    #                 y[j] - y[j - 1] - s[j-1] * p1[1] - c[j-1] * p1[2]
    #             ] in SecondOrderCone()
    #         )

    #         JuMP.@constraint(
    #             model,
    #             [
    #                 d2,
    #                 x[j] - x[j - 1] - c[j-1] * p2[1] + s[j-1] * p2[2],
    #                 y[j] - y[j - 1] - s[j-1] * p2[1] - c[j-1] * p2[2]
    #             ] in SecondOrderCone()
    #         )
    #     end
    # end

    # Set trimmed steps equal to initial position
    # for j in 1:N
    #     if j % 2 == 1
    #         JuMP.@constraint(model, t[j] => {x[j] == f1[1]})
    #         JuMP.@constraint(model, t[j] => {y[j] == f1[2]})
    #         JuMP.@constraint(model, t[j] => {θ[j] == f1[3]})
    #     else
    #         JuMP.@constraint(model, t[j] => {x[j] == f2[1]})
    #         JuMP.@constraint(model, t[j] => {y[j] == f2[2]})
    #         JuMP.@constraint(model, t[j] => {θ[j] == f2[3]})
    #     end
    # end

    # Max step distance
    # for j in 3:2:(N-1)
    #     JuMP.@constraint(model, [delta_x_y_max; f_no_theta[j] - f_no_theta[j - 2]] in SecondOrderCone())
    #     JuMP.@constraint(model, [delta_x_y_max; f_no_theta[j + 1] - f_no_theta[j - 1]] in SecondOrderCone())
    # end

    # Max theta difference for individual feet
    # for j in 3:2:(N-1)
    #     JuMP.@constraint(model, -delta_θ_max <= θ[j] - θ[j - 2] <= delta_θ_max)
    #     JuMP.@constraint(model, -delta_θ_max <= θ[j + 1] - θ[j - 1] <= delta_θ_max)
    # end

    # Max θ difference between feet
    # for j in 2:N
    #     JuMP.@constraint(model, -pi/8 <= θ[j] - θ[j-1] <= pi/8)
    # end

    # Initial footstep positions
    # JuMP.@constraint(model, f[1] .== f1)
    # JuMP.@constraint(model, f[2] .== f2)

    # Print model
    # println("\n\nPrinting model.")
    # print(model)
    # println("\n\nDisplaying model.")
    # display(model)
    # println("\n\nWriting model to file.")
    # write_to_file(model, "test.mof.json", format = MOI.FORMAT_MOF)
    # Solve
    # JuMP.optimize!(model)

    if method == "merged" && valid_cover_merged
        println("\n\nUsed merged cover.\n\n")
    elseif method != "bigM" && valid_cover 
        println("\n\nUsed full cover.\n\n")
        method = "full"
    else
        println("\n\nUsed big-M constraints.\n\n")
        method = "bigM"
    end

    stats = Dict("all_cont_variables" => all_cont_variables, "all_bin_variables" => all_bin_variables,
                 "disjunctive_cont_variables" => disjunctive_cont_variables, "disjunctive_bin_variables" => disjunctive_bin_variables,
                 "disjunctive_ineq_constraints" => disjunctive_ineq_constraints, "disjunctive_eq_constraints" => disjunctive_eq_constraints,
                 "MBC_size" => length(merged_cover), "FBC_size" =>  length(cover), "num_free_faces" => length(free_faces),
                 "num_free_face_ineq" =>num_free_face_ineq, "num_vertices" => LightGraphs.nv(graph), "method" => method)
                        # "all_ineq_constraints" => 1, "all_eq_constraints" => 1,

    return stats
end

function problem_size_stats(seed_range, num_obs_range; file_name="Problem Size Stats.txt", method="merged", partition="CDT", merge_faces=true)

    # Set parameters
    N = 20  # number of steps
    f1 = [0.0, 0.1, 0.0]  # initial footstep pose 1
    f2 = [0.0, 0.0, 0.0]  # initial footstep pose 2
    goal = [1, 1, 0]  # goal pose
    Q_g = 10*Matrix{Float64}(I, 3, 3)  # weight between final footstep and goal pose
    Q_r = Matrix{Float64}(I, 3, 3)  # weight between footsteps
    q_t = -.05  # weight for trimming unused steps
    # Optional named arguments
    # d1 = 0.2 # radius of reference foot circle
    # d2 = 0.2 # radius of moving foot circle
    # p1 = [0, 0.07] # center of reference foot circle
    # p2 = [0, -0.27] # center of moving foot circle
    # delta_x_y_max = 0.10  # max stride norm in space
    # delta_θ_max = pi/4  # max difference in θ
    
    f = open(file_name, "a")   # file is created outside of function
    # write(f, "Seed\tNum_obs\tTime\n")
    write(f, "Seed\tNum_obs\tDisjunctive_cont_var\tDisjunctive_bin_var\tDisjunctive_ineq_cons\tDisjunctive_eq_cons\tAll_cont_var\tAll_bin_var\tNum_vertices\tBC_merged_size\tBC_full_size\tNum_free_face_ineq\tNum_free_faces\n")
    # some_success_indicator = zeros(length(seed_range) * length(num_obs_range))
    # i = 1
    for seed = seed_range
        for num_obs = num_obs_range
            # f = open(file_name, "a")
            # write(f, "Seed = $seed, Num_Obs = $num_obs\n")
            # flush(f)
            # close(f)
            # println("On test Seed = $seed, Num_Obs = $num_obs")

            # Create obstacles
            obstacles = ClutteredEnvPathOpt.gen_field_random(num_obs, seed = seed)

            stats = compute_problem_size(obstacles, N, f1, f2, goal, Q_g, Q_r, q_t, method=method, partition=partition, merge_faces=merge_faces)

            # if method_used == method
            #     some_success_indicator[i] = r_solve_time # time
            # else
            #     some_success_indicator[i] = -1
            # end
            write(f, "$seed\t$num_obs\t$(stats["disjunctive_cont_variables"])\t$(stats["disjunctive_bin_variables"])\t$(stats["disjunctive_ineq_constraints"])\t$(stats["disjunctive_eq_constraints"])")
            write(f, "\t$(stats["all_cont_variables"])\t$(stats["all_bin_variables"])\t$(stats["num_vertices"])\t$(stats["MBC_size"])\t$(stats["FBC_size"])\t$(stats["num_free_face_ineq"])\t$(stats["num_free_faces"])\n")
            flush(f)

            # i += 1
        end
    end

    # write(f, "\nEND")
    # flush(f)
    close(f)
end

seed_start = 1
seed_end = 50
seed_range = seed_start:seed_end
num_obs = 1
num_obs_range = num_obs:num_obs
# partitions = ["CDT", "HP"]
partitions = ["CDT"]
# merge_faces = [true, false]
merge_faces = [true]
# merge_faces = [false]
methods = ["merged", "full", "bigM"]
# methods = ["merged"]
# methods = ["full"]
# methods = ["bigM"]
for partition in partitions
    if partition == "CDT"
        for merge_face in merge_faces
            for method in methods
                file_name = "./Experiments/Problem Sizes/Problem Size Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition Merge Face $merge_face.txt"
                f = open(file_name, "w")   # write or append appropriately
                write(f, "Seed Range = $seed_range, Num Obs Range = $num_obs_range\nMethod = $method\tPartition = $partition\tMerge Face = $merge_face\n")
                flush(f)
                close(f)
                stats = problem_size_stats(seed_range, num_obs_range, file_name=file_name, method=method, partition=partition, merge_faces=merge_face)
            end
        end
    else
        for method in methods
            file_name = "./Experiments/Problem Sizes/Problem Size Stats Seed Range $seed_start to $seed_end Num Obs $num_obs Method $method Partition $partition.txt"
            f = open(file_name, "w")   # write or append appropriately
            write(f, "Seed Range = $seed_range, Num Obs Range = $num_obs_range\nMethod = $method\tPartition = $partition\n")
            flush(f)
            close(f)
            stats = problem_size_stats(seed_range, num_obs_range, file_name=file_name, method=method, partition=partition)
        end
    end
end




#######################################################################################
################################ Debugging Functions ##################################


# # Duplicate tests
# obstacles = ClutteredEnvPathOpt.gen_field_random(num_obs, seed = seed)
# points, mapped, inside_quant = ClutteredEnvPathOpt.find_intersections(obstacles)
# neighbors = ClutteredEnvPathOpt._find_neighbors(points, mapped)
# points = ClutteredEnvPathOpt.find_points(obstacles)

# dup, dup_ind = face_duplicates(obstacle_faces)
# dup, dup_ind = face_duplicates(free_faces)
# dup, dup_ind = face_duplicates(all_faces)
# plot_intersections_indiv(points)
# dup, dup_ind = point_duplicates(points)
# dup, dup_ind = points_in_hs_duplicates(mapped)
# dup, dup_ind = hs_duplicates(mapped)
# points_in_mapped_ordered(obstacles, mapped)
# plot_neighbors(obstacles, neighbors, points)
# list_neighbors(neighbors, points)
# suspect = suspect_neighbors(neighbors)


# Check if free_faces has any duplicates---------------------------------------------
function face_duplicates(faces)
    dup = 0
    dup_ind = []
    col_faces = collect(faces)
    for i in 1:length(col_faces)
        for j = (i+1):length(col_faces)
            sort_i = sort(col_faces[i])
            sort_j = sort(col_faces[j])
            if sort_i == sort_j
                dup += 1
                push!(dup_ind, (i,j))
            end
        end
    end
    return dup, dup_ind
end

# Check if points has any duplicates---------------------------------------------
function point_duplicates(points)
    dup = 0
    dup_ind = []
    tol = Rational(1.e-13)
    for i in 1:(length(points))
        for j in (i+1):(length(points))
            #if (points[i].first == points[j].first) && (points[i].second == points[j].second)
            if abs(points[i].first - points[j].first) < tol && abs(points[i].second - points[j].second) < tol
                dup += 1
                push!(dup_ind, (i,j))
            end
        end
    end
    # for (i,j) in dup_ind
    #     println("Points $i and $j: \n ($(points[i])) \n ($(points[j]))")
    # end
    return dup, dup_ind
end

# Check if halfspaces in mapped have any duplicated points within them ---------
function points_in_hs_duplicates(mapped)
    dup = 0
    dup_ind = []
    for (l,hs) in enumerate(mapped)
        for i in 1:(length(hs))
            for j in (i+1):(length(hs))
                if (hs[i].first == hs[j].first) && (hs[i].second == hs[j].second)
                    dup += 1
                    push!(dup_ind, (l,i,j))
                end
            end
        end
    end
    return dup, dup_ind
end

# Check if any halfspaces in mapped are duplicates-----------------------------
function hs_duplicates(mapped)
    dup = 0
    dup_ind = []
    for i = 1:length(mapped)
        for j = (i+1):length(mapped)
            if mapped[i] == mapped[j]
                dup += 1
                push!(dup_ind, (i,j))
            end
        end
    end
    return dup, dup_ind
end

# Check to see if points are in order in mapped---------------------------------
function points_in_mapped_ordered(obstacles, mapped)
    for hs in mapped
        plot(legend=false,xlims=(-0.05,1.05),ylims=(-0.05,1.05));
        ClutteredEnvPathOpt.plot_field!(obstacles)
        ClutteredEnvPathOpt.plot_lines(obstacles)
        for point in hs
            display(scatter!([point.first], [point.second]))
        end
    end
end

# Plot points individually----------------------------------------------------------
function plot_intersections_indiv(intersections)
    x = map(point -> point[1], intersections)
    y = map(point -> point[2], intersections)
    Plots.plot(legend=false,xlims=(-0.05,1.05),ylims=(-0.05,1.05))
    for i = 1:length(intersections)
        # Plots.plot(legend=false,xlims=(-0.05,1.05),ylims=(-0.05,1.05))
        display(Plots.scatter!([x[i]],[y[i]],title="Point $i:\n$(x[i])\n$(y[i])"))
    end
end

# Check if neighbors are correct----------------------------------------------------
function plot_neighbors(obstacles, neighbors, points)
    for (i,point) in enumerate(points)
        ClutteredEnvPathOpt.plot_field(obstacles)
        ClutteredEnvPathOpt.plot_lines(obstacles)
        display(scatter!([point.first],[point.second],title="Point $i"))
        x_i_neighbors = map(node -> points[node].first, neighbors[i])
        y_i_neighbors = map(node -> points[node].second, neighbors[i])
        display(scatter!(x_i_neighbors,y_i_neighbors, title="Point $i. Neighbors $(neighbors[i])"))
        #println("Point $i has neighbors $(neighbors[i]).")
    end
end

function list_neighbors(neighbors, points)
    for i in 1:length(points)
        println("Point $i has neighbors $(neighbors[i]).")
    end
end

function duplicates(n)
    dup = 0
    for i in 1:length(n)
        for j in (i+1):length(n)
            if n[i] == n[j]
                dup += 1
            end
        end
    end
    return dup != 0
end

function suspect_neighbors(neighbors)
    suspect = []
    for n in 1:length(neighbors)
        if length(neighbors[n]) > 4 || duplicates(neighbors[n])
        #if duplicates(neighbors[n])
            push!(suspect, n)
        end
    end
    for point in suspect
        println("Point $point has neighbors $(neighbors[point])")
    end
    return suspect
end
