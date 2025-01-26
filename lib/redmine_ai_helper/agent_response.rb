module RedmineAiHelper
  class AgentResponse
    attr_reader :status, :value, :error
    AgentResponse::STATUS_SUCCESS = "success"
    AgentResponse::STATUS_ERROR = "error"

    def initialize(response = {})
      @status = response[:status] || response["status"]
      @value = response[:value] || response["value"]
      @error = response[:error] || response["error"]
    end

    def to_json
      to_hash().to_json
    end

    def to_hash
      { status: status, value: value, error: error }
    end

    def to_h
      to_hash
    end

    def is_success?
      status == AgentResponse::STATUS_SUCCESS
    end

    def is_error?
      !is_success?
    end

    def self.create_error(error)
      AgentResponse.new(status: AgentResponse::STATUS_ERROR, error: error)
    end

    def self.create_success(value)
      AgentResponse.new(status: AgentResponse::STATUS_SUCCESS, value: value)
    end
  end
end
