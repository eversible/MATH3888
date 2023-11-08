using Graphs
using MetaGraphsNext
using GraphPlot

"""
first interaction graph of g
"""
function successor(g::AbstractGraph)::DiGraph

    E₀ = vertices(g)
    E₁ = edges(g)
    if is_directed(g)
        E₂ = vcat([[(e, Edge(dst(e), v)) for v in neighbors(g, dst(e))] for e in E₁]...)
    else
        E₂ = vcat([[(e, Edge(dst(e), v)) for v in neighbors(g, dst(e)) if v ≠ src(e)] for e in E₁]...)
    end

    mg = MetaGraph(
        DiGraph(),
        label_type = Edge
    )

    add_vertex!.(Ref(mg), E₁)

    for (f, e) ∈ E₂
        add_edge!(mg, f, e)
    end

    mg.graph
end
succ = successor

"""
necessary graph before a first interaction graph;
successor(predecessor(E)) == E iff E is the first interaction graph of some graph.
"""
function predecessor(g::AbstractGraph)::DiGraph
    
    E₁ = vertices(g)
    E₂ = edges(g)

    created_vertices = 0
    edge_assignment = Dict(e => Edge(created_vertices += 1, created_vertices += 1) for e ∈ E₁)
    
    glued_vertices = Dict{Int, Int}()
    glued_vertex_names = 0

    for fe ∈ E₂
        s = fe.src
        u = edge_assignment[s].dst
        d = fe.dst
        v = edge_assignment[d].src

        if haskey(glued_vertices, u)
            glued_vertices[edge_assignment[d].src] = glued_vertices[u]
        elseif haskey(glued_vertices, v)
            glued_vertices[edge_assignment[s].dst] = glued_vertices[v]
        else
            glued_vertices[u] = glued_vertex_names += 1
            glued_vertices[v] = glued_vertex_names
        end
    end

    for w ∈ 1:created_vertices
        haskey(glued_vertices, w) || (glued_vertices[w] = (glued_vertex_names += 1))
    end

    SimpleDiGraphFromIterator(Edge(glued_vertices[e.src], glued_vertices[e.dst]) for e ∈ values(edge_assignment))
end
pred = predecessor


# convenience functions, e.g. g + 5 or g + 1 - 1
import Base: +, -
+(g::AbstractGraph, n::Int) = n == 0 ? g : n > 0 ? ∘(repeat([succ], n)...)(g) : ∘(repeat([pred], -n)...)(g)
-(g::AbstractGraph, n::Int) = g + (-n)


# example graph which is not a first interaction graph as observed in the report:
E = DiGraph(4)
add_edge!(E, 1, 4)
add_edge!(E, 4, 1)
add_edge!(E, 1, 2)
add_edge!(E, 2, 3)
add_edge!(E, 3, 4)

E₋ = pred(E)
E₋₊ = succ(E₋)

E == E₋₊ #* returns FALSE