class Healthcheck
  def self.checklist
    [{ebsco: {healthy: true, message: 'Not Implemented'} },
     {userinfo_service: {healthy: true, message: 'Not Implemented'}}
    ]
  end
end
