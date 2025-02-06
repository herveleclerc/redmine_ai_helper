require File.expand_path("../../test_helper", __FILE__)

class BaseAgentTest < ActiveSupport::TestCase
  def setup
    
  end

  def test_agent_list
    agent_list = RedmineAiHelper::BaseAgent.agent_list
    assert agent_list.size >= 6
  end


  class MyTestAgent < RedmineAiHelper::BaseAgent
    def self.list_tools
      {
        tools: [
          {
            name: "tool1",
            description: "tool1 description",
            arguments: {
              arg1: {
                type: "string",
                description: "arg1 description",
              }
            },
          },
          {
            name: "tool2",
            description: "tool2 description",
            arguments: {
              arg2: {
                type: "string",
                description: "arg2 description",
              }
            },
          },
        ],
      }
    end
  end

end

class MyTestAgent < RedmineAiHelper::BaseAgent
  def self.list_tools
    {
      tools: [
        {
          name: "tool1",
          description: "tool1 description",
          arguments: {
            arg1: {
              type: "string",
              description: "arg1 description",
            }
          },
        },
        {
          name: "tool2",
          description: "tool2 description",
          arguments: {
            arg2: {
              type: "string",
              description: "arg2 description",
            }
          },
        },
      ],
    }
  end
end

class MyTestAgent2 < RedmineAiHelper::BaseAgent
  def self.list_tools
    {
      tools: [
        {
          name: "tool3",
          description: "tool3 description",
          arguments: {
            arg3: {
              type: "string",
              description: "arg3 description",
            }
          },
        },
        {
          name: "tool4",
          description: "tool4 description",
          arguments: {
            arg4: {
              type: "string",
              description: "arg4 description",
            }
          },
        },
      ],
    }
  end
end

class MyTestAgent3 < RedmineAiHelper::BaseAgent
  def self.list_tools
    {
      tools: [
        {
          name: "tool5",
          description: "tool5 description",
          arguments: {
            arg5: {
              type: "string",
              description: "arg5 description",
            }
          },
        },
        {
          name: "tool6",
          description: "tool6 description",
          arguments: {
            arg6: {
              type: "string",
              description: "arg6 description",
            }
          },
        },
      ],
    }
  end
end

class MyTestAgent4 < RedmineAiHelper::BaseAgent
  def self.list_tools
    {
      tools: [
        {
          name: "tool7",
          description: "tool7 description",
          arguments: {
            arg7: {
              type: "string",
              description: "arg7 description",
            }
          },
        },
        {
          name: "tool8",
          description: "tool8 description",
          arguments: {
            arg8: {
              type: "string",
              description: "arg8 description",
            }
          },
        },
      ],
    }
  end
end

class MyTestAgent5 < RedmineAiHelper::BaseAgent
  def self.list_tools
    {
      tools: [
        {
          name: "tool9",
          description: "tool9 description",
          arguments: {
            arg9: {
              type: "string",
              description: "arg9 description",
            }
          },
        },
        {
          name: "tool10",
          description: "tool10 description",
          arguments: {
            arg10: {
              type: "string",
              description: "arg10 description",
            }
          },
        },
      ],
    }
  end
end

class MyTestAgent6 < RedmineAiHelper::BaseAgent
  def self.list_tools
    {
      tools: [
        {
          name: "tool11",
          description: "tool11 description",
          arguments: {
            arg11: {
              type: "string",
              description: "arg11 description",
            }
          },
        },
        {
          name: "tool12",
          description: "tool12 description",
          arguments: {
            arg12: {
              type: "string",
              description: "arg12 description",
            }
          },
        },
      ],
    }
  end
end

