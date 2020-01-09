class Healthcheck
  def self.checklist
    search_client_health, search_client_message = User.healthcheck
    eds_health, eds_message = EDS.healthcheck

    [{ebsco: {healthy: eds_health, message: eds_message} },
     {search_client_service: {
        healthy: search_client_health,
        message: search_client_message}
     }
    ]
  end
end
