module Engineering
  class DashboardController < ApplicationController
    def index
      # INTENTIONAL: Each phase triggers queries for epics → stories → tasks.
      # At 7 phases with 3 epics each and 3 stories each, this is ~70+ queries.
      # No eager loading. Completion percentages call tasks.count multiple times.
      @phases = Phase.all.order(:position)
    end
  end
end
