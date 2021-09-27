# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class TextEditCorrector
      def initialize(theme_file:); end

      # @param node [Node]
      def insert_after(node, content)
        {
          range: { start: end_position(node), end: end_position(node) },
          newText: content,
        }
      end

      # @param node [Node]
      def insert_before(node, content)
        {
          range: { start: start_position(node), end: start_position(node) },
          newText: content,
        }
      end

      def replace(node, content)
        {
          range: range(node),
          newText: content,
        }
      end

      def wrap(node, insert_before, insert_after)
        {
          range: range(node),
          newText: insert_before + node.markup + insert_after,
        }
      end

      private

      # @param node [ThemeCheck::Node]
      def range(node)
        {
          start: {
            line: node.start_row,
            character: node.start_column,
          },
          end: {
            line: node.end_row,
            character: node.end_column,
          },
        }
      end

      def start_position(node)
        {
          line: node.start_row,
          character: node.start_column,
        }
      end

      def end_position(node)
        {
          line: node.end_row,
          character: node.end_column,
        }
      end
    end
  end
end
