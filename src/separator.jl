# Returns (Separator, A, B)
function find_separator_lt(lg::LabeledGraph{T}, root::T)::Tuple{Set{T}, Set{T}, Set{T}} where {T}
    levels = @pipe LightGraphs.bfs_tree(lg.graph, lg.labels[root]) |> _find_bfs_levels(_, lg.labels[root]) |> map(level -> Set(convert_vertices(lg.labels, collect(level))), _)

    # Phase I
    middle_index = -1
    for i in 2:length(levels)
        if sum(map(j -> length(levels[j]), 1:i)) > (LightGraphs.nv(lg.graph) / 2)
            middle_index = i
            break
        end
    end
    middle = levels[middle_index]

    if length(middle) < (2 * sqrt(2 * LightGraphs.nv(lg.graph)))
        above = @pipe map(i -> levels[i], 1:(middle_index - 1)) |> reduce(union, _)
        below = middle_index < length(levels) ? (@pipe map(i -> levels[i], (middle_index + 1):length(levels)) |> reduce(union, _)) : Set()
        a = length(above) < length(below) ? above : below;
        b = length(above) < length(below) ? below : above;
        return (middle, a, b)
    end

    # Phase II
    upper_index = -1;
    for i in middle_index:-1:1
        distance = middle_index - i
        if length(levels[i]) < 2 * (sqrt(LightGraphs.nv(lg.graph)) - distance)
            upper_index = i
            break
        end
    end
    if sum(map(i -> length(levels[i]), 1:upper_index)) > 1/3
        # upper is separator
        above = upper_index > 1 ? (@pipe map(i -> levels[i], 1:(upper_index - 1)) |> reduce(union, _)) : Set()
        below = upper_index < length(levels) ? (@pipe map(i -> levels[i], (upper_index + 1):length(levels)) |> reduce(union, _)) : Set()
        a = length(above) < length(below) ? above : below;
        b = length(above) < length(below) ? below : above;
        return (levels[upper_index], a, b)
    end

    lower_index = -1;
    for i in middle_index:length(levels)
        distance = i - middle_index
        if length(levels[i]) < 2 * (sqrt(LightGraphs.nv(lg.graph)) - distance)
            lower_index = i
            break
        end
    end
    if sum(map(i -> length(levels[i]), lower_index:length(levels))) > 1/3
        # lower is separator
        above = lower_index > 1 ? (@pipe map(i -> levels[i], 1:(lower_index - 1)) |> reduce(union, _)) : Set()
        below = lower_index < length(levels) ? (@pipe map(i -> levels[i], (lower_index + 1):length(levels)) |> reduce(union, _)) : Set()
        a = length(above) < length(below) ? above : below;
        b = length(above) < length(below) ? below : above;
        return (levels[lower_index], a, b)
    end

    # TODO: Phase III
    ## Find a cycle between upper and lower by adding a non-tree edge
    ## Find nodes in the inner bit to the left and right of the cycle
    ## add larger of left/right to smaller of above/below and vice versa
    return find_separator_fcs(lg, root)

end

function find_separator_fcs(lg::LabeledGraph{T}, root::T)::Tuple{Set{T}, Set{T}, Set{T}} where {T}
    parents = LightGraphs.bfs_parents(lg.graph, lg.labels[root])

    tree_edges = map(tup -> LightGraphs.Edge(tup[1] => tup[2]), zip(parents, 1:length(parents)))
    non_tree_edge = filter(edge -> !(in(edge, tree_edges) || in(reverse(edge), tree_edges)), collect(LightGraphs.edges(lg.graph)))[1]

    fundamental_cycle = @pipe _find_fundamental_cycle(parents, root, non_tree_edge) |> Set(convert_vertices(lg.labels, collect(_)))
    return (fundamental_cycle, _find_partitions(lg, fundamental_cycle)...)
end

function find_separator_fcs_best(lg::LabeledGraph{T}, root::T)::Tuple{Set{T}, Set{T}, Set{T}} where {T}
    # THIS ALGORITHM IS O(n^2) BECAUSE IT CHOOSES THE MOST BALANCED
    parents = LightGraphs.bfs_parents(lg.graph, lg.labels[root])

    tree_edges = map(tup -> LightGraphs.Edge(tup[1] => tup[2]), zip(parents, 1:length(parents)))
    non_tree_edges = filter(edge -> !(in(edge, tree_edges) || in(reverse(edge), tree_edges)), collect(LightGraphs.edges(lg.graph)))

    fundamental_cycles = @pipe map(non_tree_edge -> _find_fundamental_cycle(parents, root, non_tree_edge), non_tree_edges) |> map(cycle -> Set(convert_vertices(lg.labels, collect(cycle))), _)
    partitions = map(cycle -> (cycle, _find_partitions(lg, cycle)...), fundamental_cycles)
    balances = map(partition -> min(length(partition[2]) / length(partition[3]), length(partition[3]) / length(partition[2])), partitions)

    max_balance = max(balances...)
    for i in 1:length(balances)
        if balances[i] == max_balance return partitions[i] end
    end
    return partitions[1]
end

function pp_expell(lg::LabeledGraph{T}, separator::Set{T}, a::Set{T}, b::Set{T})::Tuple{Set{T}, Set{T}, Set{T}} where {T}
    new_separator = copy(separator)
    new_a = copy(a)
    new_b = copy(b)

    if isempty(a)
        availible = filter(
            vertex -> reduce(|, map(destination -> LightGraphs.has_path(lg.graph, vertex, destination, exclude_vertices=collect(separator)), collect(new_b))),
            collect(separator)
        )
        if !isempty(availible) push!(new_a, availible[1]) end
    end

    if isempty(b)
        availible = filter(
            vertex -> reduce(|, map(destination -> LightGraphs.has_path(lg.graph, vertex, destination, exclude_vertices=collect(separator)), collect(new_a))),
            collect(separator)
        )
        if !isempty(availible) push!(new_b, availible[1]) end
    end

    for vertex in new_separator
        is_connected_a = @pipe map(destination -> LightGraphs.has_path(lg.graph, vertex, destination, exclude_vertices=collect(setdiff(new_separator, vertex))), collect(new_a)) |> reduce(|, _)
        is_connected_b = @pipe map(destination -> LightGraphs.has_path(lg.graph, vertex, destination, exclude_vertices=collect(setdiff(new_separator, vertex))), collect(new_b)) |> reduce(|, _)

        if !is_connected_a && !is_connected_b
            push!(length(new_a) < length(new_b) ? new_a : new_b, vertex)
            delete!(new_separator, vertex)
        elseif is_connected_a && !is_connected_b
            push!(new_a, vertex)
            delete!(new_separator, vertex)
        elseif !is_connected_a && is_connected_b
            push!(new_b, vertex)
            delete!(new_separator, vertex)
        end

    end

    return (new_separator, new_a, new_b)
end

function _find_partitions(lg::LabeledGraph{T}, separator::Set{T})::Tuple{Set{T}, Set{T}} where {T}
    lg_without_separator = copy(lg)

    for vertex in separator
        lg_rem_vertex!(lg_without_separator, vertex)
    end

    components = @pipe LightGraphs.connected_components(lg_without_separator.graph) |>
        map(component -> convert_vertices(lg_without_separator.labels, component), _) |>
        sort(_, by=length, rev=true)
    a = Array{T, 1}()
    b = Array{T, 1}()
    for component in components
        append!(sum(map(length, a)) < sum(map(length, b)) ? a : b, component)
    end

    return (Set(a), Set(b))
end

function _find_fundamental_cycle(parents::Array{Int, 1}, root::Int, non_tree_edge::LightGraphs.Edge)::Set{Int}
    left_vertex = LightGraphs.src(non_tree_edge)
    left_path = [left_vertex]
    while left_vertex != parents[left_vertex]
        left_vertex = parents[left_vertex]
        pushfirst!(left_path, left_vertex)
    end

    right_vertex = LightGraphs.dst(non_tree_edge)
    right_path = [right_vertex]
    while right_vertex != parents[right_vertex]
        right_vertex = parents[right_vertex]
        pushfirst!(right_path, right_vertex)
    end

    for i in 1:max(length(left_path), length(right_path))
        if left_path[i] != right_path[i]
            return Set(union(left_path[i:end], right_path[i:end], left_path[i - 1]))
        end
    end

    return Set(union(left_path, right_path))
end

function _find_bfs_levels(t::LightGraphs.AbstractGraph, root::Int)::Array{Set{Int}, 1}
    levels = Dict{Int, Set{Int}}()

    levels[1] = Set([root])
    i = 2
    while true
        levels[i] = Set(reduce(union, map(vertex -> LightGraphs.outneighbors(t, vertex), collect(levels[i - 1]))))

        if isempty(levels[i]) break end

        i += 1
    end

    res = Array{Set{Int}}(undef, i - 1)
    for i in 1:length(res)
        res[i] = levels[i]
    end

    return res
end

function find_feg_separator_lt(skeleton::LabeledGraph{T}, faces::Set{Set{Pair{T, T}}})::Tuple{Set{T}, Set{T}, Set{T}} where {T}
    g = copy(skeleton)
    
    for face in faces
        face_vertices = reduce((x, y) -> union!(x, Set([y.first, y.second])), face, init=Set{Number}())
        for edge in face
            for dest in face_vertices
                if (edge.first != dest)
                    lg_add_edge!(g, edge.first, dest)
                end
            end
        end
    end

    # println(collect(LightGraphs.edges(g.graph)))

    g_star_star = copy(skeleton)
    new_vertices = Dict{Number, Set{Pair{T, T}}}()
    for face in faces
        new_vertex = rand(Int64)
        push!(new_vertices, new_vertex => face)
        lg_add_vertex!(g_star_star, new_vertex)
        for edge in face
            lg_add_edge!(g_star_star, edge.first, new_vertex)
        end
    end

    # println(collect(LightGraphs.edges(g_star_star.graph)))

    (c_star_star, a_star_star, b_star_star) = find_separator_lt(g_star_star, 1)

    a = filter(vertex -> !(vertex in keys(new_vertices)), a_star_star)
    b = filter(vertex -> !(vertex in keys(new_vertices)), b_star_star)

    for pair in new_vertices
        if (pair.first in c_star_star)
            bad_face_vertecies =  reduce((x, y) -> union!(x, Set([y.first, y.second])), pair.second, init=Set{Number}())

            a_star_star_boundry = filter(vertex -> vertex in a_star_star, bad_face_vertecies)
            b_star_star_boundry = filter(vertex -> vertex in b_star_star, bad_face_vertecies)
            
            if length(a_star_star_boundry) < length(b_star_star_boundry)
                setdiff!(a, a_star_star_boundry)
            else
                setdiff!(b, b_star_star_boundry)
            end
        end
    end

    return (setdiff(lg_vertices(g), a, b), a, b)
end