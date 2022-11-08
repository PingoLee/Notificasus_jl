#using Revise
include("Resultados_N/Principal.jl")
include("pacs/fun.jl")
using .Principal, .fun	


# includet("Resultados_N/Principal.jl")
# includet("pacs/fun.jl")
using Gtk

win = GtkWindow("Gerenciador de notificações COVID", 400, 200)

# colocar um conteiner
hbox = GtkBox(:v)
push!(win,hbox)

g = GtkGrid()
g2 = GtkGrid()

ExtrairPos = GtkButton("Extrai notificações positivas")
UpGAL = GtkButton("Gerar CSV com o encerramento do GAL")
ARBO = GtkButton("Extrai notificações das arboviroses")

function ExtrairPos_clicked(w)
    Pergunta = ask_dialog("Você vai inciar o cruzamento das informações", "De bobs", "Qué não!")
    if Pergunta == false         
        try
          Msg, MsgF = Principal.Processar()
          set_gtk_property!(ent,:text, MsgF)
          info_dialog(Msg)
        catch
          set_gtk_property!(ent,:text,"Deu melda")
        end             
        
    else
        info_dialog("Relaxa, a bagaça foi cancelada")
    end 
end

function UpGAL_clicked(w)
  Pergunta = ask_dialog("Você vai inciar o cruzamento das informações", "De bobs", "Qué não!")
  if Pergunta == false
      set_gtk_property!(ent2,:text,"Deu melda")           
      Gtk.info_dialog(Principal.Encerrar())
      set_gtk_property!(ent2,:text,"Arquivo gerado")
  else
      info_dialog("Relaxa, a bagaça foi cancelada")
  end    
end

function Arbo_clicked(w)
  Pergunta = ask_dialog("Você vai inciar o processamento das informações", "De bobs", "Qué não!")
  if Pergunta == false      
    try
      Msg, MsgF = Principal.ZDC()
      set_gtk_property!(ent3,:text, MsgF)
      info_dialog(Msg)
    catch
      set_gtk_property!(ent3,:text,"Deu melda")
    end            
  else
      info_dialog("Relaxa, a bagaça foi cancelada")
  end    
end

function localhost_clicked(w)
  set_gtk_property!(ent,:text,"Iniciando")
  Principal.Processar()
  set_gtk_property!(ent,:text,"Terminado")
end

signal_connect(ExtrairPos_clicked, ExtrairPos, "clicked")
signal_connect(UpGAL_clicked, UpGAL, "clicked")
signal_connect(Arbo_clicked, ARBO, "clicked")
#signal_connect(Campos_clicked, Camposbelos, "clicked")

g[1,1] = GtkLabel("O que quer fazer:")
g[2,1] = GtkLabel("   ")
g[3,1] = GtkLabel(" ")
g[4,1] =  GtkLabel("  ")

ent = GtkEntry()
set_gtk_property!(ent,:text,"Aguardando iniciar")
g[1,2] = ExtrairPos
g[2,2] = GtkLabel("    ")
g[3,2] = GtkLabel("Status:")
g[4,2] = ent

for i = 1: 4
  g[i,3] = GtkLabel("    ")
end 

ent2 = GtkEntry()
set_gtk_property!(ent2,:text,"Aguardando iniciar")
g[1,4] = UpGAL
g[2,4] = GtkLabel("    ")
g[3,4] = GtkLabel("Status:")
g[4,4] = ent2

for i = 1: 4
  g[i,5] = GtkLabel("    ")
end

ent3 = GtkEntry()
set_gtk_property!(ent3,:text,"Aguardando iniciar")
g[1,6] = ARBO
g[2,6] = GtkLabel("    ")
g[3,6] = GtkLabel("Status:")
g[4,6] = ent3



# MONTA OS BOTÕES
push!(hbox,g)
#push!(hbox,g2)

showall(win)

if !isinteractive()
  c = Condition()
  signal_connect(win, :destroy) do widget
      notify(c)
  end
  @async Gtk.gtk_main()
  wait(c)
end