using DataFrames

function getColumnValues(dfTable, column)
    return convert(Array,sort(levels(dfTable[column])));
end;

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
end;

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
end;

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
end;

function treeDistance(df,attribute)
    term1 = I_Pc(df)/I_Pc_inter_PAi(df, attribute)
    term2 = I_PAi(df, attribute)/I_Pc_inter_PAi(df, attribute)
    return 2 - term1 - term2
end;

