module fun
    using Dates

    export create_storage_dir
    # Subtrai data
    function  Sub_Mes(date, delta)
        m0 = month(date) + delta
        m = (month(date) + delta) % 12
        
        m == 0 ? m = 12 : m = m 

        # avança ou não o ano
        if m0<1
            y = year(date) - 1
        elseif m0>12
            y = year(date) + 1
        else
            y = year(date)
        end
    
        # detecta se o ano é bixesto
        if y%4 == 0 && (y%100 != 0 || y%400 == 0)
            fev = 29
        else 
            fev = 28
        end

        d = min(day(date), [31,fev,31,30,31,30,31,31,30,31,30,31][m])

        return Dates.Date(y,m,d)

    end

    # Função para coleta do nome
    function get_file_name(X)
        splited = split(X, "/")
        last_item = splited[size(splited,1)]
        last_item_splited = split(last_item, ".")
        name = last_item_splited[1]
        return name
    end

    # Função para coletar 
    function get_file_path(X)
        Nome = get_file_name(X)
        return replace(X, Nome * ".csv", "")
    end
    
    # Função para coleta do nome
    function get_file_name_O(X)
        splited = split(X, "\\")
        last_item = splited[size(splited,1)]
        last_item_splited = split(last_item, ".")
        name = last_item_splited[1]
        return name
    end
    
    # Função para coletar 
    function get_file_path_O(X)
        Nome = get_file_name_O(X)
        return replace(X, Nome * ".csv" => "")
    end

    function get_os_dir(X)
        X = replace(X, "\\" => "/")
        nome = get_file_name(X)
        return replace(X, "/" * nome * ".csv" => "")
    end
    
    
    # funções textuais
    function MetaPTBR(Nome, Tamanho)
        # Value to return
        # Separa as letras num array
        if(isa(Nome, Number))
            return ""
        end
        Nome = uppercase(Nome)
        Nome = strip(Nome)
        Nome = replace(Nome, "LH" => "1")
        Nome = replace(Nome, "NH" => "3")
        Nome = replace(Nome, "XC" => "S")
        Nome = replace(Nome, "SCH" => "X")

        for j in [" DA ", " DE ", " DO ", " DAS ", " DOS ", " E "]
            Nome = replace(Nome, j => " ")
        end
        
        Chars = rsplit(Nome, "")
        N_Letras = size(Chars, 1)
        Buffer = ""
        É_Vogal = ["A", "E", "I", "O", "U"]
        # Make sure the word is at least two characters in length
        if N_Letras > 2           
            LtPlus = ""
            U_Lt  = N_Letras - 1
            i = 1
            while i <= U_Lt            
                (i + 1) == N_Letras ? LtPlus = " " : LtPlus = Chars[i + 1]

                if Chars[i] in ["A", "E", "I", "O", "U"]
                    if i == 1 || Chars[i - 1] == " "
                        Buffer = string(Buffer, Chars[i])
                    elseif LtPlus == "U"
                        Buffer = string(Buffer, "L")
                        i += 1
                    end                
                elseif Chars[i] in ["1", "3", "B", "D", "F", "J", "K", "L", "M", "P", "T", "V"]
                    Buffer = string(Buffer, Chars[i])
                    LtPlus == Chars[i] ? i += 1 : i
                elseif Chars[i] == "G"
                    if LtPlus == "E" && LtPlus == "I"
                        Buffer = string(Buffer, "J")
                        i += 1
                    elseif LtPlus == "R"
                        Buffer = string(Buffer, "GR")
                        i += 1
                    else
                        Buffer = string(Buffer, "G")
                        i += 1
                    end
                elseif Chars[i] ==  "R"
                    Buffer = string(Buffer, "2")
                elseif Chars[i] == "Z"
                    if i == U_Lt || LtPlus == " " 
                        Buffer = string(Buffer, "S")
                    else
                        Buffer = string(Buffer, "Z")
                    end
                elseif Chars[i] == "N"
                    if i == U_Lt || LtPlus == " "
                        Buffer = string(Buffer, "M")
                    else
                        Buffer = string(Buffer, "N")
                    end
                elseif Chars[i] == "S"
                    if i == 1 || Chars[i - 1] == " "
                        Buffer = string(Buffer, "S")
                    elseif  i != 0 && i != U_Lt &&
                        LtPlus in É_Vogal &&
                        Chars[i - 1] in É_Vogal
                            Buffer = string(Buffer, "Z")
                    elseif i + 2 != U_Lt && LtPlus == "C"
                        LtPlus2 = Chars[i + 2]
                        if LtPlus2 == "E" || LtPlus2 == "I"
                            Buffer = string(Buffer, "S")
                            i += 2
                        elseif LtPlus2 == "A" || LtPlus2 == "U" || LtPlus2 == "O"
                            Buffer = string(Buffer, "SC")
                            i += 2
                        else
                            Buffer = string(Buffer, "S")
                        end
                    else
                        Buffer = string(Buffer, "S")
                    end

                elseif Chars[i] == "X"
                    if i == 2 && Chars[i - 1] in É_Vogal
                        if Chars[i - 1] == "E"
                            Buffer = string(Buffer, "S")
                        elseif Chars[i - 1] == "I"
                            Buffer = string(Buffer, "X")
                        else
                            Buffer = string(Buffer, "KS")
                        end
                    else
                        Buffer = string(Buffer, "X")
                    end

                elseif Chars[i] == "C"
                    if i + 1 != U_Lt && (LtPlus == "E" || LtPlus == "I")
                        Buffer = string(Buffer, "S")
                        i += 1
                    elseif i + 1 != U_Lt && LtPlus == "H"
                        Buffer = string(Buffer, "X")
                        i += 1
                    else
                        Buffer = string(Buffer, "K")
                    end

                elseif Chars[i] == "H" # Acho que dá pra mover lá pra cima?
                    if i == 0 && LtPlus in É_Vogal
                        Buffer = string(Buffer, LtPlus)
                        i += 1
                    end
                elseif Chars[i] == "Q"
                    if LtPlus == "U"
                        Buffer = string(Buffer, "K")
                        i += 1
                    else
                        Buffer = string(Buffer, "K")
                    end

                elseif Chars[i] ==  "W"
                        if LtPlus in É_Vogal
                            Buffer = string(Buffer, "V")
                            i += 1
                        end       
                end

                # If the buffer size meets the length limit, then exit the loop
                if length.(Buffer) >= Tamanho
                    break
                end

                i += 1
            end
        else
            # Set the return value
            return Nome
        end

        # Return the computed soundex
        return Buffer

    end

    # Criar diretório
    function create_storage_dir(name)
        try
          mkdir(joinpath(@__DIR__, name)) 
          if Sys.iswindows()
            mkdir("C:\\Bancos\\$name")
          elseif Sys.islinux()
            mkdir("$(homedir())/$name")
          end 
         
        catch 
          @warn "directory already exists" 
        end
        return joinpath(@__DIR__, name)
    end

end
