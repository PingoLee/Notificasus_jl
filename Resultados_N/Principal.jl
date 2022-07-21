module Principal     
    path0 = relpath((@__DIR__)*"/..","A:/")    
    include(path0 * "/Funções.jl")
    using .Funções
    using CSV
    using DataFrames
    using StringEncodings
    using Dates
    using DBFTables
    using XLSX
    #using DBFTables

    function Processar()
        # Processa os casos no notifica que não foram laçados da planilha do coe
        
        dfCom = DataFrame(CSV.File(open(read, pwd() * "\\Resultados_N\\Comorbidades.csv", enc"windows-1252"), delim=";"))

        # importa o COE
        Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\COECONF.xlsx"
        if isfile(Local)
            dfCOE = DataFrame(XLSX.readtable(Local, "CONFIRMADOS")...)
        else
            return "A planilha do COE não foi baixada ou não esta com o nome correto", "Erro, não processado"
        end      

        Colunas = ["LIBERAÇÃO EXAME", "Nº REQUISIÇÃO GAL", "Nº NOTIFICAÇÃO", "NOME", "CNS/CPF", "DN", "UNIDADE NOTIFICADORA", "METODOLOGIA"]

        if issubset(Colunas, names(dfCOE)) == false
            return "A planilha do COE teve o títulos das colunas modificados", "Erro, não processado"
        end

                
        dfCOE = select(dfCOE, ["LIBERAÇÃO EXAME", "Nº REQUISIÇÃO GAL", "Nº NOTIFICAÇÃO", "NOME", "CNS/CPF", "DN", "UNIDADE NOTIFICADORA", "METODOLOGIA"])
        dfCOE."Nº NOTIFICAÇÃO" = map(x -> ismissing(x) ? missing : strip(string(x)), dfCOE."Nº NOTIFICAÇÃO")
        #dfCOE = filter("Nº NOTIFICAÇÃO" => x -> ismissing(x) ? false : contains(x, "-2021"), dfCOE)
      
        # Coloca o metaphone
        col = ncol(dfCOE)
        insertcols!(dfCOE, col + 1, "metaphone" => "")

        for i = 1: nrow(dfCOE)
            if ismissing(dfCOE[i, :DN]) == false && (isa(dfCOE[i, :DN], DateTime) || isa(dfCOE[i, :DN], Date))  && ismissing(dfCOE[i, "NOME"]) == false            
                dfCOE[i, :metaphone] = string(Funções.MetaPTBR(dfCOE[i, "NOME"], 20), Dates.format(dfCOE[i, :DN], "yyyy-mm-dd"))
            end
        end

        if false
            Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\dfCOE.csv"

            open(Local, "w") do io
                CSV.write(io, dfCOE, delim=";")
            end  
        end
          

        # importa notifica
        dfNOT = DataFrame(XLSX.readtable("C:\\Bancos\\Notificasus\\Covid\\BDs\\notifica.xlsx", 1)...)


        select!(dfNOT, ["num_notificacao", "nome_unidade", "data_notificacao", "cartao_sus", "cpf", "nome_paciente", "idade_anos_dt_notific",
                        "data_nascimento", "sexo", "municipio_paciente", "bairro", "logradouro", "endereco_outra_cidade", 
                        "quadra", "lote", "pais", "telefone", "telefone_2", "telefone_3", "comorb_pulm", "comorb_cardio", "comorb_renal", 
                        "comorb_hepat", "comorb_diabe", "comorb_imun", "comorb_hiv", "comorb_neopl", "comorb_tabag", 
                        "comorb_neuro_cronica", "comorb_neoplasias", "comorb_tuberculose", "comorb_obesidade", "comorb_cirurgia_bariat", 
                        "amostra_t_rapido", "tipo_amostra_t_rapido", "dt_coleta_t_rapido", "resultado_t_rapido", "amostra_sorologia", "tipo_amostra_sorologia", 
                        "dt_coleta_sorologia", "resultado_sorologia", "amostra_rt_pcr", "dt_coleta_rt_pcr", "resultado_rt_pcr", "class_final", "crit_conf", "dt_encerramento"])

        dfNOT = filter(["pais", "municipio_paciente"] => (x, y) -> ismissing(x) ? false : contains(string(x), "NULL") & isa(y,String) ? y == "PALMAS - TO" : false , dfNOT)

        # filtra casos encerrados
        dfNOT = filter(["class_final", "crit_conf", "dt_encerramento"] => (x, y, z) -> 
                        (ismissing(x) == false && x == 3 && ismissing(y) == false && ismissing(z) == false) ? false : true , dfNOT)

        # Processar as informações

        LinC = nrow(dfCom)
        LinN = nrow(dfNOT)

        insertcols!(dfNOT, 1, :Comorbidade => "-")
        insertcols!(dfNOT, 1, :Metodo_exame => "-")
        insertcols!(dfNOT, 1, :Resultado => "-")
        insertcols!(dfNOT, 1, :Obs_Exame => "-")
        insertcols!(dfNOT, 1, :Endereço => "-")
        insertcols!(dfNOT, 1, :Telefone_fim => "-")
        insertcols!(dfNOT, 1, :Data_exame => "")
        dfNOT.Data_exame = convert(Vector{Union{Missing,String, Date}}, dfNOT.Data_exame)

        dfNOT.resultado_t_rapido = map(x -> ismissing(x) ? 0 : isa(x, Number) ? x : 0, dfNOT.resultado_t_rapido)
        dfNOT.resultado_rt_pcr = map(x -> ismissing(x) ? 0 : isa(x, Number) ? x : 0, dfNOT.resultado_rt_pcr)
        dfNOT.resultado_sorologia = map(x -> ismissing(x) ? 0 : isa(x, Number) ? x : 0, dfNOT.resultado_sorologia)
        dfNOT.dt_coleta_t_rapido = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.dt_coleta_t_rapido)
        dfNOT.dt_coleta_sorologia = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.dt_coleta_sorologia)
        dfNOT.dt_coleta_rt_pcr = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.dt_coleta_rt_pcr)        
        dfNOT.data_notificacao = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.data_notificacao)
        dfNOT.data_nascimento = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.data_nascimento)
        
        
        

        for i = 1:LinN
            # consolida as comorbidades
            for j = 1:LinC    
                if isa(dfNOT[i,dfCom[j,1]], Number) && dfNOT[i,dfCom[j,1]] == 1
                    if dfNOT[i, :Comorbidade] == "-"
                        dfNOT[i, :Comorbidade] = dfCom[j,2]
                    else
                        dfNOT[i, :Comorbidade] = join([string(dfNOT[i, :Comorbidade]), "| \n", dfCom[j,2]])
                    end
                end
            end
                
            # Identificar o tipo de teste
            if dfNOT[i, "resultado_t_rapido"] == 1
                if dfNOT[i, "resultado_rt_pcr"] == 2
                    dfNOT[i, "Obs_Exame"] =  "RT-PCR deu negativo"               
                end
                if dfNOT[i, "tipo_amostra_t_rapido"] == 1
                    dfNOT[i, "Resultado"] = "IgG POSITIVO"
                elseif dfNOT[i, "tipo_amostra_t_rapido"] == 2
                    dfNOT[i, "Resultado"] = "IgM POSITIVO"
                elseif dfNOT[i, "tipo_amostra_t_rapido"] == 3
                    dfNOT[i, "Resultado"] = "IgG/IgM POSITIVO"
                elseif dfNOT[i, "tipo_amostra_t_rapido"] == 4
                    dfNOT[i, "Resultado"] = "AG POSITIVO"    
                end
                dfNOT[i, "Metodo_exame"] = "Teste Rápido"               
                if ismissing(dfNOT[i, "dt_coleta_t_rapido"]) == false
                    if isa(dfNOT[i, :dt_coleta_t_rapido], Date) 
                        dfNOT[i, "Data_exame"] = dfNOT[i, "dt_coleta_t_rapido"]
                    else
                        dfNOT[i, "Data_exame"] = Dates.format(dfNOT[i, "dt_coleta_t_rapido"], "dd/mm/yyyy")
                    end    
                end
            elseif dfNOT[i, "resultado_sorologia"] == 1
                if dfNOT[i, "resultado_rt_pcr"] == 2
                    dfNOT[i, "Obs_Exame"] =  "RT-PCR deu negativo"       
                end
                dfNOT[i, "Metodo_exame"] = "Sorologia"
                if dfNOT[i, "tipo_amostra_sorologia"] == 1
                    dfNOT[i, "Resultado"] = "IgA POSITIVO"
                elseif dfNOT[i, "tipo_amostra_sorologia"] == 2
                    dfNOT[i, "Resultado"] = "IgG POSITIVO"
                elseif dfNOT[i, "tipo_amostra_sorologia"] == 3
                    dfNOT[i, "Resultado"] = "IgM POSITIVO"
                elseif dfNOT[i, "tipo_amostra_sorologia"] == 4
                    dfNOT[i, "Resultado"] = "IgG/IgM POSITIVO"    
                end
                if ismissing(dfNOT[i, "dt_coleta_sorologia"]) == false
                    if isa(dfNOT[i, :dt_coleta_sorologia], Date) 
                        dfNOT[i, "Data_exame"] = dfNOT[i, "dt_coleta_sorologia"]
                    else
                        dfNOT[i, "Data_exame"] = Dates.format(dfNOT[i, "dt_coleta_sorologia"], "dd/mm/yyyy")
                    end                  
                end
            elseif dfNOT[i, "resultado_rt_pcr"] == 1
                dfNOT[i, "Metodo_exame"] = "RT-PCR"
                dfNOT[i, "Resultado"] = "DETECTÁVEL"
                if ismissing(dfNOT[i, "dt_coleta_rt_pcr"]) == false
                    if isa(dfNOT[i, :dt_coleta_rt_pcr], Date) 
                        dfNOT[i, "Data_exame"] = dfNOT[i, "dt_coleta_rt_pcr"]
                    else
                        dfNOT[i, "Data_exame"] = Dates.format(dfNOT[i, "dt_coleta_rt_pcr"], "dd/mm/yyyy")
                    end
                end
            else
                if dfNOT[i, "resultado_rt_pcr"] == 2
                    dfNOT[i, "Metodo_exame"] = "RT-PCR"
                    dfNOT[i, "Resultado"] = "NÃO DETECTÁVEL"
                elseif dfNOT[i, "resultado_sorologia"] == 2
                    dfNOT[i, "Metodo_exame"] = "Sorologia"
                    dfNOT[i, "Resultado"] = "NEGATIVO"
                elseif dfNOT[i, "resultado_t_rapido"] == 2
                    dfNOT[i, "Metodo_exame"] = "Teste Rápido"
                    dfNOT[i, "Resultado"] = "NEGATIVO"
                end
            end

            Testes = ["resultado_rt_pcr", "resultado_sorologia", "resultado_t_rapido"]
            N_testes = 0
            Checagem = 0
            Divergencia = "Não"
            for j in Testes
                if dfNOT[i, j] in [1,2]
                    N_testes += 1
                    if Checagem != 0
                        if  Checagem != dfNOT[i, j]
                            Divergencia = "Sim"
                        end
                    else
                        Checagem = dfNOT[i, j] 
                    end
                end
            end

            if N_testes > 1
                if dfNOT[i, "Obs_Exame"] ==  "RT-PCR deu negativo"
                elseif Divergencia == "Não"
                    dfNOT[i, "Obs_Exame"] =  "Mais de um teste informado"               
                else
                    dfNOT[i, "Obs_Exame"] =  "Mais de um teste informado, mas divergente"
                end            
            end

            # Corrige endereço
            if (ismissing(dfNOT[i, "bairro"]) == false && contains(dfNOT[i, "bairro"],"Não Encontrado") == false) || 
                (ismissing(dfNOT[i, "logradouro"]) == false && contains(dfNOT[i, "logradouro"],"Não Encontrado")== false)
                    if (ismissing(dfNOT[i, "bairro"]) == false && contains(dfNOT[i, "bairro"],"Não Encontrado")== false)
                        dfNOT[i, "Endereço"] = uppercase(dfNOT[i, "bairro"])
                    end

                    if (ismissing(dfNOT[i, "logradouro"]) == false && contains(dfNOT[i, "logradouro"],"Não Encontrado")== false)
                        if dfNOT[i, "Endereço"] == "-"
                            dfNOT[i, "Endereço"] = dfNOT[i, "logradouro"]
                        else
                            dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], " ", uppercase(dfNOT[i, "logradouro"])])
                        end
                    end

                    if (ismissing(dfNOT[i, "quadra"]) == false && contains(string(dfNOT[i, "quadra"]),"Não Encontrado")== false)
                        if dfNOT[i, "Endereço"] == "-"
                            dfNOT[i, "Endereço"] = string(dfNOT[i, "quadra"])
                        else
                            dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], " ", uppercase(string(dfNOT[i, "quadra"]))])
                        end
                    end

                    if (ismissing(dfNOT[i, "lote"]) == false && contains(string(dfNOT[i, "lote"]),"não sabe dizer")== false)
                        if dfNOT[i, "Endereço"] == "-"
                            dfNOT[i, "Endereço"] = dfNOT[i, "lote"]
                        else
                            dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], " Lote: ", uppercase(string(dfNOT[i, "lote"]))])
                        end
                    end
            end
            

            if dfNOT[i, "Endereço"] == "-"
                if ismissing(dfNOT[i, "endereco_outra_cidade"]) == false
                    dfNOT[i, "Endereço"] = uppercase(string(dfNOT[i, "endereco_outra_cidade"]))
                else                    
                    dfNOT[i, "Endereço"] = "COLETAR NO INFORME"
                end
            elseif ismissing(dfNOT[i, "endereco_outra_cidade"]) == false
                dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], "; ", uppercase(string(dfNOT[i, "endereco_outra_cidade"]))])
            end

            if ismissing(dfNOT[i, "telefone"]) == false && dfNOT[i, "telefone"] != 0
                dfNOT[i, "Telefone_fim"] = string(dfNOT[i, "telefone"])
            end

            if ismissing(dfNOT[i, "telefone_2"]) == false && dfNOT[i, "telefone_2"] != 0
                if contains(string(dfNOT[i, "Telefone_fim"]), string(dfNOT[i, "telefone_2"])) == false
                    dfNOT[i, "Telefone_fim"] = join([dfNOT[i, "Telefone_fim"], "| \n", string(dfNOT[i, "telefone_2"])])
                end
            end
            if ismissing(dfNOT[i, "telefone_3"]) == false && dfNOT[i, "telefone_3"] != 0
                if contains(string(dfNOT[i, "Telefone_fim"]), string(dfNOT[i, "telefone_3"])) == false
                    dfNOT[i, "Telefone_fim"] = join([dfNOT[i, "Telefone_fim"], "| \n", string(dfNOT[i, "telefone_3"])])
                end
            end
            if ismissing(dfNOT[i, "cartao_sus"]) == false && dfNOT[i, "cartao_sus"] == 0
                dfNOT[i, "cartao_sus"] = dfNOT[i, "cpf"]
            end
            dfNOT[i, "sexo"] = SubString(dfNOT[i, "sexo"], 4, 4)
            if findfirst('(', dfNOT[i, "nome_unidade"]) != nothing
                dfNOT[i, "nome_unidade"] = SubString(dfNOT[i, "nome_unidade"], 1, findfirst('(', dfNOT[i, "nome_unidade"]) - 1)
            end
        end

        dfNOT = filter("Resultado" => x -> x != "-", dfNOT)

        # dfCOE."pais" = map(x -> ismissing(x) ? missing : string(x), dfCOE."pais")

        # grava teste
        if false
            Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\dfNot.csv"

            open(Local, "w") do io
                CSV.write(io, dfNOT, delim=";")
            end
          
        end

        rename!(dfCOE, Dict("Nº NOTIFICAÇÃO" => "num_notificacao"))
        dfNOT = leftjoin(dfNOT, dfCOE,  on="num_notificacao", matchmissing=:equal)
        #dfNOT = filter(["Resultado", "NOME"]  => (x, y) -> x != "-" & ismissing(y), dfNOT)

        if false
            Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\Teste_completo.csv"

            open(Local, enc"windows-1252", "w") do io
                CSV.write(io, dfNOT, delim=";")
            end  
        end
        
        dfNOT = filter(["Resultado", "NOME"]  => (x, y) -> x != "NEGATIVO" && x != "NÃO DETECTÁVEL" && ismissing(y), dfNOT)

        insertcols!(dfNOT, 1, :N => "")
        insertcols!(dfNOT, 1, :Cirtério => "C.L")
        insertcols!(dfNOT, 1, "STATUS e-SUS VE" => "")

        insertcols!(dfNOT, 1, :GAL => "")
        insertcols!(dfNOT, 1, "DATA DO BOLETIM" => "")
        insertcols!(dfNOT, 1, "Laboratório" => "")

        select!(dfNOT, ["data_notificacao", "N", "Cirtério", "STATUS e-SUS VE", "Data_exame", "GAL", "DATA DO BOLETIM", "num_notificacao",
                        "nome_paciente", "idade_anos_dt_notific", "data_nascimento", "sexo", "cartao_sus", "Comorbidade", 
                        "Telefone_fim", "Endereço", "nome_unidade", "Laboratório", "Metodo_exame", "Resultado", "Obs_Exame"])

        
        # Monta o código metaphone e grava
        col = ncol(dfNOT)
        insertcols!(dfNOT, col + 1, "metaphone" => "")

        for i = 1: nrow(dfNOT)
            if ismissing(dfNOT[i, :data_nascimento]) == false && (isa(dfNOT[i, :data_nascimento], DateTime) || isa(dfNOT[i, :data_nascimento], Date))
                dfNOT[i, :metaphone] = string(Funções.MetaPTBR(dfNOT[i, :nome_paciente], 20), Dates.format(dfNOT[i, :data_nascimento], "yyyy-mm-dd"))
            end
        end
        
        Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\Notificações faltantes.xlsx"

        df = copy(dfNOT)

        for col in names(df)
            col2 = Symbol(col)
            df[!, col2] = map(x -> ismissing(x) ? missing : string(x), df[!, col2])
        end
        
        XLSX.writetable(Local, df, overwrite=true, sheetname="report", anchor_cell="A1")

        # monta a deduplicação    
        #dfCOE[!, "LIBERAÇÃO EXAME"] = map(x -> ismissing(x) || (isa(x, DateTime) == false && isa(x, Date) == false)  ? missing : Dates.format(x, "dd/mm/yyyy"), dfCOE[!, "LIBERAÇÃO EXAME"])  
        dfNOT = leftjoin(dfNOT, select(dfCOE, ["metaphone", "num_notificacao", "UNIDADE NOTIFICADORA", "LIBERAÇÃO EXAME", "METODOLOGIA"]) ,  
                                on="metaphone", matchmissing=:equal, makeunique=true)


        data = Date(2021,08,01)

        dfNOT = filter(["data_notificacao", "Data_exame"]  => (x, y) -> x >= data || (ismissing(y) == false && isa(y, DateTime) && y >= data), dfNOT)

        Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\Notificações faltantes deduplicado.xlsx"
        
        df = copy(dfNOT)

        df.data_notificacao = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"), df.data_notificacao)
        df.Data_exame = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"), df.Data_exame)
        df.data_nascimento = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"), df.data_nascimento)
        df[!, "LIBERAÇÃO EXAME"] = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"),  df[!, "LIBERAÇÃO EXAME"])

 
        for col in names(df)
            col2 = Symbol(col)
            df[!, col2] = map(x -> ismissing(x) ? missing : string(x), df[!, col2])
        end
        
        XLSX.writetable(Local, df, overwrite=true, sheetname="report", anchor_cell="A1")

        return "Terminado", "Processamento concluído"
    end  

    # Faz o encerramento dos casos gerando o CSV
    function Encerrar()
        # importa notifica
        dfNOT = DataFrame(XLSX.readtable("C:\\Bancos\\Notificasus\\Covid\\BDs\\notifica.xlsx", 1)...)


        select!(dfNOT, ["num_notificacao", "nome_unidade", "data_notificacao", "cartao_sus", "cpf", "nome_paciente", "idade_anos_dt_notific",
                        "data_nascimento", "sexo", "municipio_paciente", "bairro", "logradouro", "endereco_outra_cidade", 
                        "quadra", "lote", "pais", "telefone", "telefone_2", "telefone_3",  
                        "amostra_t_rapido", "tipo_amostra_t_rapido", "dt_coleta_t_rapido", "resultado_t_rapido", "amostra_sorologia", "tipo_amostra_sorologia", 
                        "dt_coleta_sorologia", "resultado_sorologia", "amostra_rt_pcr", "dt_coleta_rt_pcr", "resultado_rt_pcr",
                        "class_final",	"crit_conf", "evolucao", "dt_encerramento"])

                        

        dfNOT = filter(["pais", "municipio_paciente"] => (x, y) -> ismissing(x) ? false : contains(string(x), "NULL") & isa(y,String) ? y == "PALMAS - TO" : false , dfNOT)

        # carrega dados do cruzamento
        dfCRUZ = DataFrame(XLSX.readtable("C:\\Bancos\\Notificasus\\Covid\\BDs\\Encerramento\\Cruzamento de dados.xlsx", 1)...)

        rename!(dfCRUZ, Dict("LIBERAÇÃO EXAME" => "dt_liberação", "Nº NOTIFICAÇÃO" => "num_notificacao", "Nº REQUISIÇÃO GAL" => "GAL", "Comorbidade / FATOR DE RISCO" => "comorbidade"))
        
        dfNOT = leftjoin(dfNOT,select(dfCRUZ, ["num_notificacao", "GAL", "comorbidade", "dt_liberação", "Resultado"]), on="num_notificacao", makeunique=true)

        dfNOT = filter("Resultado" => x -> ismissing(x) == false, dfNOT)
        Lin = nrow(dfNOT)
        Colunas = ncol(dfNOT)
        insertcols!(dfNOT, Colunas+1, :Atualizar => 0)
        insertcols!(dfNOT, Colunas+2, :dtdiff => 0)

        # dfCOE."pais" = map(x -> ismissing(x) ? missing : string(x), dfCOE."pais")
        for i = 1:Lin
            diff = (dfNOT[i, :data_notificacao] - dfNOT[i, :dt_liberação]).value
            dfNOT[i, :dtdiff] = diff

            if diff > -16 && diff < 16
                dfNOT[i, :Atualizar] = 1 

                if ismissing(dfNOT[i, :resultado_rt_pcr]) || dfNOT[i, :resultado_rt_pcr] != 1
                    if dfNOT[i , :Resultado] == "DETECTÁVEL"
                        dfNOT[i, :resultado_rt_pcr] = 1
                        dfNOT[i, :class_final] = 2
                       
                    elseif dfNOT[i , :Resultado] == "NÃO DETECTÁVEL"
                        dfNOT[i, :resultado_rt_pcr] = 2
                        dfNOT[i, :class_final] = 3
                       
                    end

                    if ismissing(dfNOT[i , :dt_coleta_rt_pcr])
                        dfNOT[i, :dt_coleta_rt_pcr] = dfNOT[i, :dt_liberação]
                    end
                    dfNOT[i, :amostra_rt_pcr] = 1
                    dfNOT[i, :crit_conf] = 3                    
                    dfNOT[i, :dt_encerramento] = today()                    

                else
                    if ismissing(dfNOT[i, :dt_encerramento])
                        dfNOT[i, :dt_encerramento] = today()
                    end
                end           
            end
        end
       
        # Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Encerramento\\Teste2.csv"

        # open(Local, enc"windows-1252", "w") do io
        #     CSV.write(io, dfNOT, delim=";")
        # end  

        dfNOT = filter("Atualizar" => x -> x == 1, dfNOT)
        
        select!(dfNOT, ["num_notificacao", "nome_unidade", "data_notificacao", "cartao_sus", "cpf", "nome_paciente", 
                        "data_nascimento", "sexo", "municipio_paciente", "bairro", "logradouro", "endereco_outra_cidade", 
                        "quadra", "lote", "pais", "telefone", "telefone_2", "telefone_3",  
                        "amostra_t_rapido", "tipo_amostra_t_rapido", "dt_coleta_t_rapido", "resultado_t_rapido", "amostra_sorologia", "tipo_amostra_sorologia", 
                        "dt_coleta_sorologia", "resultado_sorologia", "amostra_rt_pcr", "dt_coleta_rt_pcr", "resultado_rt_pcr",
                        "class_final",	"crit_conf", "evolucao", "dt_encerramento"])

        Local = "C:\\Bancos\\Notificasus\\Covid\\BDs\\Encerramento\\Encerramento.csv"

        open(Local, enc"windows-1252", "w") do io
            CSV.write(io, dfNOT, delim=";")
        end

        return "Terminado"   
        
    end


    function ZDC()
        # Processa os casos no notifica que não foram laçados da planilha do coe
        
        df = DataFrame(CSV.File(open(read, "C:\\Bancos\\GAL\\ZDC\\data.csv", enc"windows-1252"), delim=";"))

        Colunas = ["Requisição", "Paciente", "Nome da Mãe", "Data de Nascimento", "Data da Coleta", "Sexo", "IBGE Município de Residência", 
        "Endereço", "Exame", "Data de Cadastro", "Data do Recebimento", "Status Exame", "Data da Liberação", 
        "Observações do Resultado"]
      

        if issubset(Colunas, names(df)) == false
            for item in Colunas
                if issubset([item], names(df)) 
                    println(item * "- Ok")
                else
                    println(item * "- Erro")
                end
            end
            return "O gal foi baixado incorretamente", "Erro, não processado"
        end

        for col in ["Sexo", "Status Exame", "Observações do Resultado"]
            df[!, col] = map(x -> string(x), df[!, col])
        end

        for col in ["Data de Nascimento",  "Data da Coleta",  "Data de Cadastro", "Data da Liberação", "Data do Recebimento"]
            df[!, col] = map(x -> Date(x, DateFormat("dd-mm-yyyy")), df[!, col])
        end


        for exames in ["Dengue", "Zika", "Chikungunya"]
            dff = select(df, Colunas)

            if exames == "Dengue"
                dff.Exame = map(x -> "Dengue, Biologia Molecular", dff.Exame)
            elseif exames == "Zika"
                dff.Exame = map(x -> "Zika, Biologia Molecular", dff.Exame)
            elseif exames == "Chikungunya"
                dff.Exame = map(x -> "Chikungunya, Biologia Molecular", dff.Exame)
            end

            dff.Resultado = map(x -> string(x), df[!, exames])
            Local = "C:\\Bancos\\GAL\\ZDC\\$exames.xlsx"

            XLSX.writetable(Local, dff, overwrite=true, sheetname="report", anchor_cell="A1")
        end
       
        
        return "Terminado", "Processamento concluído"
    end  

    function Sisvan()
        df1 = DataFrame(ano = String[], 
                    mes = String[],
                    faixa =  String[],
                    relatorio =  String[],
                    nu_cnes = String[],
                    usf =  String[],
                    var =  String[], 
                    valor =  Int64[])
                    

        # Processa os casos no notifica que não foram laçados da planilha do coe
        file = "C:\\Bancos\\Outros\\Sisvan\\bruto\\Adolecente - ALTURA X IDADE.xlsx"
        df = DataFrame(XLSX.readtable(file, 1, "A:Z", header=false, stop_in_empty_row=false)...)
        
        fase = df[4, 1]
        ano = first(chop(fase ,head = 5), 4)
        mes = chop(fase, head=findlast(':', fase), tail=0)

        fase = df[5, 1]
        faixa = strip(chop(fase, head=findlast(':', fase), tail=0))

        rel = df[6, 1]

        for k = 10:size(df, 1)

            for i = 6:15
                if ~ismissing(df[8, i])
                    push!(df1,[
                        ano,
                        mes,
                        faixa,
                        rel,
                        df[k, 4],
                        df[k, 5],
                        df[8, i],
                        parse(Int64, df[k, i])])
                end
            end

        end
        
    end  
end