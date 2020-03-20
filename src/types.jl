struct LabeledGraph{T}
    graph::LightGraphs.AbstractGraph
    labels::Dict{T, Int}
end

function LabeledGraph(g::LightGraphs.AbstractGraph)
    return LabeledGraph(g, Dict(i => i for i = LightGraphs.vertices(g)))
end

Base.copy(lg::LabeledGraph) = LabeledGraph(copy(lg.graph), copy(lg.labels))

function convert_vertices(labels::Dict{T, Int}, vertices) where {T}
    rev = _reverse_labels(labels)
    map(vertex -> rev[vertex], vertices)
end

function lg_rem_vertex!(lg::LabeledGraph{T}, v::T)::Bool where {T}
    rev = _reverse_labels(lg.labels)

    n = lg.labels[v]
    last = rev[LightGraphs.nv(lg.graph)]
    lg.labels[last] = n
    delete!(lg.labels, v)
    return LightGraphs.rem_vertex!(lg.graph, n)
end

function lg_add_vertex!(lg::LabeledGraph{T}, v::T)::Bool where {T}
    lg.labels[T] = LightGraphs.nv(lg.graph) + 1
    return LightGraphs.add_vertex!(lg.graph)
end

function lg_add_edge!(lg::LabeledGraph{T}, x::T, y::T)::Bool where {T}
    return LightGraphs.add_edge!(lg.labels[x], lg.labels[y])
end

function _reverse_labels(labels::Dict{K, V})::Dict{V, K} where {K, V}
    return Dict(value => key for (key, value) in labels)
end
