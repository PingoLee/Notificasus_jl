#using Revise
using Genie, Stipple
using Genie.Requests
using StippleUI

include("pacs/fun.jl")
using .fun

Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

# Generate file path
const FILE_PATH = create_storage_dir("GAL\\ZDC")

# Define react model
@reactive mutable struct APP <: ReactiveModel end

function ui(model::APP)
  page(model, title="Dashboard",
  [ 
    
      heading("Dashboard") 
      row([
        Html.div(class="col-md-12", [
          uploader(label="Upload Dataset", :auto__upload, :multiple, method="POST",
          url="http://localhost:9000/", field__name="csv_file")
        ])
      ])
  ])
end

route("/") do
  APP |> init |> ui |> html
end

#uploading csv files to the backend server
route("/", method = POST) do
  files = Genie.Requests.filespayload()
  for f in files
      write(joinpath(FILE_PATH, f[2].name), f[2].data)
      @info "Uploading: " * f[2].name
  end
  if length(files) == 0
      @info "No file uploaded"
  end
  return "upload done"
end

up(9000)