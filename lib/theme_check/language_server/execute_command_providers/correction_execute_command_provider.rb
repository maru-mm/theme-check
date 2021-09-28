# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class CorrectionExecuteCommandProvider < ExecuteCommandProvider
      command "correction"

      def execute(diagnostics)
        changes = diagnostics
          .group_by { |d| d.dig("data", "uri") }
          .map do |diagnostics_for_uri|
            diagnostics_for_uri.map do |diagnostic|
              to_text_edit(diagnostic)
            end
          end
        result = @bridge.send_request('workspace/applyEdit', {
          label: 'Theme Check correction',
          edit: {
            changes: changes,
          },
        })
        return unless result['applied']
        # Clean up DiagnosticsTracker
      end

      def to_text_edit(diagnostic)
        # TODO
      end
    end
  end
end
