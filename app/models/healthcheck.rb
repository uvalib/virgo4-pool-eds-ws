class Healthcheck
  def self.checklist
    eds_health, eds_message = EDS.healthcheck

    [{ebsco: {healthy: eds_health, message: eds_message} }
    ]
  end
end
