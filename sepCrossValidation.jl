using DataFrames

bds = ["db_tictactoe"];
k = 5
for bd in bds
    df = readtable(string(bd,".data"), separator = ',',header=false)
    srand(nrow(df))
    df[:id] = rand(nrow(df))

    df = sort(df,cols=[:id])
    delete!(df,:id)
    rows = ceil(nrow(df)/k)

    for i in 1:k
        if (i != k)
            interval = Int32(i*rows-rows+1):Int32(i*rows)
            #print(interval)
            writetable(string("bds//",bd,"_",i,".csv"),df[interval,:],separator=',',header=false)
        else
            interval = Int32(i*rows-rows+1):Int32(nrow(df))
            writetable(string("bds//",bd,"_",i,".csv"),df[interval,:],separator=',',header=false)
        end
        #print(interval)
    end

end
