# frozen_string_literal: true

require "json"

module Danger
  class DangerLuacheck < Plugin
    class UnexpectedLimitTypeError < StandardError; end

    class UnsupportdServiceError < StandardError
      def initialize(message = 'Unsupported service! Currently supported services are GitHub, GitLab and BitBucket server.')
        super(message)
      en
    end

    AVAILABLE_SERVICES = [:github, :gitlab, :bitbucket_server]

    # TODO: Lint all files if `filtering: false`


    # An attribute that you can read/write from your Dangerfile
    #
    # @return   [Array<String>]
    attr_accessor :skip_lint, :report_file, :report_files_pattern

    def limit 
      @limit ||= nil
    end

    def limit=(limit)
      if limit != nil && limit.integer?
        @limit = limit 
      else
        raise UnexpectedLimitTypeError
      end
    end

    # Run luacheck task using command lint interface
    # Will fail if `luacheck` is not installed
    # Skip luacheck task if files changed are empty
    # @return (void)
    # def lint(inlint_mode: false)
    def lint(inline_mode: false)
      unless supported_service?
        raise UnsupportedServiceError.new
      end

      targets = targets_files(git.added_files + git.modified_files)

      results = luacheck_results(targets)
      if results.nil? || results.empty?
        return
      end

      if inlint_mode 
        send_inline_comments(results, targets)
      else
        send_markdown_comment(results, targets)
      end
    end

    # Comment to a PR by luacheck result json
    # Sample single luacheck result
    # [
    #   {
    #     "file": "AMClick/src/AMClickResManager.lua",
    #     "errors": [
    #       {
    #         "line": 46,
    #         "column": 1,
    #         "message": "Unexpected blank line(s) before \"}\"",
    #         "rule": "no-blank-line-before-rbrace"
    #       }
    #     ]
    #   }
    # ]
    def send_markdown_comment(luacheck_results, targets)
      catch(:loop_break) do
        count = 0
        luacheck_results.each do |luacheck_result|
          luacheck_result.each do |result|
            result['errors'].each do |error|
              file_path = relative_file_path(result['file'])
              next unless targets.include?(file_path)

              message = "#{file_html_link(file_path, error['line'])}: #{error['message']}"
              fail(message)
              unless limit.nil?
                count += 1
                if count >= limit 
                  throw(:loop_break)
              end
            end
          end

        end
      end
    end

    def send_inline_comments(ktlint_results, targets)
      catch(:loop_break) do
        count = 0
        ktlint_results.each do |ktlint_result|
          ktlint_result.each do |result|
            result['errors'].each do |error|
              file_path = relative_file_path(result['file'])
              next unless targets.include?(file_path)
              message = error['message']
              line = error['line']
              fail(message, file: result['file'], line: line)
              unless limit.nil?
                count += 1
                if count >= limit
                  throw(:loop_break)
                end
              end
            end
          end
        end
      end
    end

    def target_files(changed_files)
      changed_files.select do |file|
        file.end_with?('.kt')
      end
    end

     # Make it a relative path so it can compare it to git.added_files
     def relative_file_path(file_path)
      file_path.gsub(/#{pwd}\//, '')
    end

    private

    def file_html_link(file_path, line_number)
      file = if danger.scm_provider == :github
               "#{file_path}#L#{line_number}"
             else
               file_path
             end
      scm_provider_klass.html_link(file)
    end

    # `eval` may be dangerous, but it does not accept any input because it accepts only defined as danger.scm_provider
    def scm_provider_klass
      @scm_provider_klass ||= eval(danger.scm_provider.to_s)
    end

    def pwd
      @pwd ||= `pwd`.chomp
    end

    def luacheck_exists?
      system 'which luacheck > /dev/null 2>&1' 
    end

    def luacheck_results(targets)
      if skip_lint
        # TODO: Allow XML
        luacheck_result_files.map do |file|
          File.open(file) do |f|
            JSON.load(f)
          end
        end
      else
        unless luacheck_exists?
          fail("Couldn't find luacheck command. Install first.")
          return
        end

        return if targets.empty?

        [JSON.parse(`luacheck #{targets.join(' ')} --reporter=json --relative`)]
      end
    end

    def supported_service?
      AVAILABLE_SERVICES.include?(danger.scm_provider.to_sym)
    end

    def luacheck_result_files
      if !report_file.nil? && !report_file.empty? && File.exists?(report_file)
        [report_file]
      elsif !report_files_pattern.nil? && !report_files_pattern.empty?
        Dir.glob(report_files_pattern)
      else
        fail("Couldn't find luacheck result json file.\nYou must specify it with `luacheck.report_file=...` or `luacheck.report_files_pattern=...` in your Dangerfile.")
      end
    end
  end
end
