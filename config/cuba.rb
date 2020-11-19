require 'cuba'
require "cuba/render"

Cuba.plugin(Cuba::Render)

Cuba.settings[:render][:template_engine] = "jbuilder"
Cuba.settings[:render][:views] = "app/views/"
Cuba.settings[:default_headers].merge!({'Content-Type' => 'application/json; charset=utf-8'})

