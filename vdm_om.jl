# TO EXECUTE:
# cd("this file and BDs files directory path")
# include("questao_1.jl")

# Pkg.add("PyCall")
using DataFrames
using Gadfly
using PyCall

#função pra testar o retorno no python
function sum(x, y)
    return x+y
end

# df = dataframe of DB
# class = class column number starting from 1
# return = dataframe with class colunm as the last column of df
function prettyDf(df, class)
    df[:Class] = df[class]
    delete!(df, class)
    return df
end

# db = DB dataframe 
# p = separation percentage for train dataframe
function train_test(df, p)
    rows, cols = size(df)
    limA = Int(floor(rows*p))
    train = df[1:limA,:]
    test = df[limA+1:rows,:]
    return train, test
end

# df = dataframe with grouped by class neighbors and count column
# return = class of tested instance
function classifier(df)
    result = sort(df, cols = :Count)
    rows, cols = size(result)
    return result[rows, :Class]
end

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
end

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
end

# a = train instance
# b = test instance
function OM(a, b)
    result = 0
    for i in 1:(cols(a)-1) #loop through attributes
        if(a[1, i] != b[1, i])
            result = result + 1
    end
    return result
end

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
end

# k = neighbor(s)
# train = train dataframe
# test = test dataframe
# flag = true if Weighted kNN
# return = classes of the test instances
function kNN(k, train, test, flag)
    trows, tcols = size(test)
    rows, columns = size(train)
    classes = Array(String, trows)
    table = createTable(train)
    for j in 1:trows
        distances = Array(Float32, rows)
        for i in 1:rows
            distances[i] = VDM(train, table, train[i,:], test[j,:])
        end
        neighbors = findNeighbors(k, distances, train, flag)
        classes[j] = classifier(neighbors)
    end
    return classes
end


######################################
#                Main                #
######################################
# println("** INICIO JULIA **")
# train = readtable("db_train.csv", ',', header = false)
# test = readtable("db_test.csv", ',', header = false)
# train = prettyDf(train, cols(train)) #Put "Class" column on DF
# test = prettyDf(test, cols(test)) #Put "Class" column on DF
# k = 10
# classes = @time(kNN(k, train, test, false))
# accuracy = mean(classes .== test[cols(test)])
# open("result.txt", "w") do f
#     write(f, accuracy)
# end
# println("Acurária: " + accuracy)
# println("** FIM JULIA **")