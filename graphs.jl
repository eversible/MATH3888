using Graphs
using MetaGraphsNext
using GraphPlot

# g = complete_digraph(4)

# only consider directed graph ?
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

    # for e ∈ E₁
    #     mg[e] = nothing
    # end
    add_vertex!.(Ref(mg), E₁)

    for (f, e) ∈ E₂
        add_edge!(mg, f, e)
    end

    mg.graph
end
succ = successor

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
        println("$s, $d")
        println("$u, $v")

        if haskey(glued_vertices, u)
            glued_vertices[edge_assignment[d].src] = glued_vertices[u]
        elseif haskey(glued_vertices, v)
            glued_vertices[edge_assignment[s].dst] = glued_vertices[v]
        else
            glued_vertices[u] = glued_vertex_names += 1
            glued_vertices[v] = glued_vertex_names
            #! WRONG !# :
            # glued_vertices[u] = u
            # glued_vertices[v] = u
        end
        println(glued_vertices)
    end

    for w ∈ 1:created_vertices
        haskey(glued_vertices, w) || (glued_vertices[w] = (glued_vertex_names += 1))
    end

    SimpleDiGraphFromIterator(Edge(glued_vertices[e.src], glued_vertices[e.dst]) for e ∈ values(edge_assignment))
end
pred = predecessor

import Base: +, -

+(g::AbstractGraph, n::Int) = n == 0 ? g : n > 0 ? ∘(repeat([succ], n)...)(g) : ∘(repeat([pred], -n)...)(g)
-(g::AbstractGraph, n::Int) = g + (-n)