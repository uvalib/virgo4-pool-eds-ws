require 'cuba'
require "cuba/render"
require 'byebug'

Cuba.plugin(Cuba::Render)

Cuba.settings[:render][:template_engine] = "jbuilder"
Cuba.settings[:render][:views] = "app/views/"


