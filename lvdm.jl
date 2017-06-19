# EXECUTAR:
# Entrar na pasta do projeto pelo terminal;
# Abrir julia;
# include("lvdm.jl")
using DataFrames
include("./distance.jl");
include("./tree.jl");

# df = dataframe of DB
# class = class column number starting from 1
# return = dataframe with class colunm as the last column of df
function prettyDf(df, class)
    df[:Class] = df[class]
    delete!(df, class)
    return df
end;

# db = DB dataframe
# p = separation percentage for train dataframe
function train_test(df, p)
    rows, cols = size(df)
    limA = Int(floor(rows*p))
    train = df[1:limA,:]
    test = df[limA+1:rows,:]
    return train, test
end;

# df = dataframe with grouped by class neighbors and count column
# return = class of tested instance
function classifier(df)
    result = sort(df, cols = :Count)
    rows, cols = size(result)
    return result[rows, :Class]
end;

# k = n neighbor(s)
# a = distance array
# train = train dataframe
# flag = true if Weighted kNN
# return = DataFrame with neighbors classes
function findNeighbors(k, a, train, flag)
    indexs = sortperm(a)
    trows, tcols = size(train)
    neighbors = DataFrame(Class = typeof(train[1, tcols])[])
    if(flag)
        neighbors[:w] = 0.0
        for i in 1:size(indexs[range(1, k)], 1)
            weight = 1/(a[indexs[i]] * a[indexs[i]])
            push!(neighbors, [train[indexs[i], tcols], weight] )
        end
        neighbors1 = by(neighbors, :Class, d -> DataFrame(Count=sum(d[:w])))
    else
        for i in 1:size(indexs[range(1, k)], 1)
            push!(neighbors, [train[indexs[i], tcols]])
        end
        neighbors1 = by(neighbors, :Class, d -> DataFrame(Count=nrow(d)))
    end
    return neighbors1
end;

# train = train dataframe
# return = dataframe with all instances quantity given the classes
function createTable(train)
    rows, cols = size(train)
    attr_names = names(train)
    df_class = groupby(train, :Class)
    len = length(df_class)
    table = DataFrame(Attr = String[], Class = String[], Nic = Int[])
    for i in 1:(cols-1) #loop through attributes
        for c in 1:len #loop through classes
            df = df_class[c]
            class_name = df[1, :Class]
            df_attribute_class = by(df, i, d -> DataFrame(Count=nrow(d)))
            for row in eachrow(df_attribute_class)
                row_name = string(attr_names[i], "_", row[1])
                n = row[:Count]
                push!(table, [row_name, class_name, n])
            end
        end
    end
    df = by(table, 1, d -> DataFrame(Ni=sum(d[:Nic])))
    table[:Prob] = 0.0
    for i in 1:size(df, 1)
        for row in eachrow(table)
            if(df[i, :Attr] == row[:Attr])
                row[:Prob] = (row[:Nic])/(df[i, :Ni])
                if(row[:Prob] > 1)
                    println("erro!")
                end
            end
        end
    end
    delete!(df, [:Attr, :Ni])
    delete!(table, :Nic)
    for row in eachrow(table)
        row[:Attr] = string(row[:Attr], "_", row[:Class])
    end
    delete!(table, :Class)
    return table
end;

# train = train dataset
# T = local tree
# q = predeterminated parameter (= 30)
# x = train instance
# y = test instance
# return = LVDM distance of two instances (x,y) and neighbors of y
function LVDM(train, T, q, x, y)
    vet = searchTree(train, T, q, y)
    df = train[vet,:]
    table = createTable(df)
    distance = VDM(df, table, x, y)
    return distance
end;

# a = train instance
# b = test instance
# return = OM distance of two instances (a, b)
function OM(a, b)
    result = 0
    for i in 1:(ncol(a)-1) #loop through attributes
        if(a[1, i] != b[1, i])
            result = result + 1
        end
    end
    return result
end;

# train = train dataframe
# table = probabilities dataframe
# a = train instance
# b = test instance
# return = VDM distance of two instances (a,b)
function VDM(train, table, a, b)
    rows, cols = size(train)
    class_names = levels(train[cols])
    attr_names = names(train)
    result = 0
    for i in 1:(cols-1) #loop through attributes
        s = 0.0
        for c in 1:length(class_names) #loop through classes
            ra = string(attr_names[i], "_", a[1, i], "_", class_names[c])
            rb = string(attr_names[i], "_", b[1, i], "_", class_names[c])
            Piac, Pibc = 0.0, 0.0
            flaga, flagb = true, true
            for row in eachrow(table)
                if(ra == row[:Attr] && flaga)
                    Piac = row[:Prob]
                    flaga = false
                end
                if(rb == row[:Attr] && flagb)
                    Pibc = row[:Prob]
                    flagb = false
                end
                if(!flaga && !flagb)
                    break
                end
            end
            #println("Piac: ", Piac, " Pibc: ", Pibc)
            sub = Piac - Pibc
            s = s + (sub * sub)
        end
        result = result + s
    end
    result = sqrt(result)
    return result
end;

# k = neighbor(s)
# train = train dataframe
# test = test dataframe
# flag = true if Weighted kNN
# dist = distance function (VDM, OM or LVDM)
# return = classes of the test instances
function kNN(k, train, test, flag, dist, T)
    trows, tcols = size(test)
    rows, columns = size(train)
    classes = Array(String, trows)
    if(dist == "VDM")
        table = createTable(train)
        for j in 1:trows
            distances = Array(Float32, rows)
            for i in 1:rows
                distances[i] = VDM(train, table, train[i,:], test[j,:])
            end
            neighbors = findNeighbors(k, distances, train, flag)
            classes[j] = classifier(neighbors)
        end
    elseif(dist == "OM")
        for j in 1:trows
            distances = Array(Float32, rows)
            for i in 1:rows
                distances[i] = OM(train[i,:], test[j,:])
            end
            neighbors = findNeighbors(k, distances, train, flag)
            classes[j] = classifier(neighbors)
        end
    else #LVDM
        q = 30
        tree = Tree([])
        instances = collect(1:1:nrow(train))
        println("Construindo árvore...")
        @time(growTree(tree, instances, 1, q))
        println("Árvore construida!")
        #perguntar disso aqui
        for j in 1:trows
            distances = Array(Float32, rows)
            for i in 1:rows
                distances[i] = LVDM(train, tree, q, train[i,:], test[j,:])
            end
            neighbors = findNeighbors(k, distances, train, flag)
            classes[j] = classifier(neighbors)
        end
    end
    return classes
end;

function joinBds(name,test)
    flag = 0
    train = NA
    for i in (1:5)
        if (i != test)

            if (flag != 0)
                aux = readtable(string("bds//",name,"_",i,".csv"),separator = ',', header = false);
                train = vcat(train,aux);
            else
                train = readtable(string("bds//",name,"_",i,".csv"),separator = ',', header = false);
            end
            flag = 1
        end
    end
    test = readtable(string("bds//",name,"_",test,".csv"),separator = ',', header = false);
    return train, test;
end;

######################################
#                Main                #
######################################
println("\n\n** INÍCIO RUN TEST **")

bds = ["db_tictactoe"]

dists = ["OM"]

#inicializando vetor de acuracia
accuracy = Vector(length(bds))
aux = Vector(length(dists))
for i in (1:length(dists))
    aux[i] = Vector(5)
end
for i in (1:length(accuracy))
    accuracy[i] = aux
end

k = 10
for bd in (1:length(bds))
    for i in (1:5)
        train, test = joinBds(bds[bd],i)
        train = prettyDf(train, ncol(train)) #Put "Class" column on DF
        test = prettyDf(test, ncol(test)) #Put "Class" column on DF
        attributes = map((x) -> string(x), names(train))
        attributes = attributes[1:(length(attributes) - 1)] #Take out the class

        for dist in (1:length(dists))
            tree = NA
            if (dists[dist] == "LVDM")
                tree = Tree([])
                attrs = copy(attributes)
                q = 4
                instances = collect(1:1:nrow(train))
                growTree(tree,train,instances, 1, q, attrs)
            end
            classes1 = @time(kNN(k, train, test, true, dists[dist], tree))
            accuracy1 = mean(classes1 .== test[ncol(test)])
            accuracy[bd][dist][i] = accuracy1
        end
    end
end

# train = readtable("db_train.csv", separator = ',', header = false)
# test = readtable("db_test.csv", separator = ',', header = false)
# train = prettyDf(train, ncol(train)) #Put "Class" column on DF
# test = prettyDf(test, ncol(test)) #Put "Class" column on DF
# attributes = map((x) -> string(x), names(train))
# attributes = attributes[1:(length(attributes) - 1)] #Take out the class
# k = 10
# classes1 = @time(kNN(k, train, test, true, "VDM", 0)) #0.85
# accuracy1 = mean(classes1 .== test[ncol(test)])
# classes2 = @time(kNN(k, train, test, true, "OM", 0))
# accuracy2 = mean(classes2 .== test[ncol(test)])
# tree = Tree([]) #Create global tree
# classes3 = @time(kNN(k, train, test, false, "LVDM"))
# accuracy3 = mean(classes3 .== test[ncol(test)])
# open("result.txt", "w") do f
#     write(f, accuracy)
# end
# println("Árvore: ")
# for i in 1:length(tree.nodes)
#     println(tree.nodes[i])
# end
#
# ########## TEST ####################################################################################
# # criação da árvore global
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
# ####################################################################################################
