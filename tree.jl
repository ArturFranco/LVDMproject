using DataFrames

#### DISTANCIA
function getColumnValues(dfTable, column)
    return convert(Array,sort(levels(dfTable[column])));
end

function I_Pc(df)
    classes = getColumnValues(df,ncol(df))
    result = 0
    rows = nrow(df);
    cols = ncol(df);
    for class in classes
        Pj = nrow(df[df[cols].== class,:])/rows
        #print(Pj)
        if(Pj != 0)
            result += Pj*log2(Pj)
        end
    end
    return -result
end

function I_PAi(df,attribute)
    values = getColumnValues(df,attribute)
    result = 0
    rows = nrow(df);
    cols = ncol(df);
    for value in values
        PAi = nrow(df[df[attribute].== value,:])/rows
        #print(Pj)
        if(PAi != 0)
            result += PAi*log2(PAi)
        end
    end
    return -result

end

function I_Pc_inter_PAi(df, attribute)
    classes = getColumnValues(df,ncol(df))

    rows = nrow(df)
    cols = ncol(df)
    result = 0

    for class in classes
        values = getColumnValues(df,attribute)
        dfClass = df[df[cols].== class,:]
        classRows = nrow(dfClass)
        Pj = classRows/rows
        for value in values
            Pij = (nrow(dfClass[dfClass[attribute].== value,:])/classRows)*Pj
            if(Pij != 0)
                result += Pij*log2(Pij)
            end
        end
    end
    return - result
end

function treeDistance(df,attribute)
    term1 = I_Pc(df)/I_Pc_inter_PAi(df, attribute)
    term2 = I_PAi(df, attribute)/I_Pc_inter_PAi(df, attribute)
    return 2 - term1 - term2
end

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

####### ÁRVORE
type TreeNode
    parent::Int # posição no vetor de nós
    value::String # "atributo_valor"
    instances::Vector{Int} # instancias
    children::Vector{Int} # posições no vetor de nós
end

type Tree
    nodes::Vector{TreeNode}
end

# criação da árvore global
tree = Tree([])

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
        return "" #sem filho? ou seja, folha
    end
    attr = attributes[indexs[1]] #pega o atributo
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

## MAIN
train = readtable("db.csv", separator = ',')
# lista de atributos que vai ser modificada conforme a árvore vai sendo construida
attributes = map((x) -> string(x), names(train))
attributes = attributes[1:(length(attributes) - 1)]
q = 4
instances = collect(1:1:nrow(train))
growTree(instances, 1, q)

println("Árvore: ")
for i in 1:length(tree.nodes)
    println(tree.nodes[i])
end