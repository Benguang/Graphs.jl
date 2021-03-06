# The Bellman Ford algorithm for single-source shortest path

###################################################################
#
#   The type that capsulates the states of Bellman Ford algorithm
#
###################################################################

mutable struct NegativeCycleError <: Exception end

mutable struct BellmanFordStates{V,D<:Number}
    parents::Vector{V}
    parent_indices::Vector{Int}
    dists::Vector{D}
end

# create Bellman Ford states

function create_bellman_ford_states(g::AbstractGraph{V}, ::Type{D}) where {V,D<:Number}
    n = num_vertices(g)
    parents = Array{V}(undef, n)
    parent_indices = zeros(Int, n)
    dists = fill(typemax(D), n)

    BellmanFordStates(parents, parent_indices, dists)
end

function bellman_ford_shortest_paths!(
    graph::AbstractGraph{V},
    edge_dists::AbstractEdgePropertyInspector{D},
    sources::AbstractVector{V},
    state::BellmanFordStates{V,D}) where {V,D}

    @graph_requires graph incidence_list vertex_map vertex_list
    edge_property_requirement(edge_dists, graph)


    active = Set{V}()
    for v in sources
        i = vertex_index(v, graph)
        state.dists[i] = 0
        state.parents[i] = v
        state.parent_indices[i] = i
        push!(active, v)
    end
    no_changes = false
    for i in 1:num_vertices(graph)
        no_changes = true
        new_active = Set{V}()
        for u in active
            uind = vertex_index(u, graph)
            for e in out_edges(u, graph)
                v = target(e, graph)
                vind = vertex_index(v, graph)
                edist = edge_property(edge_dists, e, graph)
                if state.dists[vind] > state.dists[uind] + edist
                    state.dists[vind] = state.dists[uind] + edist
                    state.parents[vind] = u
                    state.parent_indices[vind] = vertex_index(u, graph)
                    no_changes = false
                    push!(new_active, v)
                end
            end
        end
        if no_changes
            break
        end
        active = new_active
    end
    if !no_changes
        throw(NegativeCycleError())
    end
    state
end


function bellman_ford_shortest_paths(
    graph::AbstractGraph{V},
    edge_dists::AbstractEdgePropertyInspector{D},
    sources::AbstractVector{V}) where {V,D}
    #
    state = create_bellman_ford_states(graph, D)
    bellman_ford_shortest_paths!(graph, edge_dists, sources, state)
end

function bellman_ford_shortest_paths(
    graph::AbstractGraph{V},
    edge_dists::Vector{D},
    sources::AbstractVector{V}) where {V,D}
    edge_inspector = VectorEdgePropertyInspector{D}(edge_dists)
    bellman_ford_shortest_paths(graph, edge_inspector, sources)
end

function has_negative_edge_cycle(
    graph::AbstractGraph{V},
    edge_dists::AbstractEdgePropertyInspector{D}) where {V, D}
    try
        bellman_ford_shortest_paths(graph, edge_dists, vertices(graph))
    catch e
        if isa(e, NegativeCycleError)
            return true
        end
    end
    return false
end

function has_negative_edge_cycle(
    graph::AbstractGraph{V},
    edge_dists::Vector{D}) where {V, D}
    edge_inspector = VectorEdgePropertyInspector{D}(edge_dists)
    has_negative_edge_cycle(graph, edge_inspector)
end
