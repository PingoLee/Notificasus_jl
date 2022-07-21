include("Resultados_N/Principal.jl")
include("Funções.jl")

using .Principal, .Funções	

using Stipple
using StippleUI
using StippleCharts
using StringEncodings
using XLSX

using CSV, DataFrames, Dates

# Fontes: https://fonts.google.com/icons?selected=Material+Icons:note_add

# configuration
global data_opts = DataTableOptions(columns = [Column("data_notificacao"), Column("Data_exame", align = :right),
                                              Column("num_notificacao", align = :right), Column("nome_paciente", align = :left),
                                              Column("Metodo_exame", align = :right), Column("Resultado", align = :left)])



# model
#global data =  DataFrame(CSV.File(open(read, "C:/Bancos/Notificasus/Covid/BDs/Rastreio do notifica/Notificações faltantes deduplicado.csv", enc"windows-1252"), delim=";"))
global data = DataFrame(XLSX.readtable("C:\\Bancos\\Notificasus\\Covid\\BDs\\Rastreio do notifica\\Notificações faltantes deduplicado.xlsx", 1)...)

Base.@kwdef mutable struct Dashboard1 <: ReactiveModel
  credit_data::R{DataTable} = DataTable()
  credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=100)
  credit_data_loading::R{Bool} = false
  channel__::R{String} = ""
  range_data::R{RangeData{Int}} = RangeData(15:80)

  total_encontrado::R{Int} = 0
  total_ja_inserido::R{Int} = 0
  total_tipo_teste_outros::R{Int} = 0
  total_tipo_teste_pcr::R{Int} = 0
  
  process::R{Bool} = false  
  name::R{String} = string(Dates.format(Dates.unix2datetime(stat("C:/Bancos/Notificasus/Covid/BDs/Rastreio do notifica/Notificações faltantes deduplicado.csv").mtime), "dd/mm/yyyy HH:MM:SS"))
  status::R{String} = "Concluído"
end


# functions
function creditdata(data::DataFrame, model::M) where {M<:Stipple.ReactiveModel}
  model.credit_data[] = DataTable(data, data_opts)
  model.name[] = string(Dates.format(Dates.unix2datetime(stat("C:/Bancos/Notificasus/Covid/BDs/Rastreio do notifica/Notificações faltantes deduplicado.csv").mtime), "dd/mm/yyyy HH:MM:SS"))
  
end

function bignumbers(data::DataFrame, model::M) where {M<:ReactiveModel}
  model.total_encontrado[] = data |> nrow
  model.total_ja_inserido[] =  filter(:METODOLOGIA => x -> ismissing(x) == false, data) |> nrow
  model.total_tipo_teste_outros[] = filter(:Metodo_exame => x -> x != "RT-PCR", data) |> nrow
  model.total_tipo_teste_pcr[] = filter(:Metodo_exame => x -> x == "RT-PCR", data) |> nrow
end

function barstats(data::DataFrame, model::M) where {M<:Stipple.ReactiveModel}
  age_stats = Dict{Symbol,Vector{Int}}(:good_credit => Int[], :bad_credit => Int[])

  for x in 20:10:70
    push!(age_stats[:good_credit],
          data[(data.idade .∈ [x:x+10]) .& (data.ig_dias .>= 80), [:ig_dias]] |> nrow)
    push!(age_stats[:bad_credit],
          data[(data.idade .∈ [x:x+10]) .& (data.st_alto_risco .== 0), [:ig_dias]] |> nrow)
  end

  Q = maximum(maximum(values(age_stats)))

  

  model.bar_plot_data[] = [PlotSeries("Good credit", PlotData(age_stats[:good_credit])),
                            PlotSeries("Bad credit", PlotData(age_stats[:bad_credit]))]

end


function setmodel(data::DataFrame, model::M)::M where {M<:ReactiveModel}
  creditdata(data, model)
  bignumbers(data, model)

  model
end

### UI
Stipple.register_components(Dashboard1, StippleCharts.COMPONENTS)

gc_model = setmodel(data, Dashboard1()) |> Stipple.init

function filterdata(model::Dashboard1)
  model.credit_data_loading[] = true
  model = setmodel(data[(model.range_data[].range.start .<= data[:Age] .<= model.range_data[].range.stop), :], model)
  model.credit_data_loading[] = false

  nothing
end

function filtro(model::Dashboard1)  
  model = setmodel(data, model)
  model.credit_data_loading[] = false

  nothing
end


on(gc_model.process) do _
  if (gc_model.process[])
    gc_model.status[] = "Processando"
    gc_model.credit_data_loading[] = true
    Principal.Processar()    
    global data = DataFrame(CSV.File(open(read, "C:/Bancos/Notificasus/Covid/BDs/Rastreio do notifica/Notificações faltantes deduplicado.csv", enc"windows-1252"), delim=";"))    
    gc_model.status[] = "Carregando modelo"
    
    filtro(gc_model)
    
    #gc_model.processAt[] = false
    gc_model.name[] = string(Dates.format(Dates.unix2datetime(stat("C:/Bancos/Notificasus/Covid/BDs/Rastreio do notifica/Notificações faltantes deduplicado.csv").mtime), "dd/mm/yyyy HH:MM:SS"))
    
    gc_model.credit_data_loading[] = false
    gc_model.status[] = "Concluído"
    gc_model.process[] = false    
  end
 
 
end


function ui(gc_model)
  [
  dashboard(vm(gc_model), title="NotificaSUS",
            head_content = Genie.Assets.favicon_support(), partial = false,
  [
    heading("Cruzamento de dados do notifica")

    row([
        cell(class = "st-module", [ p(button("Clique para realizar o relacionamento", @click("process = true")
        ))
        ])
        cell(class = "st-module", [
          h2([
            "Status: "
            span("", @text(:status))
          ])
        ])  
        cell(class = "st-module", [
          h2([
              "Data, "
              span("", @text(:name))
            ])
        ])         
        
    ])

    row([
      cell(class="st-module", [
        row([
          cell(class="st-br", [
            bignumber("total encontrado",
                      :total_encontrado,
                      icon="format_list_numbered",
                      color="negative")
          ])

          cell(class="st-br", [
            bignumber("Já localizados",
                      :total_ja_inserido,
                      icon="format_list_numbered",
                      color="positive")
          ])

          cell(class="st-br", [
            bignumber("RT-PCR",
                      R"total_tipo_teste_pcr | numberformat",
                      icon="biotech",
                      color="negative")
          ])

          cell(class="st-br", [
            bignumber("Outros",
                      R"total_tipo_teste_outros | numberformat",
                      icon="biotech",
                      color="positive")
          ])
        ])
      ])
    ])

    
    row([
      cell(class="st-module", [
        h4("Pacientes relacionados")

        table(:credit_data;
              style="height: 400px;",
              pagination=:credit_data_pagination,
              loading=:credit_data_loading
        )
      ])      
    ])
    

    footer(class="st-footer q-pa-md", [
      cell([
        span("Stipple &copy; $(year(now()))")
      ])
    ])
  ])
  ]
end

# handlers
on(gc_model.range_data) do _
  filterdata(gc_model)
end

# routes
route("/") do
  ui(gc_model) |> html
end

up(rand((8000:9000)), open_browser=true)