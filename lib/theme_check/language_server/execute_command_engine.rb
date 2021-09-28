# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class ExecuteCommandEngine
      def initialize
        @providers = {}
        ExecuteCommandProvider.all
          .map(&:new)
          .each { |p| @providers[p.command] = p }
      end

      def execute(command, arguments)
        @providers[command].execute(arguments)
      end
    end
  end
end
