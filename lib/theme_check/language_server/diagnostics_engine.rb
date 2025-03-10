# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DiagnosticsEngine
      include URIHelper

      def initialize(bridge)
        @diagnostics_lock = Mutex.new
        @diagnostics_tracker = DiagnosticsTracker.new
        @bridge = bridge
        @token = 0
      end

      def first_run?
        @diagnostics_tracker.first_run?
      end

      def analyze_and_send_offenses(absolute_path, config)
        return unless @diagnostics_lock.try_lock
        @token += 1
        @bridge.send_create_work_done_progress_request(@token)
        storage = ThemeCheck::FileSystemStorage.new(
          config.root,
          ignored_patterns: config.ignored_patterns
        )
        theme = ThemeCheck::Theme.new(storage)
        analyzer = ThemeCheck::Analyzer.new(theme, config.enabled_checks)

        if @diagnostics_tracker.first_run?
          @bridge.send_work_done_progress_begin(@token, "Full theme check")
          @bridge.log("Checking #{config.root}")
          offenses = nil
          time = Benchmark.measure do
            offenses = analyzer.analyze_theme do |path, i, total|
              @bridge.send_work_done_progress_report(@token, "#{i}/#{total} #{path}", (i.to_f / total * 100.0).to_i)
            end
          end
          end_message = "Found #{offenses.size} offenses in #{format("%0.2f", time.real)}s"
          @bridge.send_work_done_progress_end(@token, end_message)
          send_diagnostics(offenses)
        else
          # Analyze selected files
          relative_path = Pathname.new(storage.relative_path(absolute_path))
          file = theme[relative_path]
          # Skip if not a theme file
          if file
            @bridge.send_work_done_progress_begin(@token, "Partial theme check")
            offenses = nil
            time = Benchmark.measure do
              offenses = analyzer.analyze_files([file]) do |path, i, total|
                @bridge.send_work_done_progress_report(@token, "#{i}/#{total} #{path}", (i.to_f / total * 100.0).to_i)
              end
            end
            end_message = "Found #{offenses.size} new offenses in #{format("%0.2f", time.real)}s"
            @bridge.send_work_done_progress_end(@token, end_message)
            @bridge.log(end_message)
            send_diagnostics(offenses, [absolute_path])
          end
        end
        @diagnostics_lock.unlock
      end

      private

      def send_diagnostics(offenses, analyzed_files = nil)
        @diagnostics_tracker.build_diagnostics(offenses, analyzed_files: analyzed_files) do |path, diagnostic_offenses|
          send_diagnostic(path, diagnostic_offenses)
        end
      end

      def send_diagnostic(path, offenses)
        # https://microsoft.github.io/language-server-protocol/specifications/specification-current/#notificationMessage
        @bridge.send_notification('textDocument/publishDiagnostics', {
          uri: file_uri(path),
          diagnostics: offenses.map { |offense| offense_to_diagnostic(offense) },
        })
      end

      def offense_to_diagnostic(offense)
        diagnostic = {
          code: offense.code_name,
          message: offense.message,
          range: range(offense),
          severity: severity(offense),
          source: "theme-check",
        }
        diagnostic["codeDescription"] = code_description(offense) unless offense.doc.nil?
        diagnostic
      end

      def code_description(offense)
        {
          href: offense.doc,
        }
      end

      def severity(offense)
        case offense.severity
        when :error
          1
        when :suggestion
          2
        when :style
          3
        else
          4
        end
      end

      def range(offense)
        {
          start: {
            line: offense.start_line,
            character: offense.start_column,
          },
          end: {
            line: offense.end_line,
            character: offense.end_column,
          },
        }
      end
    end
  end
end
