# instances = vector of instances
# attributes = list of attributes
# return = vector with all DN distances
function callDistance(train, instances, attributes)
    columns = map((x) -> string(x), names(train))
    distances = []
    df = train[instances, :]
    for i in 1:length(attributes)
        col = find(columns .== attributes[i])
        push!(distances, treeDistance(df, col[1]))
    end
    return distances
end;

type TreeNode
    parent::Int # vector ID of parent node
    value::String # "attribute_value"
    instances::Vector{Int}
    children::Vector{Int} # vector IDs of children nodes
end

type Tree
    nodes::Vector{TreeNode}
end

# tree = global tree
# attributes = global attributes
# instances = vector of instances
# parent = parent of the node, 1 for root
# q = predeterminated parameter
# return = return nothing but update global tree
function growTree(tree, train,instances, parent, q, attributes)
    if(parent ==  1) # é raiz
        push!(tree.nodes, TreeNode(0, "root", instances, []))
    end
    if(length(instances) < q || length(attributes) == 0)
        return ""
    end
    distances = callDistance(train,instances, attributes) # distances vector
    indexs = sortperm(distances) # return lowest value to highest value indexs
    if(distances[indexs[1]] == 1.0)
        return ""
    end
    attr = attributes[indexs[1]]
    df = train[instances, :]
    groups = by(df, parse(attr), nrow)
    for i in 1:nrow(groups)
        deleteat!(attributes, find(attributes .== attr)) # delete attribute from global attributes list
        value = string(attr, "_", groups[i, 1])
        ids = find(df[parse(attr)] .== groups[i, 1])
        new_instances = instances[ids]
        push!(tree.nodes, TreeNode(parent, value, new_instances, []))
        new_node = length(tree.nodes)
        push!(tree.nodes[parent].children, new_node)
        growTree(tree, train,new_instances, new_node, q, copy(attributes))
    end
    return ""
end;

# tree = global tree
# y = test instance
# q = predeterminated parameter
function searchTree(train, Tree, q, y)

    columns = map((x) -> string(x), names(train))

    children = Tree.nodes[1].children
    flag = 1
    result = Any
    parent = 1
    while (flag == 1)
        aux = Any
        try
            aux = split(Tree.nodes[children[1]].value,'_')[1]
            #println(aux)
        catch
            result = Tree.nodes[parent].instances
            if (length(result) < q)
                result = Tree.nodes[Tree.nodes[parent].parent].instances
            end
            flag = 0
        end
        if (flag != 0)
            value = y[1,parse(aux)]
            i = 0
            for child in children
                if (Tree.nodes[child].value == string(aux,"_",value))
                    i = child
                    break
                end
            end
            if (i == 0)
                result = Tree.nodes[parent].instances
                flag = 0
            end
            parent = i
            if (i != 0)
                children = Tree.nodes[i].children
            end
        end
    end
    return result
end;

# tree = Tree([])
# train = readtable("db.csv", separator = ',', header = false)
# # lista de atributos que vai ser modificada conforme a árvore vai sendo construida GLOBAL
# attributes = map((x) -> string(x), names(train))
# attributes = attributes[1:(length(attributes) - 1)] #tira classe
# attrs = copy(attributes)
# q = 4
# instances = collect(1:1:nrow(train))
# growTree(tree,train,instances, 1, q, attrs)
#
# println("Árvore: ")
# for i in 1:length(tree.nodes)
#     println(tree.nodes[i])
# end
#
# aux = train[1,:]
# aux[1,1] = "chuva"
# aux[1,2] = "normal" # não usa
# aux[1,3] = "elevada"
# aux[1,4] = "forte"
# print(aux)
# vet = searchTree(train,tree, 2, aux)
# println(vet)
# parent::Int # vector ID of parent node
# value::String # "attribute_value"
# instances::Vector{Int}
# children::Vector{Int} # vector IDs of children nodes
