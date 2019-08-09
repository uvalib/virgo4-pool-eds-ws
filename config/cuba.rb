require 'cuba'
require "cuba/render"

Cuba.plugin(Cuba::Render)

Cuba.settings[:render][:template_engine] = "jbuilder"
Cuba.settings[:render][:views] = "app/views/"

