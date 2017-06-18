import numpy as np
import pandas as pd
#pip install --user julia #installing julia module without root access


# I(Pc), I(Pai), I(Pc ^ Pai)

def I_Pc(dataset):
    classes = np.array(dataset['classe'].unique()) # taking dataset classes
    result = 0
    for classe in classes:
        Pj = float(dataset[dataset['classe'] == classe].shape[0])/dataset.shape[0]
        if Pj != 0:
            result += Pj*np.log2(Pj)
    return -result

def I_PAi(dataset, attribute):
    attr_values = np.array(dataset[attribute].unique()) # taking possible attribute values
    result = 0
    for value in attr_values:
        Pi = float(dataset[dataset[attribute] == value].shape[0])/dataset.shape[0]
        if Pi != 0:
            result += Pi*np.log2(Pi)    
    return -result

def I_Pc_inter_PAi(dataset, attribute):
    classes = np.array(dataset['classe'].unique()) # taking dataset classes
    result = 0
    for classe in classes:
        attr_values = np.array(dataset[attribute].unique()) # taking possible attribute values
        df_classe = dataset[dataset['classe'] == classe]
        Pj = float(df_classe.shape[0])/dataset.shape[0] 
        for value in attr_values:
            # P(Ai inter C) = P(Ai|C)*P(C)
            Pij = (float(df_classe[df_classe[attribute] == value].shape[0])/df_classe.shape[0])*Pj
            if Pij != 0:
                result += Pij*np.log2(Pij)
    return -result

def treeDistance(dataset, attribute):
    term1 = I_Pc(dataset)/I_Pc_inter_PAi(dataset, attribute)
    term2 = I_PAi(dataset, attribute)/I_Pc_inter_PAi(dataset, attribute)
    return 2 - term1 - term2

### MAIN
exemplo = pd.read_csv('db.csv',header=None)

exemplo.columns = ['aspecto','temperatura','humidade','vento','classe']
print(I_Pc(exemplo))
print(I_PAi(exemplo,'aspecto'))
print(I_Pc_inter_PAi(exemplo,'aspecto'))
print(treeDistance(exemplo,'aspecto'))
attributes = exemplo.columns
print(exemplo)
attributes = attributes[:-1]
distances = {}
aux = []
for attribute in attributes:
    distances[attribute] = treeDistance(exemplo, attribute)
    aux.append(treeDistance(exemplo, attribute))
aux.sort()
print(distances)
print(aux)

df1 = exemplo.iloc[[3,4,5,9,13]]
print(df1)
attributes = ['temperatura','humidade','vento']
distances = {}
aux = []
for attribute in attributes:
    distances[attribute] = treeDistance(df1, attribute)
    aux.append(treeDistance(df1, attribute))
aux.sort()
print(distances)
print(aux)



#df1 = exemplo.iloc[[0,1,7,8,10]]
#df2 = exemplo.iloc[[2,6,11,12]]
#df3 = exemplo.iloc[[3,4,5,9,13]]

#Calling Julia inside Python
# import julia
# j = julia.Julia()
# # j.include("vdm_om.jl")
