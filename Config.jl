using Pkg

Pkg.add("CSV")
Pkg.add("Gtk")
Pkg.add("DataFrames")
Pkg.add("StringEncodings")
Pkg.add("Dates")
Pkg.add("DBFTables")
Pkg.add("XLSX")
println("foi")
include("pacs/fun.jl")
using .fun

Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Teste.csv"
path0 = fun.get_os_dir(Local)


if isdir(path0) == false # verifica se uma pasta existe
    mkpath(path0) # cria uma pasta se ela não exite
    println("Diretório $path0 foi criado")
end

Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\Teste.csv"
path0 = fun.get_os_dir(Local)


if isdir(path0) == false # verifica se uma pasta existe
    mkpath(path0) # cria uma pasta se ela não exite
    println("Diretório $path0 foi criado")
end

Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Duplicidade\\Teste.csv"
path0 = fun.get_os_dir(Local)


if isdir(path0) == false # verifica se uma pasta existe
    mkpath(path0) # cria uma pasta se ela não exite
    println("Diretório $path0 foi criado")
end
