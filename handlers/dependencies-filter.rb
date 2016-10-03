  def filter_dependencies(event)
    if event[:check].has_key?(:dependencies)
      if event[:check][:dependencies].is_a?(Array)
        event[:check][:dependencies].each do |dependency|
          begin
            timeout(2) do
              check, client = dependency.split('/').reverse
              if event_exists?(client || event[:client][:name], check)
                return bail 'check dependency event exists', event
              end
            end
          rescue Timeout::Error
            @logger.warn('timed out while attempting to query the sensu api for an event')
          end
        end
      end
    end
    true
  end

