require 'forwardable'

module CalendariumRomanum

  # Information on one particular day of the liturgical year
  class Day
    # Note: despite of all constructor arguments being nullable,
    # instances returned by {Calendar} always have all of them set,
    # the only exception being +vespers+.
    #
    # @param date [Date, nil]
    # @param season [Season, nil]
    # @param season_week [Integer, nil]
    # @param celebrations [Array<Celebration>, nil]
    # @param vespers [Celebration, nil]
    def initialize(date: nil, season: nil, season_week: nil, celebrations: nil, vespers: nil)
      @date = date
      @season = season
      @season_week = season_week
      @celebrations = celebrations ? celebrations.dup : []
      @vespers = vespers
      cycles = Calendar.lectionary_cycles_for_date date
      @cycle_sunday = cycles[:cycle_sunday]
      @cycle_ferial = cycles[:cycle_ferial]

      if date.cwday == 7
        @cycle = @cycle_sunday
      else
        @cycle = @cycle_ferial
      end
    end

    # @return [Date]
    attr_reader :date

    # Weekday as integer (Sunday is 0)
    #
    # @return [Integer]
    def weekday
      date.wday
    end

    # Weekday as internationalized string
    #
    # @return [String]
    # @since 0.7.0
    def weekday_name
      I18n.t(date.wday, scope: 'weekday')
    end

    # @return [Season]
    attr_reader :season

    # Week of the season
    #
    # @return [Integer]
    attr_reader :season_week

    # List of celebrations for the given day.
    #
    # In tests and other "less-standard" situations the array
    # may be empty, but it's never empty for instances
    # returned by {Calendar}.
    #
    # @return [Array<Celebration>]
    attr_reader :celebrations

    # {Celebration} whose first Vespers are celebrated
    # in place of Vespers of the day's {Celebration}(s).
    # Please note that {Calendar} by default _doesn't_ populate
    # Vespers, - it's an opt-in feature
    # (see {Calendar#initialize}, {Calendar#populates_vespers?},
    # {Calendar#day}).
    #
    # @return [Celebration, nil]
    # @since 0.5.0
    attr_reader :vespers

    attr_reader :cycle_sunday
    attr_reader :cycle_ferial
    attr_reader :cycle

    def ==(other)
      self.class == other.class &&
        date == other.date &&
        season == other.season &&
        season_week == other.season_week &&
        celebrations == other.celebrations &&
        vespers == other.vespers
    end

    # Are the day's Vespers suppressed in favour of first Vespers
    # of a Sunday or solemnity?
    #
    # @return [Boolean]
    def vespers_from_following?
      !vespers.nil?
    end

    # String representation of the instance listing it's contents.
    # Intended mostly for debugging purposes.
    #
    # @return [String]
    # @since 0.7.0
    def to_s
      celebrations_string = '['
      celebrations.each do |c|
        celebrations_string << c.to_s + ', '
      end
      celebrations_string = celebrations_string.chomp(', ') << ']'
      "#<#{self.class.name} @date=#{date} @season=#{season} @season_week=#{season_week} celebrations=#{celebrations_string} vespers=#{vespers.inspect}>"
    end
  end

  # One particular celebration of the liturgical year
  # (like a Sunday, feast or memorial);
  # some days have one,
  # some have more among which one is to be chosen
  class Celebration
    extend Forwardable

    # @param title [String|Proc]
    #   Celebration title/name.
    #   If a +Proc+ is passed, it is expected not to receive
    #   arguments and to return a +String+.
    #   (Used for celebration titles which have to be
    #   internationalizable - the +Proc+ is called whenever
    #   {#title} is invoked, which allows the value to vary
    #   depending e.g. on state of the +Proc+ or some
    #   global setting - like +I18n.locale+ - it may access.)
    # @param rank [Rank] Celebration rank
    # @param colour [Colour] Liturgical colour
    # @param symbol [Symbol, nil]
    #   Unique machine-readable identifier of the celebration
    # @param date [AbstractDate, nil]
    #   Normal fixed date of the celebration
    # @param cycle [:sanctorale, :temporale]
    #   Cycle the celebration belongs to
    def initialize(title = '', rank = Ranks::FERIAL, colour = Colours::GREEN, symbol = nil, date = nil, cycle = :sanctorale, has_vigil = false, has_evening = false, move_if_sunday = false)
      @title = title
      @rank = rank
      @colour = colour
      @symbol = symbol
      @date = date
      @cycle = cycle
      @has_vigil = has_vigil
      @has_evening = has_evening
      @move_if_sunday = move_if_sunday
    end

    # @return [Rank]
    attr_reader :rank

    # @!method solemnity?
    #   @return [Boolean]
    # @!method feast?
    #   @return [Boolean]
    # @!method memorial?
    #   @return [Boolean]
    # @!method sunday?
    #   @return [Boolean]
    #   @since 0.6.0
    # @!method ferial?
    #   @return [Boolean]
    #   @since 0.6.0
    def_delegators :@rank, :solemnity?, :feast?, :memorial?, :sunday?, :ferial?

    # Feast title/name
    #
    # @return [String]
    def title
      if @title.respond_to? :call
        @title.call
      else
        @title
      end
    end

    # Liturgical colour
    #
    # @return [Colour]
    attr_reader :colour
    alias color colour

    # Symbol uniquely identifying the celebration
    #
    # @return [Symbol, nil]
    # @since 0.5.0
    attr_reader :symbol

    # Usual date of the celebration.
    #
    # Only set for celebrations with fixed date.
    # (Only) In case of solemnities it may happen that
    # {Celebration#date} differs from {Day#date} due to
    # transfer of an impeded solemnity.
    #
    # @return [AbstractDate, nil]
    # @since 0.6.0
    attr_reader :date

    # Describes the celebration as belonging either to the
    # temporale or sanctorale cycle
    #
    # @return [:sanctorale, :temporale]
    # @since 0.6.0
    attr_reader :cycle

    # Determines if the given celebration
    # should generate a corresponding vigil
    #
    # @return [Boolean]
    # @since 1.0.0
    attr_reader :has_vigil

    # Determines if the given celebration
    # should generate a corresponding evening celebration
    #
    # @return [Boolean]
    # @since 1.0.0
    attr_reader :has_evening

    # Determines if the given celebration
    # should move to monday if the natural date falls on a sunday
    #
    # @return [Boolean]
    # @since 1.0.0
    attr_reader :move_if_sunday

    def ==(b)
      self.class == b.class &&
        title == b.title &&
        rank == b.rank &&
        colour == b.colour &&
        symbol == b.symbol &&
        date == b.date &&
        cycle == b.cycle &&
        has_vigil == b.has_vigil &&
        has_evening == b.has_evening &&
        move_if_sunday = b.move_if_sunday
    end

    # Does the celebration belong to the temporale cycle?
    #
    # @return [Boolean]
    # @since 0.6.0
    def temporale?
      cycle == :temporale
    end

    # Does the celebration belong to the sanctorale cycle?
    #
    # @return [Boolean]
    # @since 0.6.0
    def sanctorale?
      cycle == :sanctorale
    end

    # Add conventional method
    #
    # @return [Boolean]
    # @since 1.0.0
    def has_vigil?
      has_vigil
    end

    # Add conventional method
    #
    # @return [Boolean]
    # @since 1.0.0
    def has_evening?
      has_evening
    end
    
    # Add conventional method
    #
    # @return [Boolean]
    # @since 1.0.0
    def move_if_sunday?
      move_if_sunday
    end

    # Build a new instance using the receiver's attributes
    # for all properties for which (a non-nil) value was not passed.
    #
    # @return [Celebration]
    # @since 0.5.0
    def change(title: nil, rank: nil, colour: nil, color: nil, symbol: nil, date: nil, cycle: nil, has_vigil: nil, has_evening: nil, move_if_sunday: nil)
      self.class.new(
        title || self.title,
        rank || self.rank,
        colour || color || self.colour,
        symbol || self.symbol,
        date || self.date,
        cycle || self.cycle,
        has_vigil || self.has_vigil,
        has_evening || self.has_evening,
        move_if_sunday || self.move_if_sunday,
      )
    end

    # String representation of the object's contents
    # (not very pretty, intended mostly for development inspections).
    #
    # @return [String]
    # @since 0.7.0
    def to_s
      "#<#{self.class.name} @title=\"#{title}\" @rank=#{rank} @colour=#{colour} symbol=#{symbol.inspect} date=#{date.inspect} cycle=#{cycle.inspect} has_vigil=#{has_vigil} has_evening=#{has_evening} move_if_sunday=#{move_if_sunday}>"
    end
  end
end
