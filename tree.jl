# instances = vector of instances
# attributes = list of attributes
# return = vector with all DN distances
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
function growTree(instances, parent, q)
    if(parent ==  1) # é raiz
        push!(tree.nodes, TreeNode(0, "root", instances, []))
    end
    if(length(instances) < q || length(attributes) == 0) #verificar isso aqui :)
        return ""
    end
    distances = callDistance(instances, attributes) # distances vector
    indexs = sortperm(distances) # return lowest value to highest value indexs
    if(distances[indexs[1]] == 1.0)
        return "" 
    end
    attr = attributes[indexs[1]]
    deleteat!(attributes, find(attributes .== attr)) # delete attribute from global attributes list
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

# tree = global tree
# y = test instance
# q = predeterminated parameter
function searchTree(y, q)
    return [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
end
