
function callDistance(instances, attributes)
    columns = map((x) -> string(x), names(train))
    distances = []
    df = train[instances, :]
    for i in 1:length(attributes)
        col = find(columns .== attributes[i])
        push!(distances, treeDistance(df, col[1]))
    end
    return distances
end

type TreeNode
    parent::Int # posição no vetor de nós
    value::String # "atributo_valor"
    instances::Vector{Int} # instancias
    children::Vector{Int} # posições no vetor de nós
end

type Tree
    nodes::Vector{TreeNode}
end

# instances = vetor de instancias
# parent = pai do nó, 1 para raíz
# q = parametro de qtd de instancias aceitavel
function growTree(instances, parent, q)
    if(parent ==  1) # é raiz
        push!(tree.nodes, TreeNode(0, "root", instances, []))
    end
    if(length(instances) < q) 
        return ""
    end
    # retorna um vetor de distancias com a ordem de atributos do header
    distances = callDistance(instances, attributes)
    indexs = sortperm(distances) # retorna os indexs do menor valor ao maior
    if(distances[indexs[1]] == 1.0)
        return "" 
    end
    attr = attributes[indexs[1]] 
    deleteat!(attributes, find(attributes .== attr)) #deleta o atributo da lista de atributos
    df = train[instances, :]
    groups = by(df, parse(attr), nrow)
    for i in 1:nrow(groups)
        value = string(attr, "_", groups[i, 1])
        ids = find(df[parse(attr)] .== groups[i, 1])
        new_instances = instances[ids]
        push!(tree.nodes, TreeNode(parent, value, new_instances, []))
        new_node = length(tree.nodes)
        push!(tree.nodes[parent].children, new_node)
        growTree(new_instances, new_node, q)
    end
    return ""
end
