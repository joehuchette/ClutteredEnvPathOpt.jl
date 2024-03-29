import Plots
import Statistics
import LightGraphs
import Polyhedra
import GLPK
# TODO: plot xlim/ylim currently hardcoded and data types still Rational{Int}

"""
    plot_faces(faces, points; plot_name, col, new_plot, individually)

Given a set of vectors corresponding to faces of a planar graph, plots the faces in the unit square.
"""
function plot_faces(faces::Set{Vector{T}}, points::Vector{Pair{Rational{Int}}}; plot_name::String="Faces", col::String="green3", new_plot::Bool=true, individually::Bool=false) where {T}
    if new_plot && !individually
        Plots.plot()
    end

    for (j,face) in enumerate(faces)
        v = Polyhedra.convexhull(map(i -> collect(points[i]), face)...)
        x_locations = map(i -> points[i].first, face)
        y_locations = map(i -> points[i].second, face)

        # avg_x = Statistics.mean(x_locations)
        # avg_y = Statistics.mean(y_locations)

        polygon = Polyhedra.polyhedron(
            v,
            Polyhedra.DefaultLibrary{Rational{Int64}}(GLPK.Optimizer)
        )

        if individually
            # Plot each face on a separate plot with node labels
            Plots.plot(polygon, color=col, alpha=0.9)
            Plots.plot!(x_locations, y_locations, series_annotations=([Plots.text(string(x), :center, 8, "courier") for x in face]))
            display(Plots.plot!(xlims=(-0.05,1.05), ylims=(-0.05,1.05), title="Face $j: $face"))
        else
            # Accumulate the faces on the same plot
            Plots.plot!(polygon, color=col, alpha=0.9)
            # Plots.plot!([avg_x], [avg_y], series_annotations=([Plots.text("$j", :center, 8, "courier")]))
            # display(Plots.plot!(polygon, title="Free Face # $j", xlims=(-0.05,1.05), ylims=(-0.05,1.05)))
        end
    end

    if !individually
        display(Plots.plot!(title=plot_name, xlims=(-0.05,1.05), ylims=(-0.05,1.05)))
    end
end

"""
    plot_edges(lg, points; plot_name, col, new_plot, vertices, with_labels)

Given a LabeledGraph, plots its nodes and edges in the unit square.
"""
function plot_edges(lg::LabeledGraph{T}, points::Vector{Pair{Rational{Int}}}; plot_name::String="Edges", col::String="colorful", new_plot::Bool=true, vertices::Dict{T,T}=Dict{T,T}(), with_labels::Bool=true) where {T}
    if new_plot
        Plots.plot()
    end

    # Need to map nodes to the point they refer to in "points"
    rev = ClutteredEnvPathOpt._reverse_labels(lg.labels)
    for edge in LightGraphs.edges(lg.graph)
        if col == "colorful"
            Plots.plot!([points[rev[edge.src]].first, points[rev[edge.dst]].first], [points[rev[edge.src]].second, points[rev[edge.dst]].second],linewidth=2)
            # display(Plots.plot!(title="Edge ($(rev[edge.src]), $(rev[edge.dst]))"))
        else
            Plots.plot!([points[rev[edge.src]].first, points[rev[edge.dst]].first], [points[rev[edge.src]].second, points[rev[edge.dst]].second], color=col,linewidth=2)
            # display(Plots.plot!(title="Edge ($(rev[edge.src]), $(rev[edge.dst]))"))
        end
    end

    ClutteredEnvPathOpt.plot_points(points, vertices=vertices, with_labels=with_labels)

    display(Plots.plot!(title=plot_name, xlims=(-0.05,1.05), ylims=(-0.05,1.05), legend=false))
end

"""
    plot_edges(lg, points, partition; plot_name, col, new_plot, vertices, with_labels)

Given a LabeledGraph, plots its nodes and edges in the unit square by partition.
"""
function plot_edges(lg::LabeledGraph{T}, points::Vector{Pair{Rational{Int}}}, partition::Tuple{Set{Int},Set{Int},Set{Int}}; plot_name::String="Edges", col::String="colorful", new_plot::Bool=true, vertices::Dict{T,T}=Dict{T,T}(), with_labels::Bool=true) where {T}
    if new_plot
        Plots.plot()
    end

    # Need to map nodes to the point they refer to in "points"
    rev = ClutteredEnvPathOpt._reverse_labels(lg.labels)
    for edge in LightGraphs.edges(lg.graph)
        if col == "colorful"
            Plots.plot!([points[rev[edge.src]].first, points[rev[edge.dst]].first], [points[rev[edge.src]].second, points[rev[edge.dst]].second],linewidth=2)
            # display(Plots.plot!(title="Edge ($(rev[edge.src]), $(rev[edge.dst]))"))
        else
            Plots.plot!([points[rev[edge.src]].first, points[rev[edge.dst]].first], [points[rev[edge.src]].second, points[rev[edge.dst]].second], color=col,linewidth=2)
            # display(Plots.plot!(title="Edge ($(rev[edge.src]), $(rev[edge.dst]))"))
        end
    end

    ClutteredEnvPathOpt.plot_points(points, partition, vertices=vertices, with_labels=with_labels)

    display(Plots.plot!(title=plot_name, xlims=(-0.05,1.05), ylims=(-0.05,1.05), legend=false))
end

"""
    plot_biclique_cover(lg, points, cover; with_all, name, save_plots)

Given a LabeledGraph and a biclique cover, plot each biclique (green edges). Remaining edges in conflict
graph can also be plotted (grey edges).
"""
function plot_biclique_cover(lg::LabeledGraph{T}, points::Vector{Pair{Rational{Int}}}, cover::Set{Pair{Set{T}, Set{T}}}; with_all::Bool=false, name::String="Biclique", save_plots::Bool=false) where {T}
    e_bar = LightGraphs.edges(LightGraphs.complement(lg.graph))

    # Vector of sets of pairs (edges)
    cover_vec = collect(cover)
    BC_edges = map(pair -> ClutteredEnvPathOpt._cartesian_product(pair.first, pair.second), cover_vec)
    # all_BC_edges = reduce(union!, BC_edges, init=Set{Pair{T,T}}())
    # temp_graph = LightGraphs.SimpleGraph(LightGraphs.nv(lg.graph))   # will contain BC edges
    rev = ClutteredEnvPathOpt._reverse_labels(lg.labels)

    # for edge in all_BC_edges
    #     # edge.first/second will be our nodes, so we map them to the nodes they are in the graph
    #     LightGraphs.add_edge!(temp_graph, lg.labels[edge.first], lg.labels[edge.second])
    # end

    # colors = [:firebrick1, :dodgerblue, :limegreen]

    # Plot biclique
    for (j,biclique_edges) in enumerate(BC_edges)
        plot(legend=false)
        if with_all
            temp_graph = LightGraphs.SimpleGraph(LightGraphs.nv(lg.graph))
            for edge in biclique_edges
                # edge.first/second will be our nodes, so we map them to the nodes they are in the graph
                LightGraphs.add_edge!(temp_graph, lg.labels[edge.first], lg.labels[edge.second])
            end

            for edge in e_bar
                if !(edge in LightGraphs.edges(temp_graph))
                    Plots.plot!([points[rev[edge.src]].first, points[rev[edge.dst]].first], [points[rev[edge.src]].second, points[rev[edge.dst]].second], linewidth=2, color="grey60")#, linealpha=0.5)
                    # display(Plots.plot!(title="Edge ($(rev[edge.src]), $(rev[edge.dst]))"))
                end
            end
            # display(Plots.plot!(title="Conflict Graph - Biclique $j"))
        end

        for edge in biclique_edges
            # Plots.plot!([points[rev[edge.first]].first, points[rev[edge.second]].first], [points[rev[edge.first]].second, points[rev[edge.second]].second], linewidth=2, color=colors[(j % 3) + 1])
            Plots.plot!([points[rev[edge.first]].first, points[rev[edge.second]].first], [points[rev[edge.first]].second, points[rev[edge.second]].second], linewidth=2, color=:green3)
            # display(Plots.plot!(title="Edge ($(rev[edge.first]), $(rev[edge.second]))"))
        end

        # See plot_points
        x = map(point -> point.first, points)
        y = map(point -> point.second, points)
        for i = 1:length(points)
            if i in cover_vec[j].first
                # Plots.scatter!([x[i]],[y[i]], color="red", markersize = 7) #, series_annotations=([Plots.text(string(i), :right, 8, "courier")]))
                Plots.scatter!([x[i]],[y[i]], color="red", markersize = 7, series_annotations=([Plots.text(string(i), :top, 15)]))
            elseif i in cover_vec[j].second
                # Plots.scatter!([x[i]],[y[i]], color="blue", markersize = 7) #, series_annotations=([Plots.text(string(i), :right, 8, "courier")]))
                Plots.scatter!([x[i]],[y[i]], color="blue", markersize = 7, series_annotations=([Plots.text(string(i), :top, 15)]))
            else
                # Plots.scatter!([x[i]],[y[i]], color="grey35", markersize = 7) #, series_annotations=([Plots.text(string(i), :right, 8, "courier")]))
                Plots.scatter!([x[i]],[y[i]], color="grey35", markersize = 7, series_annotations=([Plots.text(string(i), :top, 15)]))
            end
        end

        display(Plots.plot!(title="Biclique $j"))
        # display(Plots.plot!())
        if save_plots
            # savefig("$name $j.pdf")
            png("$name $j")
        end
    end
end

"""
    plot_field(field; title, display_plot)

Plots the obstacles onto a new plot.
"""
function plot_field(field; title::String="", display_plot::Bool=false)
    Plots.plot(title=title)
    for i = 1:length(field)
        Plots.plot!(field[i], xlims = (-0.05,1.05), ylim = (-0.05, 1.05))
    end
    if display_plot
        display(Plots.plot!())
    end
end

"""
    plot_field!(field)

Plots the obstacles onto the existing active plot.
"""
function plot_field!(field)
    for i = 1:length(field)
        Plots.plot!(field[i], xlims = (-0.05,1.05), ylim = (-0.05, 1.05))
    end
end

"""
    plot_lines(field)

Plots the lines that make up the obstacles' halfspaces to the existing active
plot. Requires active plot.
"""
function plot_lines(field)
    halfspaces = @pipe map(obstacle -> Polyhedra.hrep(obstacle).halfspaces, field) |> Iterators.flatten(_) |> collect(_)
    unique!(halfspaces)

    for h in halfspaces
        if abs(h.a[2]) != 0//1
            f = x -> (h.β - h.a[1] * x) // h.a[2]

            x = LinRange(0//1, 1//1, 11)
            y = map(f, x)
        else  # vertical lines
            x = fill(abs(h.β // h.a[1]), 11)
            y = LinRange(0//1, 1//1, 11)
        end

        Plots.plot!(x, y)
    end
end

"""
    plot_borders()

Plots the lines that make up the unit square's borders to the existing active
plot.
"""
function plot_borders()
    halfspaces = [
        Polyhedra.HalfSpace([-1//1, 0//1], 0//1),
        Polyhedra.HalfSpace([1//1, 0//1], 1//1),
        Polyhedra.HalfSpace([0//1, -1//1], 0//1),
        Polyhedra.HalfSpace([0//1, 1//1], 1//1)
    ]

    for h in halfspaces
        if abs(h.a[2]) != 0//1
            f = x -> (h.β - h.a[1] * x) // h.a[2]

            x = LinRange(0//1, 1//1, 11)
            y = map(f, x)
        else  # vertical lines
            x = fill(abs(h.β // h.a[1]), 11)
            y = LinRange(0//1, 1//1, 11)
        end

        Plots.plot!(x, y)
    end
end

"""
    plot_intersections(field; vertices)

Plots and labels the points where the lines that make up the obstacles'
halfspaces intersect to the existing active plot. Optional argument to plot
a subset of vertices.
"""
function plot_intersections(field; vertices::Dict{T,T}=Dict{T,T}()) where {T}
    intersections, _, inside_quant = find_intersections(field)

    # Remove points inside obstacles (located at end of vector)
    for _ = 1:inside_quant
        pop!(intersections)
    end

    if !isempty(vertices)
        # points_filtered = []   # this approach makes it type Vector{Any}, whereas map() makes in Vector{T} where T is the element type of intersections
        # for v in keys(vertices)
        #     push!(points_filtered, intersections[v])
        # end
        # points_filtered = @pipe filter(v -> v in keys(vertices), 1:length(intersections)) |> intersections[_]   # type Vector{T} and in order
        points_filtered = map(v -> intersections[v], collect(keys(vertices)))
        x = map(point -> point.first, points_filtered)
        y = map(point -> point.second, points_filtered)
        Plots.scatter!(x,y, color="red", series_annotations=([Plots.text(string(x), :right, 8, "courier") for x in keys(vertices)]))
    else
        x = map(point -> point.first, intersections)
        y = map(point -> point.second, intersections)
        Plots.scatter!(x,y, color="red", series_annotations=([Plots.text(string(x), :right, 8, "courier") for x in 1:length(points)]))
    end
end

"""
    plot_points(points; vertices, with_labels)

Plots and labels points given. Optional argument to plot a subset of vertices.
Requires active plot.
"""
function plot_points(points::Vector{Pair{Rational{Int}}}; vertices::Dict{Int,Int}=Dict{Int,Int}(), with_labels::Bool=true)
    # TODO: Make plot_points!() for this method
    Plots.plot!(legend=false)

    if !isempty(vertices)
        # points_filtered = []   # this approach makes it type Vector{Any}, whereas map() makes in Vector{T} where T is the element type of intersections
        # for v in keys(vertices)
        #     push!(points_filtered, points[v])
        # end
        # points_filtered = @pipe filter(v -> v in keys(vertices), 1:length(intersections)) |> intersections[_]   # type Vector{T} and in order
        points_filtered = map(v -> intersections[v], collect(keys(vertices)))
        x = map(point -> point.first, points_filtered)
        y = map(point -> point.second, points_filtered)
        if with_labels
            Plots.scatter!(x,y, color="red", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in keys(vertices)]))
        else
            Plots.scatter!(x,y, color="red", markersize=7)
        end
    else
        x = map(point -> point.first, points)
        y = map(point -> point.second, points)
        if with_labels
            Plots.scatter!(x,y, color="red", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in 1:length(points)]))
        else
            Plots.scatter!(x,y, color="red", markersize=7)
        end
    end

end

"""
    plot_points(points, partition; vertices, with_labels)

Plots and labels points given by partition. Optional argument to plot a subset of vertices.
Requires active plot.
"""
function plot_points(points::Vector{Pair{Rational{Int}}}, partition::Tuple{Set{Int},Set{Int},Set{Int}}; vertices::Dict{Int,Int}=Dict{Int,Int}(), with_labels::Bool=true)
    # TODO: Make plot_points!() for this method
    Plots.plot!(legend=false)
    A,B,C = partition

    if !isempty(vertices)
        # points_filtered = []
        points_filtered_A = []
        points_filtered_B = []
        points_filtered_C = []
        v_filtered_A = []
        v_filtered_B = []
        v_filtered_C = []
        for v in keys(vertices)
            # push!(points_filtered, points[v])
            if v in A
                push!(points_filtered_A, points[v])
                push!(v_filtered_A, v)
            elseif v in B
                push!(points_filtered_B, points[v])
                push!(v_filtered_B, v)
            else
                push!(points_filtered_C, points[v])
                push!(v_filtered_C, v)
            end
        end
        # x = map(point -> point.first, points_filtered)
        # y = map(point -> point.second, points_filtered)
        x_A = map(point -> point.first, points_filtered_A)
        y_A = map(point -> point.second, points_filtered_A)
        x_B = map(point -> point.first, points_filtered_B)
        y_B = map(point -> point.second, points_filtered_B)
        x_C = map(point -> point.first, points_filtered_C)
        y_C = map(point -> point.second, points_filtered_C)
        if with_labels
            Plots.scatter!(x_A, y_A, color="red", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in v_filtered_A]))
            Plots.scatter!(x_B, y_B, color="blue", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in v_filtered_B]))
            Plots.scatter!(x_C, y_C, color="green", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in v_filtered_C]))
        else
            Plots.scatter!(x_A, y_A, color="red", markersize=7)
            Plots.scatter!(x_B, y_B, color="blue", markersize=7)
            Plots.scatter!(x_C, y_C, color="green", markersize=7)
        end
    else
        # x = map(point -> point.first, points)
        # y = map(point -> point.second, points)
        AA = collect(A)
        BB = collect(B)
        CC = collect(C)
        x_A = [points[v].first for v in AA]
        y_A = [points[v].second for v in AA]
        x_B = [points[v].first for v in BB]
        y_B = [points[v].second for v in BB]
        x_C = [points[v].first for v in CC]
        y_C = [points[v].second for v in CC]

        if with_labels
            Plots.scatter!(x_A,y_A, color="red", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in AA]))
            Plots.scatter!(x_B,y_B, color="blue", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in BB]))
            Plots.scatter!(x_C,y_C, color="green", markersize=7, series_annotations=([Plots.text(string(x), :top, 15) for x in CC]))
        else
            Plots.scatter!(x_A,y_A, color="red", markersize=7)
            Plots.scatter!(x_B,y_B, color="blue", markersize=7)
            Plots.scatter!(x_C,y_C, color="green", markersize=7)
        end
    end
end

"""
    plot_steps(obstacles, x, y, θ)

Plots footsteps of optimal path along with arrows indicating orientation.
"""
function plot_steps(obstacles, x, y, θ)
    ClutteredEnvPathOpt.plot_field(obstacles);
    scatter!(x[1:2:end], y[1:2:end], color="red", markersize=5, series_annotations=([Plots.text(string(x), :right, 8, "courier") for x in 1:2:length(x)]));
    scatter!(x[2:2:end], y[2:2:end], color="blue", markersize=5, series_annotations=([Plots.text(string(x), :right, 8, "courier") for x in 2:2:length(x)]));
    quiver!(x, y, quiver=(0.075 * cos.(θ), 0.075 * sin.(θ)))
end

"""
    plot_new(n, plot_name; seed, save_image, partition, merge_faces)

Plots and generates associated data for a randomly generated set of n obstacles.
"""
function plot_new(n::Int, plot_name::String; seed::Int=1, save_image::Bool=false, partition::String="CDT", merge_faces::Bool=false)
    obs = gen_field_random(n, seed = seed)

    if save_image
        plot_field(obs)
        points = ClutteredEnvPathOpt.find_points(obs)
        plot_points(points)
        #plot_lines(obs)
        #plot_borders()
        #plot_intersections(obs)
        Plots.png(plot_name)
        display(Plots.plot!(title="Field"))
    end

    if partition == "CDT"
        return construct_graph_delaunay(obs; merge_faces=merge_faces)
    else
        return construct_graph(obs)
    end
end

"""
    plot_new(obstacles, plot_name; save_image, partition, merge_faces)

Plots and generates associated data for a given set of obstacles.
"""
function plot_new(obstacles, plot_name::String; save_image::Bool=false, partition::String="CDT", merge_faces::Bool=true)
    obs = gen_field(obstacles)

    if save_image
        plot_field(obs)
        points = ClutteredEnvPathOpt.find_points(obs)
        plot_points(points)
        #plot_lines(obs)
        #plot_borders()
        #plot_intersections(obs)
        Plots.png(plot_name)
        display(Plots.plot!(title="Field"))
    end

    if partition == "CDT"
        return construct_graph_delaunay(obs; merge_faces=merge_faces)
    else
        return construct_graph(obs)
    end
end